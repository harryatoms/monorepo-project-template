#!/usr/bin/env bash
# Report the currently deployed version of the example API Lambda function.
set -euo pipefail

ENV="${ENV:-staging}"
AWS_REGION="${AWS_REGION:-$(aws configure get region 2>/dev/null)}"
: "${AWS_REGION:?could not determine AWS_REGION — set it explicitly or ensure your AWS profile has a default region}"
FUNCTION_NAME="${FUNCTION_NAME:-example-monorepo-${ENV}-example-api}"
ALIAS_NAME="${ALIAS_NAME:-live}"

LIVE_VERSION=$(aws lambda get-alias \
  --function-name "$FUNCTION_NAME" \
  --name "$ALIAS_NAME" \
  --region "$AWS_REGION" \
  --query 'FunctionVersion' \
  --output text)

FUNCTION_CONFIG=$(aws lambda get-function \
  --function-name "$FUNCTION_NAME" \
  --qualifier "$LIVE_VERSION" \
  --region "$AWS_REGION" \
  --query '{ImageUri: Code.ImageUri, LastModified: Configuration.LastModified}' \
  --output json)

IMAGE_URI=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["ImageUri"])' <<<"$FUNCTION_CONFIG")
LAST_MODIFIED=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["LastModified"])' <<<"$FUNCTION_CONFIG")

if [[ -z "${API_ENDPOINT:-}" ]]; then
  API_ENDPOINT=$(aws apigatewayv2 get-apis \
    --region "$AWS_REGION" \
    --query "Items[?Name=='${FUNCTION_NAME}'].ApiEndpoint | [0]" \
    --output text 2>/dev/null || true)
fi

echo "function:      $FUNCTION_NAME"
echo "alias:         $ALIAS_NAME → version $LIVE_VERSION"
echo "image:         $IMAGE_URI"
echo "last modified: $LAST_MODIFIED"

if [[ -n "${API_ENDPOINT:-}" && "$API_ENDPOINT" != "None" ]]; then
  echo "api endpoint:  ${API_ENDPOINT%/}"
fi
