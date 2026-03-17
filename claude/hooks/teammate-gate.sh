#!/bin/bash
# Quality gate for agent team teammates going idle
# Exit 0 = accept idle. Exit 2 = send feedback, keep working.
INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[ -z "$CWD" ] && exit 0

cd "$CWD" 2>/dev/null || exit 0

# Check if there are unstaged changes (teammate made edits but didn't verify)
if git rev-parse --is-inside-work-tree &>/dev/null; then
  DIRTY=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
  if [ "$DIRTY" -gt 0 ]; then
    # If tests exist, run them
    if [ -f "package.json" ]; then
      if node -e "const p=require('./package.json'); process.exit(p.scripts && p.scripts.test ? 0 : 1)" 2>/dev/null; then
        if ! timeout 60 npm test --silent 2>/dev/null; then
          echo "You have $DIRTY modified files and tests are failing. Fix tests before going idle." >&2
          exit 2
        fi
      fi
    fi
  fi
fi

exit 0
