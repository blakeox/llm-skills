#!/bin/bash
# ============================================================================
# Script Name  : scaffold-skill.sh
# Author       : ICCI, LLC (Aaron Salsitz)
# Organization : ICCI, LLC — Secure. Governed. Operational.
# Title        : ICCI Skill Directory Scaffolder
# Created      : 13MAR26
# Version      : 1.0.0
# Description  : Creates a complete ICCI-standard skill directory structure
#                with all required files pre-populated from templates.
# Usage        : ./scaffold-skill.sh <skill-name> [target-dir]
#                skill-name: lowercase, hyphens (e.g., icci-new-skill)
#                target-dir: where to create (default: ~/Documents/GitHub/icci-skills/skills/)
# Notes        : Templates are read from the icci-skill-creator templates/ directory.
#                Run from anywhere — the script locates templates relative to itself.
# License      : CC BY 4.0 — https://creativecommons.org/licenses/by/4.0/
# Changes      :
#   1.0.0 — 13MAR26 — Initial version
# ============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
ORANGE='\033[0;33m'
# shellcheck disable=SC2034  # Used in success() via variable expansion
GREEN='\033[0;32m'
REVERSED='\033[7m'
NC='\033[0m'

error() { echo -e "${RED}ERROR: $*${NC}" >&2; }
progress() { echo -e "${ORANGE}>>> $*${NC}"; }
success() {
  if command -v lolcat &>/dev/null; then
    echo "$*" | lolcat
  else
    echo -e "${REVERSED} $* ${NC}"
  fi
}

# Validate arguments
if [ $# -lt 1 ]; then
  error "Usage: scaffold-skill.sh <skill-name> [target-dir]"
  echo "  skill-name: lowercase, hyphens (e.g., icci-new-skill)"
  echo "  target-dir: where to create (default: ~/Documents/GitHub/icci-skills/skills/)"
  exit 1
fi

SKILL_NAME="$1"
TARGET_DIR="${2:-$HOME/Documents/GitHub/icci-skills/skills}"
SKILL_DIR="$TARGET_DIR/$SKILL_NAME"
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/templates"
TODAY=$(date +%Y-%m-%d)

# Validate skill name format
if [[ ! "$SKILL_NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
  error "Skill name must be lowercase letters, numbers, and hyphens. Got: $SKILL_NAME"
  exit 1
fi

# Check if directory already exists
if [ -d "$SKILL_DIR" ]; then
  error "Directory already exists: $SKILL_DIR"
  echo "  To start fresh, remove it first: rm -rf $SKILL_DIR"
  exit 1
fi

# Verify templates exist
if [ ! -d "$TEMPLATE_DIR" ]; then
  error "Templates directory not found: $TEMPLATE_DIR"
  echo "  This script must be run from the icci-skill-creator skill directory."
  exit 1
fi

progress "Creating skill directory: $SKILL_DIR"

# Create directory structure
mkdir -p "$SKILL_DIR"/{references,scripts,config,assets,evals}

# Generate SKILL.md from template
progress "Generating SKILL.md"
sed \
  -e "s/{{SKILL_NAME}}/$SKILL_NAME/g" \
  -e "s/{{Skill Title}}/${SKILL_NAME}/g" \
  -e "s/{{SKILL_NAME_UPPER}}/$(echo "$SKILL_NAME" | tr '[:lower:]-' '[:upper:]_')/g" \
  -e "s/{{repo}}/$SKILL_NAME/g" \
  "$TEMPLATE_DIR/SKILL.md.template" >"$SKILL_DIR/SKILL.md"

# Generate USAGE.md from template
progress "Generating USAGE.md"
sed \
  -e "s/{{Skill Name}}/$SKILL_NAME/g" \
  "$TEMPLATE_DIR/USAGE.md.template" >"$SKILL_DIR/USAGE.md"

# Generate README.md from template
progress "Generating README.md"
sed \
  -e "s/{{Skill Name}}/$SKILL_NAME/g" \
  -e "s/{{skill-name}}/$SKILL_NAME/g" \
  "$TEMPLATE_DIR/README.md.template" >"$SKILL_DIR/README.md"

# Generate LESSONS-LEARNED.md from template
progress "Generating LESSONS-LEARNED.md"
sed \
  -e "s/{{YYYY-MM-DD}}/$TODAY/g" \
  "$TEMPLATE_DIR/LESSONS-LEARNED.md.template" >"$SKILL_DIR/LESSONS-LEARNED.md"

# Create VERSION file
progress "Generating VERSION"
cat >"$SKILL_DIR/VERSION" <<EOF
1.0.0

## Changelog

### 1.0.0 — $TODAY
- Initial release
EOF

# Create LICENSE.txt
progress "Generating LICENSE.txt"
cat >"$SKILL_DIR/LICENSE.txt" <<'EOF'
PROPRIETARY — ICCI, LLC

This software and all associated documentation, scripts, and configuration
files are the proprietary property of ICCI, LLC. Unauthorized copying,
distribution, modification, or use of this software, in whole or in part,
is strictly prohibited without the express written permission of ICCI, LLC.

ICCI, LLC — Secure. Governed. Operational.
EOF

# Create branding-config.md reference
progress "Generating references/branding-config.md"
cat >"$SKILL_DIR/references/branding-config.md" <<EOF
# Branding Configuration

## Source
- Branding repo: \`~/Documents/GitHub/icci-report-branding/\`
- Brand identity: \`brand/identity.md\`
- CSS tokens: \`brand/tokens.css\`
- Templates: \`templates/\`
- Logos: \`assets/\`

## Report Output
- Directory: \`~/Documents/claude-code/$SKILL_NAME/reports/\`
- WeasyPrint: \`/opt/homebrew/Cellar/weasyprint/68.1/libexec/bin/python3\`

## Quick Color Reference
- Navy: #1B2B41 (headings, headers)
- Gold: #C9A55A (accents, borders)
- Cream: #F7F5F0 (backgrounds)
- Georgia serif for headings, Inter sans-serif for body
EOF

# Create empty evals.json
progress "Generating evals/evals.json"
cat >"$SKILL_DIR/evals/evals.json" <<EOF
{
  "skill_name": "$SKILL_NAME",
  "evals": []
}
EOF

# Create .gitkeep files for empty directories
touch "$SKILL_DIR/scripts/.gitkeep"
touch "$SKILL_DIR/config/.gitkeep"
touch "$SKILL_DIR/assets/.gitkeep"

# Summary
echo ""
success "Skill scaffolded successfully: $SKILL_DIR"
echo ""
echo "Created files:"
find "$SKILL_DIR" -type f | sort | sed "s|$SKILL_DIR/|  |"
echo ""
echo "Next steps:"
echo "  1. Edit SKILL.md — fill in description, workflows, delegation rules"
echo "  2. Edit USAGE.md — add real examples"
echo "  3. Edit README.md — add origin prompt"
echo "  4. Add API reference to references/ if needed"
echo "  5. Validate: bash $SCRIPT_DIR/scripts/validate-skill.sh $SKILL_DIR"
echo "  6. Symlink: ln -s $SKILL_DIR ~/.claude/skills/$SKILL_NAME"
