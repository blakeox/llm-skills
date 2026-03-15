#!/bin/bash
# ============================================================================
# Script Name  : validate-skill.sh
# Author       : ICCI, LLC (Aaron Salsitz)
# Organization : ICCI, LLC — Secure. Governed. Operational.
# Title        : ICCI Skill Validator
# Created      : 13MAR26
# Version      : 1.0.0
# Description  : Validates an ICCI skill directory against all ICCI standards.
#                Checks structure, frontmatter, security, branding, cross-skill
#                delegation, formatting, and conventions.
# Usage        : ./validate-skill.sh <path-to-skill-directory>
# Notes        : Non-destructive — reads only, never modifies files.
#                Exit code 0 = all checks pass, 1 = failures found.
# License      : CC BY 4.0 — https://creativecommons.org/licenses/by/4.0/
# Changes      :
#   1.0.0 — 13MAR26 — Initial version
# ============================================================================

set -euo pipefail

# Use GNU grep if available (macOS BSD grep lacks -P)
if command -v ggrep &>/dev/null; then
  GREP=ggrep
else
  GREP="grep"
fi

# Colors
RED='\033[0;31m'
ORANGE='\033[0;33m'
GREEN='\033[0;32m'
# shellcheck disable=SC2034  # Reserved for future summary output
REVERSED='\033[7m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

pass() {
  PASS=$((PASS + 1))
  echo -e "  ${GREEN}PASS${NC}  $*"
}
fail() {
  FAIL=$((FAIL + 1))
  echo -e "  ${RED}FAIL${NC}  $*"
}
warn() {
  WARN=$((WARN + 1))
  echo -e "  ${ORANGE}WARN${NC}  $*"
}

# Validate arguments
if [ $# -lt 1 ]; then
  echo "Usage: validate-skill.sh <path-to-skill-directory>"
  exit 1
fi

SKILL_DIR="$1"

if [ ! -d "$SKILL_DIR" ]; then
  echo -e "${RED}ERROR: Not a directory: $SKILL_DIR${NC}"
  exit 1
fi

SKILL_NAME=$(basename "$SKILL_DIR")
echo ""
echo "========================================="
echo "  ICCI Skill Validator"
echo "  Skill: $SKILL_NAME"
echo "  Path:  $SKILL_DIR"
echo "========================================="
echo ""

# ---- STRUCTURE CHECKS ----
echo "--- Structure ---"

if [ -f "$SKILL_DIR/SKILL.md" ]; then
  pass "SKILL.md exists"
else
  fail "SKILL.md missing (required)"
fi

if [ -f "$SKILL_DIR/USAGE.md" ]; then
  pass "USAGE.md exists"
else
  fail "USAGE.md missing (required)"
fi

if [ -f "$SKILL_DIR/README.md" ]; then
  pass "README.md exists"
else
  fail "README.md missing (required)"
fi

if [ -f "$SKILL_DIR/VERSION" ]; then
  pass "VERSION exists"
else
  fail "VERSION missing (required)"
fi

if [ -f "$SKILL_DIR/LESSONS-LEARNED.md" ]; then
  pass "LESSONS-LEARNED.md exists"
else
  fail "LESSONS-LEARNED.md missing (required)"
fi

if [ -f "$SKILL_DIR/LICENSE.txt" ]; then
  pass "LICENSE.txt exists"
else
  fail "LICENSE.txt missing (required)"
fi

echo ""

# ---- FRONTMATTER CHECKS ----
echo "--- Frontmatter (SKILL.md) ---"

if [ -f "$SKILL_DIR/SKILL.md" ]; then
  # Check YAML frontmatter exists
  if head -1 "$SKILL_DIR/SKILL.md" | grep -q "^---$"; then
    pass "YAML frontmatter detected"

    # Extract frontmatter (between first and second ---)
    FRONTMATTER=$(awk 'NR==1{next} /^---$/{exit} {print}' "$SKILL_DIR/SKILL.md")

    # Check name field
    if echo "$FRONTMATTER" | grep -q "^name:"; then
      pass "name field present"
    else
      fail "name field missing in frontmatter"
    fi

    # Check description field
    if echo "$FRONTMATTER" | grep -q "^description:"; then
      pass "description field present"

      # Check description length (should be pushy, 50+ words)
      DESC=$(echo "$FRONTMATTER" | grep "^description:" | sed 's/^description: *//' | tr -d '"')
      WORD_COUNT=$(echo "$DESC" | wc -w | tr -d ' ')
      if [ "$WORD_COUNT" -ge 30 ]; then
        pass "description is substantial ($WORD_COUNT words)"
      else
        warn "description may be too short ($WORD_COUNT words) — aim for 50-150 words with specific trigger phrases"
      fi
    else
      fail "description field missing in frontmatter"
    fi
  else
    fail "No YAML frontmatter (must start with ---)"
  fi
fi

echo ""

# ---- CONTENT CHECKS ----
echo "--- Content ---"

if [ -f "$SKILL_DIR/SKILL.md" ]; then
  LINE_COUNT=$(wc -l <"$SKILL_DIR/SKILL.md" | tr -d ' ')
  if [ "$LINE_COUNT" -le 500 ]; then
    pass "SKILL.md is $LINE_COUNT lines (limit: 500)"
  else
    warn "SKILL.md is $LINE_COUNT lines (recommend: <500, move detail to references/)"
  fi

  # Check for Critical Rules section
  if grep -q "## Critical Rules" "$SKILL_DIR/SKILL.md"; then
    pass "Critical Rules section present"
  else
    warn "No '## Critical Rules' section found"
  fi

  # Check for Cross-Skill Delegation section
  if grep -qi "cross.skill\|delegation" "$SKILL_DIR/SKILL.md"; then
    pass "Cross-skill delegation section present"
  else
    warn "No cross-skill delegation section — skills should know their neighbors"
  fi

  # Check for Self-Improvement Protocol
  if grep -qi "self.improvement\|improvement protocol" "$SKILL_DIR/SKILL.md"; then
    pass "Self-improvement protocol present"
  else
    warn "No self-improvement protocol section"
  fi
fi

# Check README.md for origin prompt
if [ -f "$SKILL_DIR/README.md" ]; then
  if grep -q "^>" "$SKILL_DIR/README.md"; then
    pass "README.md contains blockquote (likely origin prompt)"
  else
    warn "README.md may be missing origin prompt (should have blockquoted founding prompt)"
  fi
fi

echo ""

# ---- SECURITY CHECKS ----
echo "--- Security ---"

# Check for embedded credentials
CRED_HITS=$(grep -rn \
  -e "api[_-]key.*=.*['\"][a-zA-Z0-9]" \
  -e "password.*=.*['\"][a-zA-Z0-9]" \
  -e "secret.*=.*['\"][a-zA-Z0-9]" \
  -e "bearer.*[a-zA-Z0-9]\{20,\}" \
  --include="*.md" --include="*.json" --include="*.sh" --include="*.py" \
  "$SKILL_DIR" 2>/dev/null | grep -v "template\|placeholder\|example\|your-.*-here\|<.*>\|typically\|prefix\|checklist\|Pattern\|pattern" || true)

if [ -z "$CRED_HITS" ]; then
  pass "No embedded credentials detected"
else
  fail "Possible embedded credentials found:"
  echo "$CRED_HITS" | head -5 | sed 's/^/         /'
fi

# Check for credential handling section
if [ -f "$SKILL_DIR/SKILL.md" ]; then
  if grep -qi "credential\|api.key\|session.start\|first use each session" "$SKILL_DIR/SKILL.md"; then
    pass "Credential handling section present"
  else
    warn "No credential handling section (required if skill uses external APIs)"
  fi
fi

# Check for repo security rule
if [ -f "$SKILL_DIR/SKILL.md" ]; then
  if grep -q "isPrivate" "$SKILL_DIR/SKILL.md"; then
    pass "Repository privacy check in Critical Rules"
  else
    warn "No repository privacy check in Critical Rules"
  fi
fi

echo ""

# ---- FORMATTING CHECKS ----
echo "--- Formatting ---"

# Check for hard returns mid-sentence in .md files
HARD_BREAKS=0
for md_file in "$SKILL_DIR"/*.md; do
  [ -f "$md_file" ] || continue
  # Look for lines that end with a lowercase letter (likely mid-sentence break)
  # Exclude code blocks, list items, headers, and short lines
  BREAKS=$(grep -n '[a-z,]$' "$md_file" | grep -v '^\s*[-*#|`>]' | grep -v '```' | head -5 || true)
  if [ -n "$BREAKS" ]; then
    HARD_BREAKS=$((HARD_BREAKS + 1))
  fi
done

if [ "$HARD_BREAKS" -eq 0 ]; then
  pass "No obvious hard line breaks mid-sentence"
else
  warn "Possible hard line breaks mid-sentence in $HARD_BREAKS file(s) — check manually"
fi

# Check for second person in SKILL.md
if [ -f "$SKILL_DIR/SKILL.md" ]; then
  SECOND_PERSON=$(grep -cn "\bYou should\b\|\bYou need\b\|\bYou must\b\|\bYou can\b" "$SKILL_DIR/SKILL.md" || true)
  if [ "$SECOND_PERSON" -eq 0 ]; then
    pass "No second-person language in SKILL.md"
  else
    warn "Found $SECOND_PERSON instances of second-person language in SKILL.md (prefer imperative form)"
  fi
fi

echo ""

# ---- REFERENCE CHECKS ----
echo "--- References ---"

# Check that all files referenced in SKILL.md exist
if [ -f "$SKILL_DIR/SKILL.md" ]; then
  REFS=$($GREP -oP 'references/[a-zA-Z0-9_-]+\.md' "$SKILL_DIR/SKILL.md" | sort -u || true)
  if [ -n "$REFS" ]; then
    while IFS= read -r ref; do
      if [ -f "$SKILL_DIR/$ref" ]; then
        pass "Referenced file exists: $ref"
      else
        fail "Referenced file MISSING: $ref"
      fi
    done <<<"$REFS"
  else
    warn "No reference files mentioned in SKILL.md"
  fi
fi

echo ""

# ---- SUMMARY ----
echo "========================================="
echo "  Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}, ${ORANGE}$WARN warnings${NC}"
echo "========================================="
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo -e "${RED}Skill has $FAIL failing check(s). Fix before shipping.${NC}"
  exit 1
else
  if [ "$WARN" -gt 0 ]; then
    echo -e "${ORANGE}Skill passes but has $WARN warning(s). Review recommended.${NC}"
  else
    echo -e "${GREEN}Skill passes all checks!${NC}"
  fi
  exit 0
fi
