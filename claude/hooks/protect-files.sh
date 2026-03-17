#!/bin/bash
# Block edits to sensitive files
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -z "$FILE" ] && exit 0

PROTECTED=(".env" ".env.local" "credentials" "secrets/" ".git/" "package-lock.json" "yarn.lock" "pnpm-lock.yaml")

for pattern in "${PROTECTED[@]}"; do
  if [[ "$FILE" == *"$pattern"* ]]; then
    echo "Blocked edit to protected file matching: $pattern" >&2
    exit 2
  fi
done

exit 0
