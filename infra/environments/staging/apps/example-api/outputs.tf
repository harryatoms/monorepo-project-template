output "ecr_repository_url" {
  description = "ECR repository URL for the API image."
  value       = aws_ecr_repository.api.repository_url
}

output "lambda_function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.api.function_name
}

output "lambda_alias_arn" {
  description = "ARN of the Lambda 'live' alias (used by the release layer)."
  value       = aws_lambda_alias.live.arn
}

output "lambda_alias_name" {
  description = "Name of the Lambda 'live' alias (used by the release layer)."
  value       = aws_lambda_alias.live.name
}

output "api_gateway_id" {
  description = "API Gateway HTTP API ID."
  value       = aws_apigatewayv2_api.api.id
}

output "api_gateway_endpoint" {
  description = "Default invoke URL for the API Gateway stage."
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "lambda_exec_role_arn" {
  description = "ARN of the Lambda execution IAM role."
  value       = aws_iam_role.lambda_exec.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for Lambda."
  value       = aws_cloudwatch_log_group.lambda.name
}

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch staging dashboard."
  value       = aws_cloudwatch_dashboard.staging.dashboard_name
}

output "cloudwatch_dashboard_url" {
  description = "Direct URL to the CloudWatch staging dashboard."
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.staging.dashboard_name}"
}

output "sns_topic_alarms_arn" {
  description = "ARN of the SNS topic that receives all alarm notifications."
  value       = aws_sns_topic.alarms.arn
}

output "composite_alarm_name" {
  description = "Name of the composite 'service unhealthy' alarm."
  value       = aws_cloudwatch_composite_alarm.service_unhealthy.alarm_name
}

output "github_deploy_role_arn" {
  description = "ARN of the GitHub Actions deploy role. Set as EXAMPLE_API_STAGING_AWS_DEPLOY_ROLE_ARN in GitHub repository variables."
  value       = aws_iam_role.github_deploy.arn
}

output "github_evals_role_arn" {
  description = "ARN of the GitHub Actions evals role. Set as EXAMPLE_EVALS_AWS_ROLE_ARN in GitHub repository variables."
  value       = aws_iam_role.github_evals.arn
}

output "ssm_openai_api_key_path" {
  description = "SSM parameter path for the OpenAI API key. Set as EXAMPLE_EVALS_SSM_OPENAI_API_KEY_PATH in GitHub repository variables."
  value       = local.ssm_openai_key_path
}
