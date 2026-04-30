#!/usr/bin/env bash
# Release a new image to the example API Lambda function.
set -euo pipefail

ENV="${ENV:-staging}"
AWS_REGION="${AWS_REGION:-$(aws configure get region 2>/dev/null)}"
: "${AWS_REGION:?could not determine AWS_REGION — set it explicitly or ensure your AWS profile has a default region}"
FUNCTION_NAME="${FUNCTION_NAME:-example-monorepo-${ENV}-example-api}"
ALIAS_NAME="${ALIAS_NAME:-live}"
: "${IMAGE_URI:?IMAGE_URI must be set}"

CURRENT_VERSION=$(aws lambda get-alias \
  --function-name "$FUNCTION_NAME" \
  --name "$ALIAS_NAME" \
  --region "$AWS_REGION" \
  --query 'FunctionVersion' \
  --output text)

echo "current live version: $CURRENT_VERSION"
echo "updating function code: $IMAGE_URI"

aws lambda update-function-code \
  --function-name "$FUNCTION_NAME" \
  --image-uri "$IMAGE_URI" \
  --region "$AWS_REGION" \
  > /dev/null

echo "waiting for function update to complete..."
aws lambda wait function-updated \
  --function-name "$FUNCTION_NAME" \
  --region "$AWS_REGION"

NEW_VERSION=$(aws lambda publish-version \
  --function-name "$FUNCTION_NAME" \
  --region "$AWS_REGION" \
  --query 'Version' \
  --output text)

echo "new published version: $NEW_VERSION"

aws lambda update-alias \
  --function-name "$FUNCTION_NAME" \
  --name "$ALIAS_NAME" \
  --function-version "$NEW_VERSION" \
  --region "$AWS_REGION" \
  > /dev/null

CONFIRMED_VERSION=$(aws lambda get-alias \
  --function-name "$FUNCTION_NAME" \
  --name "$ALIAS_NAME" \
  --region "$AWS_REGION" \
  --query 'FunctionVersion' \
  --output text)

echo "alias '$ALIAS_NAME' now points to version: $CONFIRMED_VERSION"
echo ""
echo "to rollback:  ./rollback.sh '${CURRENT_VERSION}'"
echo ""

if [[ -n "${API_ENDPOINT:-}" ]]; then
  echo "API endpoint:  ${API_ENDPOINT%/}"
  echo "smoke test:    curl ${API_ENDPOINT%/}/health"
else
  echo "API_ENDPOINT not set. To smoke test, export API_ENDPOINT or retrieve it from your infrastructure outputs."
fi
