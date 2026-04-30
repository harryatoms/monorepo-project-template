#!/usr/bin/env bash
# Smoke test: verifies the deployed frontend is reachable and returns HTTP 200.
#
# Required environment variables:
#   APP_ENDPOINT  — base URL of the deployed frontend (e.g. https://d1234.cloudfront.net)

set -euo pipefail

: "${APP_ENDPOINT:?APP_ENDPOINT must be set}"

echo "smoke testing ${APP_ENDPOINT}..."

HTTP_STATUS=$(curl --silent --output /dev/null --write-out "%{http_code}" \
  --max-time 15 "${APP_ENDPOINT}/")

if [[ "${HTTP_STATUS}" == "200" ]]; then
  echo "smoke test passed (HTTP ${HTTP_STATUS})."
else
  echo "smoke test failed (HTTP ${HTTP_STATUS})." >&2
  exit 1
fi
