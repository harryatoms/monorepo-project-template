# Infrastructure Operations

This boilerplate includes Terraform for account bootstrap resources and per-app infrastructure.

## Layout

```text
infra/
├── bootstrap/                         # Shared state bucket, lock table, OIDC provider
└── environments/staging/apps/
    ├── example-api/                   # Lambda, API Gateway, ECR, alarms
    └── example-web/                   # S3 and CloudFront static site
```

## Greenfield Defaults

The Terraform defaults use `example-monorepo` as the project prefix. Changing `project_name`, SSM paths, or backend state keys creates a new greenfield deployment surface. Treat those values as starter placeholders, not an in-place migration strategy for existing AWS resources.

## Backend Configs

Generate local backend configs after bootstrap:

```bash
make infra-generate-backend-configs
```

Then initialize an app module:

```bash
make infra-init APP=example-api ENV=staging
make infra-plan APP=example-api ENV=staging
```
