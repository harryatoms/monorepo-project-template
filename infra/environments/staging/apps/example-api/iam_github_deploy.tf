# ─── GitHub Actions Deploy Role ───────────────────────────────────────────────
#
# Assumed by the deploy workflow on pushes to main. Permissions are scoped to
# exactly this app's ECR repository and Lambda function — no cross-app access.
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
  description        = "Assumed by the GitHub Actions deploy workflow on pushes to main. Scoped to this app's ECR repository and Lambda function."

  tags = local.common_tags
}

data "aws_iam_policy_document" "github_deploy_permissions" {
  # ecr:GetAuthorizationToken is account-scoped; AWS does not support narrowing
  # it to a specific repository ARN.
  statement {
    sid       = "ECRGetToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "ECRPush"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:BatchGetImage",
      "ecr:DescribeRepositories",
    ]
    resources = [aws_ecr_repository.api.arn]
  }

  statement {
    sid    = "LambdaDeploy"
    effect = "Allow"
    actions = [
      "lambda:UpdateFunctionCode",
      "lambda:PublishVersion",
      "lambda:UpdateAlias",
      "lambda:GetAlias",
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
    ]
    # Unqualified ARN covers UpdateFunctionCode and PublishVersion.
    # The :* wildcard extends coverage to all aliases and versions so
    # UpdateAlias / GetAlias resolve correctly against qualified ARNs.
    resources = [
      aws_lambda_function.api.arn,
      "${aws_lambda_function.api.arn}:*",
    ]
  }
}

resource "aws_iam_role_policy" "github_deploy_permissions" {
  name   = "${local.prefix}-github-deploy-permissions"
  role   = aws_iam_role.github_deploy.id
  policy = data.aws_iam_policy_document.github_deploy_permissions.json
}
