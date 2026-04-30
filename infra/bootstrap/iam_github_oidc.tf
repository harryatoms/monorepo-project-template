# ─── GitHub Actions OIDC Provider ────────────────────────────────────────────
#
# Registers GitHub's OIDC issuer with this AWS account so that GitHub Actions
# workflows can exchange short-lived OIDC tokens for temporary AWS credentials
# via sts:AssumeRoleWithWebIdentity — no static IAM access keys required.
#
# This is a per-account registration. Set create_github_oidc_provider = false
# if the provider already exists in the account (e.g. registered by another
# project) to avoid a conflict on apply.

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_github_oidc_provider ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # SHA-1 fingerprint of the intermediate CA in GitHub's OIDC TLS chain.
  # Obtained by inspecting the certificate chain for token.actions.githubusercontent.com
  # (e.g. `openssl s_client -connect token.actions.githubusercontent.com:443 -showcerts`
  # and SHA-1-hashing the last intermediate certificate). AWS no longer enforces
  # this value for known providers, but it is required by the resource schema.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = { Project = var.project_name, ManagedBy = "terraform" }
}

locals {
  oidc_provider_arn = (
    var.create_github_oidc_provider
    ? aws_iam_openid_connect_provider.github[0].arn
    : "arn:aws:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"
  )
}
