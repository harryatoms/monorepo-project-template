output "s3_bucket_name" {
  description = "Name of the S3 bucket hosting the static site."
  value       = aws_s3_bucket.site.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = aws_s3_bucket.site.arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID. Set as EXAMPLE_WEB_STAGING_CLOUDFRONT_DISTRIBUTION_ID in GitHub repository variables."
  value       = aws_cloudfront_distribution.site.id
}

output "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN."
  value       = aws_cloudfront_distribution.site.arn
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name (the public URL of the staging frontend)."
  value       = "https://${aws_cloudfront_distribution.site.domain_name}"
}

output "github_deploy_role_arn" {
  description = "ARN of the GitHub Actions deploy role. Set as EXAMPLE_WEB_STAGING_AWS_DEPLOY_ROLE_ARN in GitHub repository variables."
  value       = aws_iam_role.github_deploy.arn
}
