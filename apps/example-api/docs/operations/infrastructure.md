# Infrastructure Setup

How to stand up AWS infrastructure for `example-api` in a new environment.

This covers the app layer: ECR, Lambda, API Gateway, IAM roles, CloudWatch alarms, dashboard, and the shared API endpoint SSM parameter. Account-level bootstrap must be completed first.

## What Gets Created

| Resource | Example name |
|---|---|
| ECR repository | `example-monorepo-example-api` |
| Lambda function + alias | `example-monorepo-staging-example-api` |
| API Gateway HTTP API | `example-monorepo-staging-example-api` |
| CloudWatch log group | `/aws/lambda/example-monorepo-staging-example-api` |
| API endpoint SSM parameter | `/example-monorepo/staging/api-gateway-endpoint` |

## First-Time Flow

```bash
aws sso login --profile example-monorepo-staging
export AWS_PROFILE=example-monorepo-staging
make infra-generate-backend-configs
make infra-init APP=example-api ENV=staging
```

Push a bootstrap image to the ECR repository, set `lambda_bootstrap_image_uri` in `terraform.tfvars`, then run:

```bash
make infra-plan APP=example-api ENV=staging
make infra-apply APP=example-api ENV=staging
```

## GitHub Variables

Set these repository variables from Terraform outputs before enabling deploy workflows:

| Variable | Source |
|---|---|
| `EXAMPLE_API_STAGING_AWS_DEPLOY_ROLE_ARN` | `github_deploy_role_arn` |
| `EXAMPLE_API_ECR_REPOSITORY` | repository name from `ecr_repository_url` |
| `EXAMPLE_API_STAGING_LAMBDA_FUNCTION_NAME` | `lambda_function_name` |
| `EXAMPLE_API_STAGING_LAMBDA_ALIAS_NAME` | `live` |
| `EXAMPLE_API_STAGING_API_ENDPOINT` | `api_gateway_endpoint` |

The boilerplate uses `example-monorepo` defaults for greenfield deployments. Change `project_name`, state keys, and SSM prefixes before first apply for a real project.
