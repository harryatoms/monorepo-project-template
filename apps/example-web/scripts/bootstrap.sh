#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$APP_DIR"

npm install

echo "✓ Bootstrap complete. Run npm run dev from apps/example-web to start the frontend."
