#!/bin/bash
# icci-skills version checker
# Called by Claude Code skills on first trigger to detect stale installations.
#
# Usage: version-check.sh [skill-name]
#   skill-name: optional, checks a specific skill's VERSION file
#
# Exit codes:
#   0 = up to date
#   1 = updates available (prints changelog)
#   2 = not a git repo / not installed correctly

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_NAME="${1:-}"

# Verify this is a git repo
if ! git -C "$REPO_DIR" rev-parse --git-dir &>/dev/null; then
    echo "ERROR: $REPO_DIR is not a git repository."
    echo "Re-clone: git clone git@github.com:icci/icci-skills.git ~/Documents/GitHub/icci-skills"
    exit 2
fi

# Fetch latest (quiet, no merge)
git -C "$REPO_DIR" fetch --quiet origin main 2>/dev/null || {
    echo "WARNING: Could not reach GitHub. Skipping version check."
    exit 0
}

LOCAL=$(git -C "$REPO_DIR" rev-parse HEAD)
REMOTE=$(git -C "$REPO_DIR" rev-parse origin/main)

if [ "$LOCAL" = "$REMOTE" ]; then
    if [ -n "$SKILL_NAME" ] && [ -f "$REPO_DIR/skills/$SKILL_NAME/VERSION" ]; then
        VERSION=$(head -1 "$REPO_DIR/skills/$SKILL_NAME/VERSION")
        echo "✓ $SKILL_NAME v$VERSION — up to date"
    else
        echo "✓ All skills up to date"
    fi
    exit 0
fi

# Count commits behind
BEHIND=$(git -C "$REPO_DIR" rev-list HEAD..origin/main --count)

echo "UPDATE AVAILABLE: $BEHIND new commit(s) on origin/main"
echo ""

# Show what changed
if [ -n "$SKILL_NAME" ]; then
    # Show only commits touching this skill
    SKILL_COMMITS=$(git -C "$REPO_DIR" log HEAD..origin/main --oneline -- "skills/$SKILL_NAME/")
    if [ -n "$SKILL_COMMITS" ]; then
        echo "Changes to $SKILL_NAME:"
        echo "$SKILL_COMMITS"
    else
        echo "No changes to $SKILL_NAME specifically, but other skills were updated."
    fi
else
    git -C "$REPO_DIR" log HEAD..origin/main --oneline
fi

echo ""
echo "To update:  cd ~/Documents/GitHub/icci-skills && git pull"
exit 1
