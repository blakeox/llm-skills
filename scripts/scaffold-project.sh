#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SCAFFOLD="$REPO_DIR/templates/project-scaffold"
TARGET="${1:-.}"

echo "LLM Skills — Project scaffold"
echo

if [[ ! -d "$TARGET" ]]; then
  echo "ERROR: Target directory $TARGET does not exist" >&2
  exit 1
fi

# Copy CLAUDE.md if missing
if [[ ! -f "$TARGET/CLAUDE.md" ]]; then
  cp "$SCAFFOLD/CLAUDE.md" "$TARGET/CLAUDE.md"
  echo "Created CLAUDE.md"
else
  echo "CLAUDE.md exists (not overwritten)"
fi

# Create .claude directory structure
mkdir -p "$TARGET/.claude/hooks"

if [[ ! -f "$TARGET/.claude/settings.json" ]]; then
  cp "$SCAFFOLD/.claude/settings.json" "$TARGET/.claude/settings.json"
  echo "Created .claude/settings.json"
else
  echo ".claude/settings.json exists (not overwritten)"
fi

if [[ ! -f "$TARGET/.claude/hooks/lint-on-edit.sh" ]]; then
  cp "$SCAFFOLD/.claude/hooks/lint-on-edit.sh" "$TARGET/.claude/hooks/lint-on-edit.sh"
  chmod +x "$TARGET/.claude/hooks/lint-on-edit.sh"
  echo "Created .claude/hooks/lint-on-edit.sh"
fi

if [[ ! -f "$TARGET/.claude/settings.local.json" ]]; then
  cp "$SCAFFOLD/.claude/settings.local.json.example" "$TARGET/.claude/settings.local.json.example"
  echo "Created .claude/settings.local.json.example (rename to activate)"
fi

# Add .claude/settings.local.json to .gitignore if not already there
GITIGNORE="$TARGET/.gitignore"
if [[ -f "$GITIGNORE" ]]; then
  if ! grep -q "settings.local.json" "$GITIGNORE" 2>/dev/null; then
    echo ".claude/settings.local.json" >> "$GITIGNORE"
    echo "Added settings.local.json to .gitignore"
  fi
fi

echo
echo "Scaffold complete. Edit CLAUDE.md with your project's build commands and conventions."
echo "Uncomment the linter in .claude/hooks/lint-on-edit.sh for your stack."
