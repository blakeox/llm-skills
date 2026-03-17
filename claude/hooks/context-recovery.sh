#!/bin/bash
# After compaction or resume, re-inject git and working directory context
INPUT=$(cat)
SOURCE=$(echo "$INPUT" | jq -r '.source // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Only fire on compact or resume, not fresh startup
case "$SOURCE" in
  compact|resume|clear) ;;
  *) exit 0 ;;
esac

[ -z "$CWD" ] && exit 0
cd "$CWD" 2>/dev/null || exit 0

# Output goes to stdout and is injected into Claude's context
echo "=== Context recovery ==="

if git rev-parse --is-inside-work-tree &>/dev/null; then
  BRANCH=$(git branch --show-current 2>/dev/null)
  echo "Branch: $BRANCH"
  echo "Recent commits:"
  git log --oneline -5 2>/dev/null
  echo ""

  DIRTY=$(git status --porcelain 2>/dev/null | head -10)
  if [ -n "$DIRTY" ]; then
    echo "Uncommitted changes:"
    echo "$DIRTY"
  fi
fi

echo "Working directory: $CWD"
echo "=== End context recovery ==="

exit 0
