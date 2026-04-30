terraform {
  required_version = "~> 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend is controlled by a generated backend.tf file (gitignored).
  # When backend.tf exists (written by make infra-generate-backend-configs),
  # Terraform uses the S3 backend. When it does not exist, Terraform uses
  # local state. See docs/operations/account-setup.md for the full flow.
}

provider "aws" {
  region = var.region
}
