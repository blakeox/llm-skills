#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "LLM Skills — Codex installer"
echo "Bundle version: $(tr -d '[:space:]' < "$REPO_DIR/VERSION")"
echo

"$SCRIPT_DIR/install-codex-skills.sh"

echo
echo "Canonical skills were rendered into Codex-native copies."
echo "OpenClaw agent wrappers are not installed into Codex because their invocation contract is platform-specific."
