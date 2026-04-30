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

variable "app_name" {
  description = "Short app identifier used in resource names."
  type        = string
  default     = "example-web"
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
