# ─── GitHub Actions Evals Role ────────────────────────────────────────────────
#
# Assumed by the evals workflow on pull requests and workflow_dispatch.
# Intentionally separate from the deploy role: the trust policy allows any
# ref from this repo (not just main), and permissions are scoped to a single
# SSM GetParameter call — no deploy capabilities.
#
# The OIDC provider is registered at the account level (infra/bootstrap).
# Its ARN is looked up via data source (already declared in iam_github_deploy.tf).

data "aws_iam_policy_document" "github_evals_trust" {
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

    # Allows assumption from any ref in this repo — pull requests, main,
    # and workflow_dispatch — unlike the deploy role which restricts to main only.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["${local.github_subject}:*"]
    }
  }
}

resource "aws_iam_role" "github_evals" {
  name               = "${local.prefix}-github-evals"
  assume_role_policy = data.aws_iam_policy_document.github_evals_trust.json
  description        = "Assumed by the GitHub Actions evals workflow on pull requests and workflow_dispatch. Read-only access to the OpenAI API key in SSM."

  tags = local.common_tags
}

data "aws_iam_policy_document" "github_evals_permissions" {
  statement {
    sid       = "SSMReadOpenAIKey"
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = [local.ssm_openai_key_arn]
  }
}

resource "aws_iam_role_policy" "github_evals_permissions" {
  name   = "${local.prefix}-github-evals-permissions"
  role   = aws_iam_role.github_evals.id
  policy = data.aws_iam_policy_document.github_evals_permissions.json
}
