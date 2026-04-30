#!/usr/bin/env bash
# Deploy the static site build to S3 and invalidate the CloudFront cache.
#
# Required environment variables:
#   S3_BUCKET                    — target S3 bucket name
#   CLOUDFRONT_DISTRIBUTION_ID   — CloudFront distribution to invalidate

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${APP_DIR}/build"

: "${S3_BUCKET:?S3_BUCKET must be set}"
: "${CLOUDFRONT_DISTRIBUTION_ID:?CLOUDFRONT_DISTRIBUTION_ID must be set}"

if [[ ! -d "${BUILD_DIR}" ]]; then
  echo "error: build directory not found at ${BUILD_DIR}. run 'npm run build' first." >&2
  exit 1
fi

echo "syncing build/ to s3://${S3_BUCKET}..."
aws s3 sync "${BUILD_DIR}" "s3://${S3_BUCKET}" \
  --delete \
  --cache-control "public, max-age=31536000, immutable" \
  --exclude "*.html"

# HTML files should not be cached aggressively so browsers always fetch fresh.
aws s3 sync "${BUILD_DIR}" "s3://${S3_BUCKET}" \
  --delete \
  --cache-control "public, no-cache" \
  --exclude "*" \
  --include "*.html"

echo "creating cloudfront invalidation for distribution ${CLOUDFRONT_DISTRIBUTION_ID}..."
INVALIDATION_ID=$(aws cloudfront create-invalidation \
  --distribution-id "${CLOUDFRONT_DISTRIBUTION_ID}" \
  --paths "/*" \
  --query "Invalidation.Id" \
  --output text)

echo "invalidation ${INVALIDATION_ID} created."
echo "deploy complete."
