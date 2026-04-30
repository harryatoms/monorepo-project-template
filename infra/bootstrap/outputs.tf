output "tfstate_bucket_name" {
  description = "Name of the S3 bucket used for Terraform state storage."
  value       = aws_s3_bucket.tfstate.bucket
}

output "tflock_table_name" {
  description = "Name of the DynamoDB table used for Terraform state locking."
  value       = aws_dynamodb_table.tflock.name
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider registered in this account."
  value       = local.oidc_provider_arn
}
