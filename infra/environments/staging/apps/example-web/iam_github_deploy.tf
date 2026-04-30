# ─── GitHub Actions Deploy Role ───────────────────────────────────────────────
#
# Assumed by the deploy workflow on pushes to main. Permissions are scoped to
# this app's S3 bucket and CloudFront distribution only — no cross-app access.
#
# The OIDC provider is registered at the account level (infra/bootstrap).
# Its ARN is looked up here via data source so this module has no dependency
# on bootstrap's local state file.

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

locals {
  github_subject = "repo:${var.github_org}/${var.github_repo}"
}

data "aws_iam_policy_document" "github_deploy_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Restricts assumption to pushes to main only — PRs cannot acquire
    # deploy credentials.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["${local.github_subject}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_deploy" {
  name               = "${local.prefix}-github-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_deploy_trust.json
  description        = "Assumed by the GitHub Actions deploy workflow on pushes to main. Scoped to this app's S3 bucket and CloudFront distribution."

  tags = local.common_tags
}

data "aws_iam_policy_document" "github_deploy_permissions" {
  statement {
    sid    = "S3SyncObjects"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.site.arn,
      "${aws_s3_bucket.site.arn}/*",
    ]
  }

  statement {
    sid    = "CloudFrontInvalidate"
    effect = "Allow"
    actions = [
      "cloudfront:CreateInvalidation",
      "cloudfront:GetInvalidation",
    ]
    resources = [aws_cloudfront_distribution.site.arn]
  }

  # Allows the deploy workflow to read the API Gateway endpoint published by
  # the example-api infra, so PUBLIC_API_URL can be injected at
  # build time without a manually managed GitHub variable.
  statement {
    sid     = "ReadSharedSSMParameters"
    effect  = "Allow"
    actions = ["ssm:GetParameter"]
    resources = [
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/example-monorepo/${var.environment}/api-gateway-endpoint",
    ]
  }
}

resource "aws_iam_role_policy" "github_deploy_permissions" {
  name   = "${local.prefix}-github-deploy-permissions"
  role   = aws_iam_role.github_deploy.id
  policy = data.aws_iam_policy_document.github_deploy_permissions.json
}
