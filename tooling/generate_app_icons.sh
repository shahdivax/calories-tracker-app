#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ $# -gt 0 ]]; then
  python3 "$ROOT_DIR/tooling/generate_app_icons.py" "$1"
else
  python3 "$ROOT_DIR/tooling/generate_app_icons.py"
fi
