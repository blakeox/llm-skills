#!/bin/bash
# Block commits containing debug artifacts in source code
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$COMMAND" ] && exit 0

# Only check git commit commands
echo "$COMMAND" | grep -q "git commit" || exit 0

# Check staged diff for debug code in source files only (skip .sh, .md, .example)
MATCHES=$(git diff --cached --diff-filter=ACMR -- '*.ts' '*.tsx' '*.js' '*.jsx' '*.py' '*.rb' 2>/dev/null | grep -cE '^\+.*(console\.log|debugger;|binding\.pry|import pdb|\.only\(|\.skip\()' || true)

if [ "$MATCHES" -gt 0 ]; then
  git diff --cached --diff-filter=ACMR -- '*.ts' '*.tsx' '*.js' '*.jsx' '*.py' '*.rb' 2>/dev/null | grep -En '^\+.*(console\.log|debugger;|binding\.pry|import pdb|\.only\(|\.skip\()' | head -5
  echo "Blocked: $MATCHES debug artifact(s) found in staged source files." >&2
  exit 2
fi

exit 0
