#!/bin/bash
# Block destructive shell commands before execution
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$COMMAND" ] && exit 0

# Destructive patterns — block these outright
BLOCKED_PATTERNS=(
  'rm -rf /'
  'rm -rf ~'
  'rm -rf \.'
  'rm -rf \*'
  'git push.*--force.*main'
  'git push.*--force.*master'
  'git push.*-f.*main'
  'git push.*-f.*master'
  'git reset --hard'
  'git clean -fd'
  'git checkout -- \.'
  'git restore \.'
  'DROP TABLE'
  'DROP DATABASE'
  'TRUNCATE '
  'DELETE FROM.*WHERE 1'
  'kubectl delete namespace'
  'kubectl delete -f'
  'docker system prune -a'
  'chmod -R 777'
  'mkfs\.'
  ':(){:|:&};:'
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE "$pattern"; then
    echo "Blocked destructive command matching: $pattern" >&2
    echo "If this is intentional, ask the user to confirm before retrying." >&2
    exit 2
  fi
done

exit 0
