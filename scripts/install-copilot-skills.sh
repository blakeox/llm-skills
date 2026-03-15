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

mkdir -p "$TARGET_DIR"

while IFS= read -r skill || [[ -n "$skill" ]]; do
  [[ -z "$skill" ]] && continue
  SOURCE_PATH="$REPO_DIR/skills/$skill/"
  TARGET_PATH="$TARGET_DIR/$skill/"

  if [[ ! -d "$SOURCE_PATH" ]]; then
    echo "ERROR: Missing source directory $SOURCE_PATH" >&2
    exit 1
  fi

  rsync -a --delete "$SOURCE_PATH" "$TARGET_PATH"
  echo "Installed $skill -> $TARGET_PATH"
done < "$MANIFEST"

echo
echo "Install complete. Start a new Copilot session so the updated skills are loaded."
