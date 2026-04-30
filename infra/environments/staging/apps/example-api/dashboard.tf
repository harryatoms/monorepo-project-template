# ─── CloudWatch Dashboard ────────────────────────────────────────────────────
#
# Single-pane operational view for the staging environment.
# Four sections answer three questions fast:
#   1. Is the API healthy?   → Traffic / Availability
#   2. Is it slow?           → Latency
#   3. Is the LLM failing?   → Dependency Health

locals {
  # Lambda metrics are emitted per alias when the Resource dimension is set to
  # "function-name:alias-name".  This gives alias-scoped granularity separate
  # from the unqualified function totals.
  lambda_alias_resource = "${aws_lambda_function.api.function_name}:${aws_lambda_alias.live.name}"
}

resource "aws_cloudwatch_dashboard" "staging" {
  dashboard_name = "${local.prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [

      # ── Section 1: Traffic / Availability ──────────────────────────────────

      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "## 1 · Traffic / Availability"
        }
      },

      # API Gateway: request count, 4XX, 5XX (top row — 3 × 8 columns)
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 8
        height = 6
        properties = {
          title   = "API GW – Request Count"
          view    = "timeSeries"
          stacked = false
          region  = var.region
          stat    = "Sum"
          period  = 60
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiId", aws_apigatewayv2_api.api.id, "Stage", "$default"],
          ]
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 1
        width  = 8
        height = 6
        properties = {
          title   = "API GW – 4XX Errors"
          view    = "timeSeries"
          stacked = false
          region  = var.region
          stat    = "Sum"
          period  = 60
          metrics = [
            ["AWS/ApiGateway", "4XXError", "ApiId", aws_apigatewayv2_api.api.id, "Stage", "$default"],
          ]
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 1
        width  = 8
        height = 6
        properties = {
          title   = "API GW – 5XX Errors"
          view    = "timeSeries"
          stacked = false
          region  = var.region
          stat    = "Sum"
          period  = 60
          metrics = [
            ["AWS/ApiGateway", "5XXError", "ApiId", aws_apigatewayv2_api.api.id, "Stage", "$default"],
          ]
        }
      },

      # Lambda: invocations, errors, throttles (second row — 3 × 8 columns)
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 8
        height = 6
        properties = {
          title   = "Lambda – Invocations"
          view    = "timeSeries"
          stacked = false
          region  = var.region
          stat    = "Sum"
          period  = 60
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.api.function_name, "Resource", local.lambda_alias_resource],
          ]
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 7
        width  = 8
        height = 6
        properties = {
          title   = "Lambda – Errors"
          view    = "timeSeries"
          stacked = false
          region  = var.region
          stat    = "Sum"
          period  = 60
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.api.function_name, "Resource", local.lambda_alias_resource],
          ]
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 7
        width  = 8
        height = 6
        properties = {
          title   = "Lambda – Throttles"
          view    = "timeSeries"
          stacked = false
          region  = var.region
          stat    = "Sum"
          period  = 60
          metrics = [
            ["AWS/Lambda", "Throttles", "FunctionName", aws_lambda_function.api.function_name, "Resource", local.lambda_alias_resource],
          ]
        }
      },

      # ── Section 2: Latency ──────────────────────────────────────────────────

      {
        type   = "text"
        x      = 0
        y      = 13
        width  = 24
        height = 1
        properties = {
          markdown = "## 2 · Latency"
        }
      },

      # API GW end-to-end latency — p50 / p95 / p99
      {
        type   = "metric"
        x      = 0
        y      = 14
        width  = 6
        height = 6
        properties = {
          title   = "API GW – Latency (ms)"
          view    = "timeSeries"
          stacked = false
          region  = var.region
          period  = 60
          metrics = [
            ["AWS/ApiGateway", "Latency", "ApiId", aws_apigatewayv2_api.api.id, "Stage", "$default", { stat = "p50", label = "p50" }],
            ["...", { stat = "p95", label = "p95" }],
            ["...", { stat = "p99", label = "p99" }],
          ]
        }
      },

      # API GW integration (Lambda) latency — p50 / p95 / p99
      {
        type   = "metric"
        x      = 6
        y      = 14
        width  = 6
        height = 6
        properties = {
          title   = "API GW – Integration Latency (ms)"
          view    = "timeSeries"
          stacked = false
          region  = var.region
          period  = 60
          metrics = [
            ["AWS/ApiGateway", "IntegrationLatency", "ApiId", aws_apigatewayv2_api.api.id, "Stage", "$default", { stat = "p50", label = "p50" }],
            ["...", { stat = "p95", label = "p95" }],
            ["...", { stat = "p99", label = "p99" }],
          ]
        }
      },

      # Lambda duration — p50 / p95 / p99
      {
        type   = "metric"
        x      = 12
        y      = 14
        width  = 6
        height = 6
        properties = {
          title   = "Lambda – Duration (ms)"
          view    = "timeSeries"
          stacked = false
          region  = var.region
          period  = 60
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.api.function_name, "Resource", local.lambda_alias_resource, { stat = "p50", label = "p50" }],
            ["...", { stat = "p95", label = "p95" }],
            ["...", { stat = "p99", label = "p99" }],
          ]
        }
      },

      # App-level request latency from structured logs (http.request.completed → attributes.latency_ms)
      {
        type   = "log"
        x      = 18
        y      = 14
        width  = 6
        height = 6
        properties = {
          title            = "App – Request Latency (ms)"
          region           = var.region
          view             = "timeSeries"
          stacked          = false
          queryBy          = "logGroupName"
          logGroupPrefixes = { accountIds = [], logGroupPrefix = [], logClass = "STANDARD" }
          query            = "SOURCE \"${aws_cloudwatch_log_group.lambda.name}\" |\nfilter event = \"http.request.completed\" |\n stats avg(attributes.latency_ms) as avg_ms,\n pct(attributes.latency_ms, 95) as p95_ms by bin(1min)"
        }
      },

      # ── Section 3: Dependency Health – LLM ─────────────────────────────────

      {
        type   = "text"
        x      = 0
        y      = 20
        width  = 24
        height = 1
        properties = {
          markdown = "## 3 · Dependency Health – LLM"
        }
      },

      # provider_unavailable — logged as service.sample_resource.provider_error
      {
        type   = "log"
        x      = 0
        y      = 21
        width  = 6
        height = 6
        properties = {
          title            = "provider_unavailable"
          region           = var.region
          view             = "timeSeries"
          stacked          = false
          queryBy          = "logGroupName"
          logGroupPrefixes = { accountIds = [], logGroupPrefix = [], logClass = "STANDARD" }
          query            = "SOURCE \"${aws_cloudwatch_log_group.lambda.name}\" |\nfilter event = \"service.sample_resource.provider_error\" |\nstats count(*) as provider_unavailable by bin(5min)"
        }
      },

      # invalid_response — logged as service.sample_resource.parse_error
      {
        type   = "log"
        x      = 6
        y      = 21
        width  = 6
        height = 6
        properties = {
          title            = "invalid_response"
          region           = var.region
          view             = "timeSeries"
          stacked          = false
          queryBy          = "logGroupName"
          logGroupPrefixes = { accountIds = [], logGroupPrefix = [], logClass = "STANDARD" }
          query            = "SOURCE \"${aws_cloudwatch_log_group.lambda.name}\" |\nfilter event = \"service.sample_resource.parse_error\" |\nstats count(*) as invalid_response by bin(5min)"
        }
      },

      # configuration_failed — logged as service.sample_resource.configuration_failed
      {
        type   = "log"
        x      = 12
        y      = 21
        width  = 6
        height = 6
        properties = {
          title            = "configuration_failed"
          region           = var.region
          view             = "timeSeries"
          stacked          = false
          queryBy          = "logGroupName"
          logGroupPrefixes = { accountIds = [], logGroupPrefix = [], logClass = "STANDARD" }
          query            = "SOURCE \"${aws_cloudwatch_log_group.lambda.name}\" |\nfilter event = \"service.sample_resource.configuration_failed\" |\nstats count(*) as configuration_failed by bin(5min)"
        }
      },

      # LLM request latency — client.openai.request.completed → attributes.latency_ms
      {
        type   = "log"
        x      = 18
        y      = 21
        width  = 6
        height = 6
        properties = {
          title            = "LLM – Request Latency (ms)"
          region           = var.region
          view             = "timeSeries"
          stacked          = false
          queryBy          = "logGroupName"
          logGroupPrefixes = { accountIds = [], logGroupPrefix = [], logClass = "STANDARD" }
          query            = "SOURCE \"${aws_cloudwatch_log_group.lambda.name}\" |\nfilter event = \"client.openai.request.completed\" |\n stats avg(attributes.latency_ms) as avg_ms,\n pct(attributes.latency_ms, 95) as p95_ms by bin(1min)"
        }
      },

      # ── Section 4: Deployment / Version Context ─────────────────────────────

      {
        type   = "text"
        x      = 0
        y      = 27
        width  = 24
        height = 1
        properties = {
          markdown = "## 4 · Deployment / Version Context"
        }
      },

      # Request volume by version over time — shows when each version was active
      # so that deploy transitions and any overlap between old and new versions
      # are immediately visible. The line for a version ending = last request.
      {
        type   = "log"
        x      = 0
        y      = 28
        width  = 12
        height = 6
        properties = {
          title            = "Request Count by Version"
          region           = var.region
          view             = "timeSeries"
          queryBy          = "logGroupName"
          logGroupPrefixes = { accountIds = [], logGroupPrefix = [], logClass = "STANDARD" }
          query            = "SOURCE \"${aws_cloudwatch_log_group.lambda.name}\" |\nfilter event = \"http.request.completed\" |\nstats count(*) as requests by bin(5min), version"
        }
      },

      # Recent ERROR events with request_id and version for post-incident correlation
      {
        type   = "log"
        x      = 12
        y      = 28
        width  = 12
        height = 6
        properties = {
          title            = "Recent Errors (request_id + version)"
          region           = var.region
          view             = "table"
          queryBy          = "logGroupName"
          logGroupPrefixes = { accountIds = [], logGroupPrefix = [], logClass = "STANDARD" }
          query            = "SOURCE \"${aws_cloudwatch_log_group.lambda.name}\" |\nfilter level = \"ERROR\" |\nfields @timestamp, version, attributes.request_id as request_id, event, attributes.error_type as error_type |\nsort @timestamp desc |\nlimit 50"
        }
      },

      # Optional LLM provider activity. The default boilerplate app does not emit
      # this event unless provider support is enabled by a project.
      {
        type   = "log"
        x      = 0
        y      = 34
        width  = 12
        height = 6
        properties = {
          title            = "Optional LLM Requests"
          region           = var.region
          view             = "timeSeries"
          queryBy          = "logGroupName"
          logGroupPrefixes = { accountIds = [], logGroupPrefix = [], logClass = "STANDARD" }
          query            = "SOURCE \"${aws_cloudwatch_log_group.lambda.name}\" |\nfilter event = \"client.openai.request.completed\" |\nstats count(*) as requests by bin(5min), concat(attributes.model, \" / prompts \", attributes.prompt_package_version) as provider"
        }
      },

    ]
  })
}
