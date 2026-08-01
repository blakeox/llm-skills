#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_DIR="${1:-$HOME/.codex/skills}"

python3 "$REPO_DIR/scripts/validate-skill-bench.py"
python3 "$SCRIPT_DIR/sync-codex-skills.py" --dest "$TARGET_DIR" --check
