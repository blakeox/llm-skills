#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<'EOF'
Usage: scripts/bootstrap-repo-bench.sh <target-repo> [--copy-agents] [--force]

Copy the core llm-skills repository guidance files into another repository.

Options:
  --copy-agents  Also copy .github/agents/*.agent.md into the target repo.
  --force        Overwrite existing files instead of skipping them.
EOF
}

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 1
fi

TARGET_ROOT=""
COPY_AGENTS=0
FORCE=0

for arg in "$@"; do
  case "$arg" in
    --copy-agents)
      COPY_AGENTS=1
      ;;
    --force)
      FORCE=1
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      if [[ -z "$TARGET_ROOT" ]]; then
        TARGET_ROOT="$arg"
      else
        echo "ERROR: Unexpected argument: $arg" >&2
        usage >&2
        exit 1
      fi
      ;;
  esac
done

if [[ -z "$TARGET_ROOT" ]]; then
  echo "ERROR: Missing target repo path" >&2
  usage >&2
  exit 1
fi

TARGET_ROOT="$(cd "$TARGET_ROOT" && pwd)"

if [[ ! -d "$TARGET_ROOT" ]]; then
  echo "ERROR: Target repo does not exist: $TARGET_ROOT" >&2
  exit 1
fi

display_path() {
  local path="$1"
  python3 - "$TARGET_ROOT" "$path" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
path = Path(sys.argv[2])

try:
    print(path.relative_to(root))
except ValueError:
    print(path)
PY
}

install_file() {
  local source="$1"
  local destination="$2"

  mkdir -p "$(dirname "$destination")"

  if [[ -e "$destination" && "$FORCE" -ne 1 ]]; then
    echo "Skipped $(display_path "$destination")"
    return
  fi

  cp "$source" "$destination"
  echo "Wrote $(display_path "$destination")"
}

install_file "$REPO_DIR/AGENTS.md" "$TARGET_ROOT/AGENTS.md"
install_file "$REPO_DIR/CLAUDE.md" "$TARGET_ROOT/CLAUDE.md"
install_file "$REPO_DIR/.github/copilot-instructions.md" "$TARGET_ROOT/.github/copilot-instructions.md"
install_file "$REPO_DIR/.github/instructions/skills.instructions.md" "$TARGET_ROOT/.github/instructions/skills.instructions.md"
install_file "$REPO_DIR/.github/instructions/agents.instructions.md" "$TARGET_ROOT/.github/instructions/agents.instructions.md"

if [[ "$COPY_AGENTS" -eq 1 ]]; then
  while IFS= read -r agent; do
    install_file "$agent" "$TARGET_ROOT/.github/agents/$(basename "$agent")"
  done < <(find "$REPO_DIR/.github/agents" -maxdepth 1 -type f -name '*.agent.md' | sort)
fi

echo
echo "Bootstrap complete for $TARGET_ROOT"
echo "Next steps:"
echo "  1. Review the copied guidance files and trim anything your repo does not need."
echo "  2. Commit the new files in the target repository."
if [[ "$COPY_AGENTS" -eq 1 ]]; then
  echo "  3. Install or verify the copied Copilot agents inside that repo as needed."
fi
