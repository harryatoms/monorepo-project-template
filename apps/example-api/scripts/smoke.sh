#!/usr/bin/env bash
# Post-deploy endpoint verification for the example API.
set -euo pipefail

BASE="${1:-${API_ENDPOINT:-}}"

if [[ -z "$BASE" ]]; then
  echo "usage: $0 <api-endpoint>" >&2
  echo "or set API_ENDPOINT=https://..." >&2
  exit 1
fi

BASE="${BASE%/}"
PASS=0
FAIL=0

_ok()   { printf "  ✓  %s\n" "$1"; PASS=$((PASS + 1)); }
_fail() { printf "  ✗  %s\n" "$1"; FAIL=$((FAIL + 1)); }

_request() {
  local method="$1" url="$2"
  curl -s --max-time 30 -w $'\n%{http_code}' -X "$method" "$url"
}

_status() { printf '%s' "$1" | sed -n '$p'; }
_body()   { printf '%s' "$1" | sed '$d'; }

printf "\nSmoke test: %s\n" "$BASE"
printf "%s\n\n" "────────────────────────────────────────────────"

RESP=$(_request GET "${BASE}/")
STATUS=$(_status "$RESP")
if [[ "$STATUS" == "200" ]]; then
  _ok "GET /  →  HTTP 200"
else
  _fail "GET /  →  expected 200, got ${STATUS}"
  printf "         body: %s\n" "$(_body "$RESP")"
fi

RESP=$(_request GET "${BASE}/health")
STATUS=$(_status "$RESP")
BODY=$(_body "$RESP")
if [[ "$STATUS" == "200" ]]; then
  _ok "GET /health  →  HTTP 200"
else
  _fail "GET /health  →  expected 200, got ${STATUS}"
  printf "         body: %s\n" "$BODY"
fi

if [[ "$BODY" == *'"status"'* ]]; then
  _ok "GET /health  →  status field present"
else
  _fail "GET /health  →  status field missing from response body"
fi

RESP=$(_request GET "${BASE}/sample-resource")
STATUS=$(_status "$RESP")
BODY=$(_body "$RESP")
if [[ "$STATUS" == "200" ]]; then
  _ok "GET /sample-resource  →  HTTP 200"
else
  _fail "GET /sample-resource  →  expected 200, got ${STATUS}"
  printf "         body: %s\n" "$BODY"
fi

for field in id name description tags; do
  if [[ "$BODY" == *"\"${field}\""* ]]; then
    _ok "GET /sample-resource  →  ${field}"
  else
    _fail "GET /sample-resource  →  ${field} missing from response"
  fi
done

printf "\n%s\n" "────────────────────────────────────────────────"
if [[ "$FAIL" -eq 0 ]]; then
  printf "  All %d checks passed.\n\n" "$PASS"
else
  printf "  %d passed, %d failed.\n\n" "$PASS" "$FAIL"
  exit 1
fi
