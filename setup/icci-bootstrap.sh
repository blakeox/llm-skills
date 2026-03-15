#!/bin/bash
# ============================================================================
# Script Name  : icci-bootstrap.sh
# Author       : ICCI, LLC (Aaron Salsitz)
# Organization : ICCI, LLC — Secure. Governed. Operational.
# Title        : ICCI Workstation Bootstrap
# Created      : 13MAR26
# Version      : 1.1.0
# Description  : Sets up a new Mac with all ICCI tools, skills, and MCPs.
#                Safe to re-run — skips anything already installed.
# Usage        : bash icci-bootstrap.sh
# Notes        : Requires macOS with internet access. Does NOT install
#                credentials — those are handled per-user after bootstrap.
# License      : CC BY 4.0 — https://creativecommons.org/licenses/by/4.0/
# Changes      :
#   1.1.0 — 14MAR26 — Fix: add missing warn() function (#3), fix pip3
#                      PEP 668 --break-system-packages (#4), add Claude
#                      Code install phase (#5)
#   1.0.0 — 13MAR26 — Initial version
# ============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
ORANGE='\033[0;33m'
# shellcheck disable=SC2034
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

error() { echo -e "${RED}ERROR: $*${NC}" >&2; }
warn() { echo -e "${ORANGE}WARN: $*${NC}"; }
progress() { echo -e "${ORANGE}>>> $*${NC}"; }
info() { echo -e "${BLUE}    $*${NC}"; }
header() { echo -e "\n${BOLD}═══ $* ═══${NC}\n"; }
success() { echo -e "${GREEN}✓${NC} $*"; }

FAILED=0

# ---- PHASE 1: HOMEBREW ----
header "Phase 1: Homebrew"

if command -v brew &>/dev/null; then
  success "Homebrew already installed ($(brew --version | head -1))"
else
  progress "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add to PATH for this session
  if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

# ---- PHASE 2: BREW FORMULAE ----
header "Phase 2: Core Tools (Homebrew)"

BREW_PACKAGES=(
  git
  gh
  node
  "python@3.13"
  awscli
  tree
  ripgrep
  wget
  jq
  yq
  fd
  bat
  grep
  shellcheck
  shfmt
  weasyprint
  lefthook
  openssh
  1password-cli
  git-delta
)

MISSING_BREW=()
for pkg in "${BREW_PACKAGES[@]}"; do
  # Check if installed (handle versioned packages like python@3.13)
  base_pkg="${pkg%%@*}"
  if brew list "$pkg" &>/dev/null || brew list "$base_pkg" &>/dev/null; then
    success "$pkg"
  else
    MISSING_BREW+=("$pkg")
  fi
done

if [ ${#MISSING_BREW[@]} -gt 0 ]; then
  progress "Installing ${#MISSING_BREW[@]} missing packages: ${MISSING_BREW[*]}"
  brew install "${MISSING_BREW[@]}"
else
  info "All brew packages already installed"
fi

# ---- PHASE 3: NPM GLOBAL PACKAGES ----
header "Phase 3: npm Global Packages"

NPM_PACKAGES=(prettier)

for pkg in "${NPM_PACKAGES[@]}"; do
  if npm list -g "$pkg" &>/dev/null; then
    success "$pkg"
  else
    progress "Installing $pkg..."
    npm install -g "$pkg"
  fi
done

# ---- PHASE 4: PYTHON PACKAGES ----
header "Phase 4: Python Packages"

PIP_PACKAGES=(jinja2 pyyaml click)

for pkg in "${PIP_PACKAGES[@]}"; do
  if pip3 show "$pkg" &>/dev/null 2>&1; then
    success "$pkg"
  else
    progress "Installing $pkg..."
    pip3 install --break-system-packages "$pkg"
  fi
done

# ---- PHASE 5: GITHUB AUTHENTICATION ----
header "Phase 5: GitHub Authentication"

if gh auth status &>/dev/null 2>&1; then
  GH_USER=$(gh auth status 2>&1 | grep "Logged in" | head -1 || echo "authenticated")
  success "GitHub CLI authenticated ($GH_USER)"
else
  echo ""
  echo -e "${BOLD}GitHub authentication is required to access ICCI's private repos.${NC}"
  echo "This will open a browser for you to log in."
  echo ""
  read -rp "Press Enter to start GitHub login (or Ctrl+C to skip)..."
  gh auth login --web --git-protocol https
fi

# Configure git to use gh for HTTPS auth (critical for npm installs from private repos)
progress "Configuring git credential helper for GitHub..."
gh auth setup-git 2>/dev/null || true
success "Git credential helper configured"

# Verify access to ICCI org
if gh repo view icci/icci-skills --json name -q '.name' &>/dev/null; then
  success "Access to icci/icci-skills confirmed"
else
  error "Cannot access icci/icci-skills — ask Aaron for org access"
  FAILED=$((FAILED + 1))
fi

# ---- 1PASSWORD CLI ----
header "1Password CLI"

if command -v op &>/dev/null; then
  if op account list &>/dev/null 2>&1; then
    success "1Password CLI connected (biometric unlock active)"
  else
    info "1Password CLI installed but not connected to desktop app"
    info "Open 1Password → Settings → Developer → enable 'Integrate with 1Password CLI'"
  fi
else
  warn "1Password CLI installed via brew but 'op' not found — restart your terminal"
fi

# ---- PHASE 6: CLAUDE CODE ----
header "Phase 6: Claude Code"

if command -v claude &>/dev/null; then
  CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "installed")
  success "Claude Code already installed ($CLAUDE_VERSION)"
else
  progress "Installing Claude Code..."
  brew install claude-code
  if command -v claude &>/dev/null; then
    success "Claude Code installed"
  else
    error "Claude Code install failed — try: npm install -g @anthropic-ai/claude-code"
    FAILED=$((FAILED + 1))
  fi
fi
info "Run 'claude' after setup to authenticate with your Anthropic account"

# ---- PHASE 7: CLONE REPOS ----
header "Phase 7: ICCI Repositories"

mkdir -p ~/Documents/GitHub

REPOS=(
  "icci/icci-skills"
  "icci/icci-report-branding"
  "icci/icci-workspace-mcp"
)

for repo in "${REPOS[@]}"; do
  dir_name="${repo#*/}"
  target=~/Documents/GitHub/$dir_name

  if [ -d "$target/.git" ]; then
    success "$dir_name (already cloned)"
    # Pull latest
    git -C "$target" pull --quiet 2>/dev/null || true
  else
    progress "Cloning $repo..."
    if git clone "https://github.com/$repo.git" "$target" 2>/dev/null; then
      success "$dir_name"
    else
      error "Failed to clone $repo — check GitHub access"
      FAILED=$((FAILED + 1))
    fi
  fi
done

# ---- PHASE 8: INSTALL SKILLS ----
header "Phase 8: ICCI Skills"

mkdir -p ~/.claude/skills

if [ -d ~/Documents/GitHub/icci-skills/skills ]; then
  for skill in ~/Documents/GitHub/icci-skills/skills/*/; do
    skill_name=$(basename "$skill")
    target=~/.claude/skills/$skill_name

    if [ -L "$target" ]; then
      success "$skill_name (symlink exists)"
    else
      ln -sf "$skill" "$target"
      success "$skill_name (linked)"
    fi
  done

  # Install lefthook in skills repo
  if command -v lefthook &>/dev/null; then
    (cd ~/Documents/GitHub/icci-skills && lefthook install 2>/dev/null) || true
    success "Lefthook hooks installed"
  fi
else
  error "icci-skills repo not found — skills not installed"
  FAILED=$((FAILED + 1))
fi

# ---- PHASE 9: INSTALL WORKSPACE MCP ----
header "Phase 9: ICCI Workspace MCP"

if command -v icci-workspace-mcp &>/dev/null; then
  success "icci-workspace-mcp already installed"
else
  MCP_DIR=~/Documents/GitHub/icci-workspace-mcp

  if [ -f "$MCP_DIR/package.json" ]; then
    progress "Installing icci-workspace-mcp from local clone..."
    (cd "$MCP_DIR" && npm install && npm run build && npm install -g .) 2>&1 | tail -3

    if command -v icci-workspace-mcp &>/dev/null; then
      success "icci-workspace-mcp installed"
    else
      error "icci-workspace-mcp install failed"
      FAILED=$((FAILED + 1))
    fi
  else
    # Try direct install from GitHub
    progress "Installing icci-workspace-mcp from GitHub..."
    if npm install -g "git+https://github.com/icci/icci-workspace-mcp.git" 2>/dev/null; then
      success "icci-workspace-mcp installed"
    else
      error "npm install from GitHub failed — trying local clone method..."
      if [ -d "$MCP_DIR" ]; then
        (cd "$MCP_DIR" && npm install && npm run build && npm install -g .) 2>&1 | tail -3
        if command -v icci-workspace-mcp &>/dev/null; then
          success "icci-workspace-mcp installed (from local clone)"
        else
          error "icci-workspace-mcp install failed both ways"
          FAILED=$((FAILED + 1))
        fi
      fi
    fi
  fi
fi

# Check if MCP needs setup
if [ -f ~/.icci-mcp/tokens.json ]; then
  success "Workspace MCP already configured (tokens exist)"
else
  echo ""
  echo -e "${BOLD}The Workspace MCP needs OAuth setup.${NC}"
  echo "This opens a browser for Google Workspace login."
  echo ""
  read -rp "Run setup now? (y/N): " run_setup
  if [[ "$run_setup" =~ ^[Yy] ]]; then
    icci-workspace-mcp setup
  else
    info "Skipped — run 'icci-workspace-mcp setup' later"
  fi
fi

# ---- PHASE 10: STANDARD DIRECTORIES ----
header "Phase 10: Standard Directories"

DIRS=(
  ~/Documents/claude-code
  ~/Documents/claude-code/aws
)

for dir in "${DIRS[@]}"; do
  mkdir -p "$dir"
  success "${dir/$HOME/\~}"
done

# ---- SUMMARY ----
header "Setup Complete"

if [ "$FAILED" -gt 0 ]; then
  echo -e "${RED}$FAILED step(s) had errors. Review the output above.${NC}"
  echo ""
  echo "Common fixes:"
  echo "  - GitHub access: Ask Aaron to add you to the icci org"
  echo "  - npm auth: Run 'gh auth setup-git' then retry"
  echo "  - Permissions: Run 'sudo chown -R \$(whoami) \$(npm config get prefix)/{lib/node_modules,bin,share}'"
else
  echo -e "${GREEN}All steps completed successfully!${NC}"
fi

echo ""
echo "Next steps:"
echo "  1. Run 'claude' to launch Claude Code (authenticate if first time)"
echo "  2. Run 'icci-workspace-mcp setup' if you skipped it above"
echo "  3. Ask Aaron for any role-specific credentials (API keys, SSH keys)"
echo "  4. Run 'bash ~/Documents/GitHub/icci-skills/setup/verify-setup.sh' to verify"
echo ""
echo "ICCI, LLC — Secure. Governed. Operational."
