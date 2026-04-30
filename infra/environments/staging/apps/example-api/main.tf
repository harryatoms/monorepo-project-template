data "aws_caller_identity" "current" {}

data "aws_kms_key" "ssm" {
  key_id = "alias/aws/ssm"
}

locals {
  prefix = "${var.project_name}-${var.environment}-${var.app_name}"

  # ECR is environment-agnostic — the same repository is used across environments
  # to support image promotion (staging → production) without rebuilding.
  ecr_name = "${var.project_name}-${var.app_name}"

  ssm_openai_key_path = "/example-monorepo/${var.environment}/OPENAI_API_KEY"
  ssm_openai_key_arn  = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter${local.ssm_openai_key_path}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    App         = var.app_name
    ManagedBy   = "terraform"
  }

  # ECR is shared across environments so Environment is omitted from its tags.
  ecr_tags = {
    Project   = var.project_name
    App       = var.app_name
    ManagedBy = "terraform"
  }
}

# ─── ECR ────────────────────────────────────────────────────────────────────

resource "aws_ecr_repository" "api" {
  name                 = local.ecr_name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.ecr_tags
}

resource "aws_ecr_lifecycle_policy" "api" {
  repository = aws_ecr_repository.api.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 20 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 20
        }
        action = { type = "expire" }
      }
    ]
  })
}

# ─── IAM ────────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "${local.prefix}-lambda-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_ssm_secrets" {
  statement {
    sid       = "AllowSSMGetOpenAIKey"
    actions   = ["ssm:GetParameter"]
    resources = [local.ssm_openai_key_arn]
  }

  statement {
    sid       = "AllowKMSDecryptSSMKey"
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_key.ssm.arn]

    # Restrict decryption to the specific parameter's encryption context.
    # SSM sets PARAMETER_ARN in the KMS encryption context when encrypting or
    # decrypting a SecureString.  Without this condition the role could decrypt
    # any SSM SecureString encrypted with the AWS-managed aws/ssm key in this
    # account and region, even parameters it cannot read via ssm:GetParameter.
    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:PARAMETER_ARN"
      values   = [local.ssm_openai_key_arn]
    }
  }
}

resource "aws_iam_role_policy" "lambda_ssm_secrets" {
  name   = "${local.prefix}-lambda-ssm-secrets"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_ssm_secrets.json
}

# ─── CloudWatch ─────────────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.prefix}"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}

# ─── Lambda ─────────────────────────────────────────────────────────────────

resource "aws_lambda_function" "api" {
  function_name = local.prefix
  role          = aws_iam_role.lambda_exec.arn
  architectures = ["x86_64"]
  package_type  = "Image"

  # Temporary bootstrap image; replaced by the release layer on first deploy.
  image_uri = var.lambda_bootstrap_image_uri

  memory_size = var.lambda_memory_mb
  timeout     = var.lambda_timeout_seconds

  environment {
    variables = {
      PORT                         = "8000"
      AWS_LWA_PORT                 = "8000"
      AWS_LWA_READINESS_CHECK_PATH = "/health"
      SSM_OPENAI_API_KEY_PATH      = local.ssm_openai_key_path
      ENVIRONMENT                  = var.environment
    }
  }

  # Publish a version so the alias can point to the initial function version.
  publish = true

  lifecycle {
    # The release layer owns image_uri; prevent base from reverting it.
    ignore_changes = [image_uri]
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy_attachment.lambda_basic_execution,
  ]

  tags = local.common_tags
}

resource "aws_lambda_alias" "live" {
  name          = "live"
  function_name = aws_lambda_function.api.function_name
  # We use the the initial function version for bootstrapping the base infra layer and alias, but the release layer must manage the version pointer after the initial bootstrap.
  function_version = aws_lambda_function.api.version

  lifecycle {
    # The release layer manages the version pointer after the initial bootstrap.
    # IMPORTANT: Without this ignore, the live function version may be overwritten by the base layer during subsequent plan/apply cycles.
    ignore_changes = [function_version]
  }
}

# ─── API Gateway ─────────────────────────────────────────────────────────────

resource "aws_apigatewayv2_api" "api" {
  name          = local.prefix
  protocol_type = "HTTP"

  tags = local.common_tags
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_alias.live.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "root" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "ANY /"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "proxy" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true

  tags = local.common_tags
}

# ─── Lambda invoke permission ────────────────────────────────────────────────

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  qualifier     = aws_lambda_alias.live.name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# ─── SSM — shared parameters ─────────────────────────────────────────────────
# The API Gateway endpoint is published to SSM so that dependent apps (e.g.
# the frontend) can read it at deploy time without manual variable management.

resource "aws_ssm_parameter" "api_gateway_endpoint" {
  name  = "/example-monorepo/${var.environment}/api-gateway-endpoint"
  type  = "String"
  value = aws_apigatewayv2_stage.default.invoke_url

  tags = local.common_tags
}
