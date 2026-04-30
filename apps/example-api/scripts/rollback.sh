#!/usr/bin/env bash
# rollback.sh — Repoint the Lambda alias to a previously published version.
#
# What it does:
#   1. Records the currently live Lambda version for reference.
#   2. Updates the alias to the requested target version number.
#   3. Prints a smoke test command to confirm the rollback.
#
# This script does NOT redeploy code or publish a new version — it only moves
# the alias pointer to an already-published immutable version.
#
# Environment variables (all optional — derived from ENV when not set):
#   ENV             — Target environment (default: staging)
#   AWS_REGION      — Derived from the active AWS profile when not set
#   FUNCTION_NAME   — Defaults to example-monorepo-${ENV}-example-api
#   ALIAS_NAME      — Defaults to live
#
# Arguments:
#   <target-version>  — The Lambda version number to roll back to.
#                       deploy.sh prints this after a successful deploy
#                       under "to rollback: ./rollback.sh <version>".
#
# Usage:
#   ENV=staging ./rollback.sh <target-version>
#   make rollback ENV=staging VERSION=7
#
# Example:
#   ENV=staging ./rollback.sh 7
set -euo pipefail

# ─── Resolve config with convention-based defaults ───────────────────────────

ENV="${ENV:-staging}"

AWS_REGION="${AWS_REGION:-$(aws configure get region 2>/dev/null)}"
: "${AWS_REGION:?could not determine AWS_REGION — set it explicitly or ensure your AWS profile has a default region}"

FUNCTION_NAME="${FUNCTION_NAME:-example-monorepo-${ENV}-example-api}"
ALIAS_NAME="${ALIAS_NAME:-live}"

# ─── Validate target version argument ────────────────────────────────────────

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <target-version>" >&2
  exit 1
fi

TARGET_VERSION="$1"

if [[ ! "$TARGET_VERSION" =~ ^[0-9]+$ ]]; then
  echo "error: target version must be a positive integer (got: '$TARGET_VERSION')" >&2
  exit 1
fi

# ─── Capture current alias target before we move it ──────────────────────────

CURRENT_VERSION=$(aws lambda get-alias \
  --function-name "$FUNCTION_NAME" \
  --name "$ALIAS_NAME" \
  --region "$AWS_REGION" \
  --query 'FunctionVersion' \
  --output text)

echo "current live version: $CURRENT_VERSION"
echo "rolling back to version: $TARGET_VERSION"

# ─── Move alias to target version ────────────────────────────────────────────

aws lambda update-alias \
  --function-name "$FUNCTION_NAME" \
  --name "$ALIAS_NAME" \
  --function-version "$TARGET_VERSION" \
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

if [[ -n "${API_ENDPOINT:-}" ]]; then
  echo "smoke test:    curl ${API_ENDPOINT%/}/health"
else
  echo "smoke test: export API_ENDPOINT and re-run, or retrieve it from your infrastructure outputs."
fi
