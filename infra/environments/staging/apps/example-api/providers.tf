terraform {
  required_version = "~> 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration is supplied at init time via backend.hcl, which is
  # gitignored and generated per-machine by scripts/generate-backend-configs.sh.
  # Run: make infra-generate-backend-configs && make infra-init APP=example-api ENV=staging
  backend "s3" {}
}

provider "aws" {
  region = var.region
}
