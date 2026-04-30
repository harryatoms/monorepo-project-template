#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="$APP_DIR/.venv"

if [[ ! -f "$VENV_DIR/bin/activate" ]]; then
  echo "✗ Virtual environment not found. Run make bootstrap first." >&2
  exit 1
fi

source "$VENV_DIR/bin/activate"

cd "$APP_DIR"
exec python server.py
