# ─── CloudWatch Alarms ────────────────────────────────────────────────────────
#
# Five signal categories, ordered by urgency:
#
#   1. configuration_failed  — any occurrence → page immediately
#   2. api_5xx_errors        — ≥1 error in 2/5 consecutive minutes
#   3. lambda_errors         — ≥1 error in 2/5 consecutive minutes
#   4. p95_latency           — sustained above 15 s for 10 minutes
#   5. provider_unavailable  — repeated failures across a 15-minute window
#
# A composite alarm ("service unhealthy") rolls up 1–3 into a single
# pager-worthy signal. Latency and provider alarms are standalone.
#
# Thresholds are pragmatic staging defaults. Tune them after observing
# real traffic patterns.

# ─── SNS topic ────────────────────────────────────────────────────────────────

resource "aws_sns_topic" "alarms" {
  name = "${local.prefix}-alarms"

  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "alarms_email" {
  count = var.alarm_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# ─── Metric filters (log events → custom CloudWatch metrics) ──────────────────
#
# These lift structured-log events out of the Lambda log group and make them
# queryable as standard CloudWatch metrics, which standard alarms can then
# evaluate. A default_value of "0" ensures periods with no matching events
# still emit a data point, which keeps treat_missing_data = "notBreaching"
# reliable.

resource "aws_cloudwatch_log_metric_filter" "configuration_failed" {
  name           = "${local.prefix}-configuration-failed"
  log_group_name = aws_cloudwatch_log_group.lambda.name
  pattern        = "{ $.event = \"service.sample_resource.configuration_failed\" }"

  metric_transformation {
    name          = "ConfigurationFailed"
    namespace     = "${local.prefix}/App"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_log_metric_filter" "provider_unavailable" {
  name           = "${local.prefix}-provider-unavailable"
  log_group_name = aws_cloudwatch_log_group.lambda.name
  pattern        = "{ $.event = \"service.sample_resource.provider_error\" }"

  metric_transformation {
    name          = "ProviderUnavailable"
    namespace     = "${local.prefix}/App"
    value         = "1"
    default_value = "0"
  }
}

# invalid_response — dashboard-only (no alarm wired yet)
#
# parse_error is one of the most LLM-specific failure signals in the system: it
# fires when the model returns a response that cannot be coerced into the
# expected schema even after the repair loop is exhausted. This is intentionally
# not alarmed today because:
#   - volume is expected to be very low in normal operation
#   - individual occurrences are not service-breaking (callers get a 500, but
#     the failure is isolated to that request)
#   - diagnosing a spike requires prompt/schema investigation, not an ops page
#
# The metric is extracted here so it is trivial to graph in dashboards and to
# add an alarm threshold later once baseline behaviour is understood.
resource "aws_cloudwatch_log_metric_filter" "invalid_response" {
  name           = "${local.prefix}-invalid-response"
  log_group_name = aws_cloudwatch_log_group.lambda.name
  pattern        = "{ $.event = \"service.sample_resource.parse_error\" }"

  metric_transformation {
    name          = "InvalidResponse"
    namespace     = "${local.prefix}/App"
    value         = "1"
    default_value = "0"
  }
}

# ─── Alarm 1: configuration_failed ────────────────────────────────────────────
#
# A configuration failure means the service cannot read its OpenAI key from SSM.
# Every subsequent request will fail with configuration_failed until resolved.
# One occurrence is enough to page — this is never expected in normal operation.

resource "aws_cloudwatch_metric_alarm" "configuration_failed" {
  alarm_name        = "${local.prefix}-configuration-failed"
  alarm_description = "service.sample_resource.configuration_failed logged — OpenAI key or SSM access is broken. Every request is failing."

  namespace   = "${local.prefix}/App"
  metric_name = "ConfigurationFailed"
  statistic   = "Sum"

  period              = 60
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = local.common_tags
}

# ─── Alarm 2: API Gateway 5XX errors ──────────────────────────────────────────
#
# Fires when at least one 5XX occurs in 2 out of 5 consecutive 1-minute windows.
# The 2/5 rule avoids noise from isolated transient errors while catching any
# sustained failure pattern quickly.

resource "aws_cloudwatch_metric_alarm" "api_5xx_errors" {
  alarm_name        = "${local.prefix}-5xx-errors"
  alarm_description = "API Gateway is returning 5XX responses — indicates service or Lambda integration failure."

  namespace   = "AWS/ApiGateway"
  metric_name = "5XXError"
  dimensions = {
    ApiId = aws_apigatewayv2_api.api.id
    Stage = "$default"
  }
  statistic = "Sum"

  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = local.common_tags
}

# ─── Alarm 3: Lambda errors ────────────────────────────────────────────────────
#
# Catches errors thrown inside the Lambda runtime itself (crashes, timeouts,
# OOM), which API GW surfaces as 5XX but which have a distinct root cause path.
# Same 2/5 cadence as the 5XX alarm.

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name        = "${local.prefix}-lambda-errors"
  alarm_description = "Lambda function is throwing errors — check recent ERROR log events for stack traces or timeout messages."

  namespace   = "AWS/Lambda"
  metric_name = "Errors"
  dimensions = {
    FunctionName = aws_lambda_function.api.function_name
    Resource     = local.lambda_alias_resource
  }
  statistic = "Sum"

  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = local.common_tags
}

# ─── Alarm 4: p95 latency ─────────────────────────────────────────────────────
#
# Fires when API GW p95 latency exceeds 15 s for two consecutive 5-minute
# windows (10 minutes sustained). 15 s is a conservative ceiling given:
#   - Lambda timeout = 30 s
#   - Typical OpenAI call duration = 3–10 s
#   - Cold start overhead = up to ~3 s
#
# A 5-minute period is used (instead of 1 minute) to avoid false alarms from
# isolated slow OpenAI responses, which are common and transient.

resource "aws_cloudwatch_metric_alarm" "p95_latency" {
  alarm_name        = "${local.prefix}-p95-latency"
  alarm_description = "API Gateway p95 latency has been above 15 s for 10 minutes — likely sustained OpenAI slowdown or Lambda cold-start spike."

  namespace   = "AWS/ApiGateway"
  metric_name = "Latency"
  dimensions = {
    ApiId = aws_apigatewayv2_api.api.id
    Stage = "$default"
  }
  extended_statistic = "p95"

  period              = 300
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  threshold           = 15000
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = local.common_tags
}

# ─── Alarm 5: provider_unavailable (repeated) ─────────────────────────────────
#
# A single OpenAI error can be a transient blip (rate limit, network hiccup).
# This alarm fires when ≥2 provider errors occur in a 5-minute window, and
# that pattern repeats across 2 of 3 consecutive windows (up to 15 minutes).
# That filters single blips while catching genuine degradation early.

resource "aws_cloudwatch_metric_alarm" "provider_unavailable" {
  alarm_name        = "${local.prefix}-provider-unavailable"
  alarm_description = "OpenAI provider is repeatedly unavailable — check OpenAI status page and API key quota."

  namespace   = "${local.prefix}/App"
  metric_name = "ProviderUnavailable"
  statistic   = "Sum"

  period              = 300
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  threshold           = 1
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = local.common_tags
}

# ─── Composite alarm: service unhealthy ───────────────────────────────────────
#
# Rolls up the three highest-signal alarms (configuration_failed, 5XX, Lambda
# errors) into a single alarm suitable for wiring to PagerDuty or on-call.
#
# Latency and provider_unavailable are intentionally excluded: latency
# degradation is important but not immediately service-breaking, and provider
# errors may resolve on their own. Each of those alarms still fires
# independently to ensure visibility.

resource "aws_cloudwatch_composite_alarm" "service_unhealthy" {
  alarm_name        = "${local.prefix}-service-unhealthy"
  alarm_description = "One or more critical alarms are active. Open the dashboard and check individual alarm states."

  alarm_rule = join(" OR ", [
    "ALARM(\"${aws_cloudwatch_metric_alarm.configuration_failed.alarm_name}\")",
    "ALARM(\"${aws_cloudwatch_metric_alarm.api_5xx_errors.alarm_name}\")",
    "ALARM(\"${aws_cloudwatch_metric_alarm.lambda_errors.alarm_name}\")",
  ])

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = local.common_tags
}
