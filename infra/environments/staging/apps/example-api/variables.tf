variable "project_name" {
  description = "Project name used as a prefix for all resource names."
  type        = string
  default     = "example-monorepo"
}

variable "environment" {
  description = "Deployment environment (e.g. staging, production)."
  type        = string
  default     = "staging"
}

variable "region" {
  description = "AWS region to deploy resources into."
  type        = string
  default     = "us-east-1"
}

variable "lambda_memory_mb" {
  description = "Memory allocated to the Lambda function in MB."
  type        = number
  default     = 512
}

variable "lambda_timeout_seconds" {
  description = "Lambda function timeout in seconds."
  type        = number
  default     = 30
}

variable "lambda_bootstrap_image_uri" {
  description = "URI of the bootstrap image for the Lambda function. This is a required input for the initial base layer deployment, but will be replaced by the release layer."
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch log events."
  type        = number
  default     = 14
}

variable "alarm_email" {
  description = "Email address to subscribe to the alarms SNS topic. Leave empty to create the topic without a subscription."
  type        = string
  default     = ""
}

variable "app_name" {
  description = "Short app identifier used in resource names (e.g. example-api)."
  type        = string
  default     = "example-api"
}

variable "github_org" {
  description = "GitHub organisation that owns the repository. Used to scope the OIDC deploy role trust policy."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (without org prefix). Used to scope the OIDC deploy role trust policy."
  type        = string
  default     = "example-monorepo"
}
