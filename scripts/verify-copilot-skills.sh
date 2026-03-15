#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$REPO_DIR/skills/manifest.txt"
TARGET_DIR="${1:-$HOME/.copilot/skills}"

if [[ ! -f "$MANIFEST" ]]; then
  echo "ERROR: Missing manifest at $MANIFEST" >&2
  exit 1
fi

missing=0

while IFS= read -r skill || [[ -n "$skill" ]]; do
  [[ -z "$skill" ]] && continue
  TARGET_PATH="$TARGET_DIR/$skill"
  if [[ ! -d "$TARGET_PATH" ]]; then
    echo "MISSING: $TARGET_PATH"
    missing=1
    continue
  fi

  if [[ "$skill" == "_house-style" ]]; then
    required=("house-style.md" "workflow-guide.md")
  else
    required=("SKILL.md")
  fi

  for entry in "${required[@]}"; do
    if [[ ! -e "$TARGET_PATH/$entry" ]]; then
      echo "MISSING: $TARGET_PATH/$entry"
      missing=1
    fi
  done
done < "$MANIFEST"

if [[ "$missing" -ne 0 ]]; then
  echo
  echo "Verification failed. Re-run scripts/install-copilot-skills.sh and start a new Copilot session." >&2
  exit 1
fi

echo "Verification passed for $TARGET_DIR"
