#!/bin/bash
# Auto-lint after file edits. Customize the linter command for your project.
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -z "$FILE" ] && exit 0

# Uncomment the linter for your stack:
# npx eslint --fix "$FILE" 2>/dev/null
# npx prettier --write "$FILE" 2>/dev/null
# ruff check --fix "$FILE" 2>/dev/null
# go fmt "$FILE" 2>/dev/null

exit 0
