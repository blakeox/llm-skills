#!/bin/bash
# On stop: check if tests exist and pass. Non-blocking — warns but doesn't prevent stop.
# Exit 0 = let Claude stop. Exit 2 = send feedback, keep working.
INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[ -z "$CWD" ] && exit 0

cd "$CWD" 2>/dev/null || exit 0

# Detect test runner and check if tests pass
if [ -f "package.json" ]; then
  # Node project — check if test script exists
  if node -e "const p=require('./package.json'); process.exit(p.scripts && p.scripts.test ? 0 : 1)" 2>/dev/null; then
    # Run tests with a timeout
    if ! timeout 60 npm test --silent 2>/dev/null; then
      echo "Tests are failing. Fix them before finishing." >&2
      exit 2
    fi
  fi
elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
  if command -v pytest &>/dev/null; then
    if ! timeout 60 pytest --tb=no -q 2>/dev/null; then
      echo "Tests are failing. Fix them before finishing." >&2
      exit 2
    fi
  fi
elif [ -f "go.mod" ]; then
  if ! timeout 60 go test ./... -count=1 -short 2>/dev/null; then
    echo "Tests are failing. Fix them before finishing." >&2
    exit 2
  fi
fi

exit 0
