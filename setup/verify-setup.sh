#!/bin/bash
# ============================================================================
# Script Name  : verify-setup.sh
# Author       : ICCI, LLC (Aaron Salsitz)
# Organization : ICCI, LLC — Secure. Governed. Operational.
# Title        : ICCI Workstation Setup Verifier
# Created      : 13MAR26
# Version      : 1.0.0
# Description  : Checks that all ICCI tools, skills, MCPs, and directories
#                are correctly installed and configured. Non-destructive.
# Usage        : bash verify-setup.sh
# Notes        : Exit 0 = all good, Exit 1 = issues found.
# License      : CC BY 4.0 — https://creativecommons.org/licenses/by/4.0/
# Changes      :
#   1.0.0 — 13MAR26 — Initial version
# ============================================================================

set -uo pipefail

# Colors
RED='\033[0;31m'
ORANGE='\033[0;33m'
GREEN='\033[0;32m'
# shellcheck disable=SC2034
BLUE='\033[0;34m'
BOLD='\033[1m'
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
section() { echo -e "\n${BOLD}--- $* ---${NC}"; }

echo ""
echo -e "${BOLD}════════════════════════════════════════${NC}"
echo -e "${BOLD}  ICCI Workstation Setup Verifier${NC}"
echo -e "${BOLD}  $(date '+%Y-%m-%d %H:%M')${NC}"
echo -e "${BOLD}════════════════════════════════════════${NC}"

# ---- CORE TOOLS ----
section "Core Tools (Homebrew)"

check_tool() {
  local name="$1"
  local cmd="${2:-$1}"
  # shellcheck disable=SC2034
  local min_version="${3:-}" # Reserved for future version checking

  if command -v "$cmd" &>/dev/null; then
    local version
    version=$("$cmd" --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "?")
    pass "$name ($version)"
  else
    fail "$name — not installed (brew install $name)"
  fi
}

check_tool "Homebrew" "brew"
check_tool "git" "git"
check_tool "GitHub CLI" "gh"
check_tool "Node.js" "node"
check_tool "npm" "npm"
check_tool "Python 3" "python3"
check_tool "pip3" "pip3"
check_tool "AWS CLI" "aws"
check_tool "jq" "jq"
check_tool "yq" "yq"
check_tool "ripgrep" "rg"
check_tool "fd" "fd"
check_tool "bat" "bat"
check_tool "GNU grep" "ggrep"
check_tool "shellcheck" "shellcheck"
check_tool "shfmt" "shfmt"
check_tool "tree" "tree"
check_tool "wget" "wget"
check_tool "lefthook" "lefthook"
check_tool "WeasyPrint" "weasyprint"
check_tool "1Password CLI" "op"
check_tool "git-delta" "delta"

section "npm Global Packages"

if npm list -g prettier &>/dev/null 2>&1; then
  pass "prettier"
else
  fail "prettier — not installed (npm install -g prettier)"
fi

section "Python Packages"

for pkg in jinja2 pyyaml click; do
  if pip3 show "$pkg" &>/dev/null 2>&1; then
    pass "$pkg"
  else
    warn "$pkg — not installed (pip3 install $pkg) — needed for report generation"
  fi
done

# ---- NODE VERSION CHECK ----
section "Version Requirements"

NODE_MAJOR=$(node --version 2>/dev/null | grep -oE '^v([0-9]+)' | tr -d 'v' || echo "0")
if [ "$NODE_MAJOR" -ge 20 ]; then
  pass "Node.js ≥ 20 (v$NODE_MAJOR)"
else
  fail "Node.js must be ≥ 20 (current: v$NODE_MAJOR) — brew upgrade node"
fi

# ---- GITHUB AUTH ----
section "GitHub Authentication"

if gh auth status &>/dev/null 2>&1; then
  pass "GitHub CLI authenticated"
else
  fail "GitHub CLI not authenticated — run: gh auth login"
fi

# Check git credential helper
if git config --global credential.https://github.com.helper 2>/dev/null | grep -q "gh"; then
  pass "Git credential helper configured for GitHub (gh)"
elif git credential-manager 2>/dev/null | grep -q ""; then
  pass "Git credential manager detected"
else
  warn "Git credential helper not configured — run: gh auth setup-git"
fi

# Check ICCI org access
if gh repo view icci/icci-skills --json name -q '.name' &>/dev/null 2>&1; then
  pass "Access to icci org confirmed"
else
  fail "Cannot access icci/icci-skills — ask Aaron for org access"
fi

# ---- REPOSITORIES ----
section "ICCI Repositories"

check_repo() {
  local name="$1"
  local path="$2"
  local required="${3:-true}"

  if [ -d "$path/.git" ]; then
    # Check if up to date
    local behind
    behind=$(git -C "$path" rev-list HEAD..origin/main --count 2>/dev/null || echo "?")
    if [ "$behind" = "0" ]; then
      pass "$name (up to date)"
    elif [ "$behind" = "?" ]; then
      pass "$name (cloned, couldn't check remote)"
    else
      warn "$name ($behind commits behind — cd $path && git pull)"
    fi
  else
    if [ "$required" = "true" ]; then
      fail "$name — not cloned at $path"
    else
      warn "$name — not cloned (optional)"
    fi
  fi
}

check_repo "icci-skills" ~/Documents/GitHub/icci-skills "true"
check_repo "icci-report-branding" ~/Documents/GitHub/icci-report-branding "true"
check_repo "icci-workspace-mcp" ~/Documents/GitHub/icci-workspace-mcp "true"
check_repo "di-shepherd" ~/Documents/GitHub/di-shepherd "false"
check_repo "icci-HD-assistant" ~/Documents/GitHub/icci-HD-assistant "false"

# ---- SKILLS ----
section "ICCI Skills (Symlinks)"

EXPECTED_SKILLS=(
  di-shepherd
  icci-aws
  icci-gam-pfm
  icci-happyfox
  icci-HD-assistant
  icci-pbxact-maintenance
  icci-plesk-maintenance
  icci-skill-creator
  icci-workspace-security
  pigboats
)

for skill in "${EXPECTED_SKILLS[@]}"; do
  link=~/.claude/skills/$skill
  if [ -L "$link" ] && [ -f "$link/SKILL.md" ]; then
    pass "$skill"
  elif [ -L "$link" ]; then
    fail "$skill — symlink exists but SKILL.md missing (broken link?)"
  elif [ -d "$link" ]; then
    warn "$skill — exists as directory, not symlink (won't auto-update)"
  else
    fail "$skill — not installed (ln -s ~/Documents/GitHub/icci-skills/skills/$skill ~/.claude/skills/$skill)"
  fi
done

# ---- MCPs ----
section "MCP Servers"

if command -v icci-workspace-mcp &>/dev/null; then
  pass "icci-workspace-mcp CLI installed"
else
  fail "icci-workspace-mcp — not installed"
fi

if [ -f ~/.icci-mcp/tokens.json ]; then
  pass "Workspace MCP configured (tokens exist)"
else
  if command -v icci-workspace-mcp &>/dev/null; then
    warn "Workspace MCP installed but not configured — run: icci-workspace-mcp setup"
  fi
fi

if [ -f ~/.icci-mcp/config.json ]; then
  PROFILE=$(jq -r '.profile // "unknown"' ~/.icci-mcp/config.json 2>/dev/null || echo "unknown")
  SERVICES=$(jq -r '.services | length // 0' ~/.icci-mcp/config.json 2>/dev/null || echo "0")
  pass "Workspace MCP profile: $PROFILE ($SERVICES services)"
fi

# ---- DIRECTORIES ----
section "Standard Directories"

check_dir() {
  local path="$1"
  local display
  display="${path/$HOME/\~}"

  if [ -d "$path" ]; then
    pass "$display"
  else
    warn "$display — doesn't exist (mkdir -p $path)"
  fi
}

check_dir ~/.claude/skills
check_dir ~/Documents/GitHub
check_dir ~/Documents/claude-code

# ---- LEFTHOOK ----
section "Git Hooks (Lefthook)"

if [ -d ~/Documents/GitHub/icci-skills/.git ]; then
  if [ -f ~/Documents/GitHub/icci-skills/.git/hooks/pre-commit ] || [ -f ~/Documents/GitHub/icci-skills/.lefthook-local ]; then
    # Check if lefthook hooks are installed by looking for lefthook in hook files
    if grep -q "lefthook" ~/Documents/GitHub/icci-skills/.git/hooks/pre-commit 2>/dev/null; then
      pass "Lefthook hooks installed in icci-skills"
    else
      warn "Git hooks exist but may not be lefthook — run: cd ~/Documents/GitHub/icci-skills && lefthook install"
    fi
  else
    warn "Lefthook hooks not installed — run: cd ~/Documents/GitHub/icci-skills && lefthook install"
  fi
fi

# ---- CLAUDE CODE ----
section "Claude Code"

if command -v claude &>/dev/null; then
  CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "installed")
  pass "Claude Code ($CLAUDE_VERSION)"
else
  warn "Claude Code not installed — brew install claude-code"
fi

# ---- 1PASSWORD ----
section "1Password CLI + SSH Agent"

if command -v op &>/dev/null; then
  if op account list &>/dev/null 2>&1; then
    pass "1Password CLI connected (biometric unlock active)"
  else
    warn "1Password CLI installed but not connected — open 1Password → Settings → Developer → enable 'Integrate with 1Password CLI'"
  fi
else
  fail "1Password CLI — not installed (brew install 1password-cli)"
fi

# Check SSH agent
AGENT_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
if [ -S "$AGENT_SOCK" ]; then
  KEY_COUNT=$(SSH_AUTH_SOCK="$AGENT_SOCK" ssh-add -l 2>/dev/null | grep -c "SHA256" || echo "0")
  if [ "$KEY_COUNT" -gt 0 ]; then
    pass "1Password SSH agent serving $KEY_COUNT key(s)"
  else
    warn "1Password SSH agent running but serving 0 keys — check ~/.config/1Password/ssh/agent.toml"
  fi
else
  warn "1Password SSH agent socket not found — enable 'Use the SSH Agent' in 1Password → Settings → Developer"
fi

# Check agent.toml exists and has vault config
AGENT_TOML="$HOME/.config/1Password/ssh/agent.toml"
if [ -f "$AGENT_TOML" ]; then
  VAULT_COUNT=$(grep -c '^\[\[ssh-keys\]\]' "$AGENT_TOML" 2>/dev/null || echo "0")
  if [ "$VAULT_COUNT" -gt 0 ]; then
    pass "SSH agent config has $VAULT_COUNT vault(s) configured"
  else
    warn "agent.toml exists but no [[ssh-keys]] blocks — see SETUP.md Phase 2.5"
  fi
else
  warn "No agent.toml found at $AGENT_TOML — SSH agent won't serve keys from custom vaults"
fi

# ---- SUMMARY ----
echo ""
echo -e "${BOLD}════════════════════════════════════════${NC}"
echo -e "  ${GREEN}$PASS passed${NC}  ${RED}$FAIL failed${NC}  ${ORANGE}$WARN warnings${NC}"
echo -e "${BOLD}════════════════════════════════════════${NC}"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo -e "${RED}Setup has $FAIL issue(s) that need attention.${NC}"
  echo "Run the bootstrap script to fix: bash ~/Documents/GitHub/icci-skills/setup/icci-bootstrap.sh"
  exit 1
elif [ "$WARN" -gt 0 ]; then
  echo -e "${ORANGE}Setup is functional but has $WARN optional item(s) to address.${NC}"
  exit 0
else
  echo -e "${GREEN}Everything looks good!${NC}"
  exit 0
fi
