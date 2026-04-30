variable "project_name" {
  description = "Project name used as a prefix for all resource names."
  type        = string
  default     = "example-monorepo"
}

variable "region" {
  description = "AWS region for the state bucket and lock table."
  type        = string
  default     = "us-east-1"
}

variable "create_github_oidc_provider" {
  description = "Whether to create the GitHub Actions OIDC provider in this account. Set to false if the provider already exists (it is per-account, not per-project)."
  type        = bool
  default     = true
}
