#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"
API_DIR="$REPO_ROOT/apps/example-api"
VENV_DIR="$API_DIR/.venv"

if ! python3 -c "import subprocess" 2>/dev/null; then
  echo "✗ Python interpreter is broken or missing C extensions."
  echo "  Try: mise uninstall python && mise install python"
  exit 1
fi

venv_healthy() {
  [ -d "$VENV_DIR" ] && "$VENV_DIR/bin/python3" -c "import subprocess" 2>/dev/null
}

if venv_healthy; then
  echo "→ Virtual environment already exists at $VENV_DIR — skipping creation"
else
  if [ -d "$VENV_DIR" ]; then
    echo "→ Virtual environment at $VENV_DIR is broken — recreating"
    rm -rf "$VENV_DIR"
  fi
  echo "→ Creating virtual environment at $VENV_DIR"
  python3 -m venv "$VENV_DIR"
fi

echo "→ Installing dependencies"
"$VENV_DIR/bin/pip" install --upgrade pip -q
"$VENV_DIR/bin/pip" install -e "$API_DIR[dev]"

if [ -d "$REPO_ROOT/packages/example-prompts" ]; then
  "$VENV_DIR/bin/pip" install -e "$REPO_ROOT/packages/example-prompts"
fi
if [ -d "$REPO_ROOT/packages/example-evals" ]; then
  "$VENV_DIR/bin/pip" install -e "$REPO_ROOT/packages/example-evals"
fi

echo "✓ Bootstrap complete. Run apps/example-api/scripts/run.sh to start the server."
