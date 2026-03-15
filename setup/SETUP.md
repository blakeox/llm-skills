# ICCI Workstation Setup Guide

Complete setup guide for a new ICCI technical workstation. This gets a Mac from zero to fully operational with all ICCI skills, MCPs, and tools.

**Audience:** New ICCI technical staff (or rebuilding a Mac from scratch).
**Time:** ~30 minutes with good internet.
**Tested on:** macOS Sequoia (Apple Silicon). Intel Macs should work but are untested.

> **TL;DR** — If you just want to run the bootstrap script:
>
> ```bash
> /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/icci/icci-skills/main/setup/icci-bootstrap.sh)"
> ```
>
> But read this doc first so you understand what it does.

---

## Phase 1: Foundation (Homebrew + Core Tools)

### 1.1 Install Homebrew

If you don't have Homebrew yet:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After installation, follow the instructions it prints to add Homebrew to your PATH. For Apple Silicon Macs, this is usually:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

**Verify:** `brew --version` should return a version number.

### 1.2 Install Core Brew Formulae

```bash
brew install \
  git \
  gh \
  node \
  python@3.13 \
  awscli \
  tree \
  ripgrep \
  wget \
  jq \
  yq \
  fd \
  bat \
  grep \
  shellcheck \
  shfmt \
  weasyprint \
  lefthook \
  openssh \
  1password-cli \
  git-delta
```

**What each one does:**

| Package         | Purpose                                                     | Used By                                        |
| --------------- | ----------------------------------------------------------- | ---------------------------------------------- |
| `git`           | Version control                                             | Everything                                     |
| `gh`            | GitHub CLI — **critical for private repo access**           | Skills, MCPs, repo management                  |
| `node`          | JavaScript runtime (includes npm)                           | icci-workspace-mcp, Claude Code                |
| `python@3.13`   | Python runtime                                              | Report generation, scripts                     |
| `awscli`        | AWS CLI                                                     | icci-aws skill                                 |
| `tree`          | Directory visualization                                     | General                                        |
| `ripgrep`       | Fast search                                                 | Claude Code, general                           |
| `wget`          | HTTP downloads                                              | Scripts                                        |
| `jq`            | JSON processor                                              | Scripts, API work                              |
| `yq`            | YAML processor                                              | Skill frontmatter parsing                      |
| `fd`            | Fast file finder                                            | General                                        |
| `bat`           | Syntax-highlighted file viewer                              | General                                        |
| `grep`          | GNU grep (macOS default lacks `-P`)                         | validate-skill.sh                              |
| `shellcheck`    | Bash linter                                                 | Script quality                                 |
| `shfmt`         | Shell formatter                                             | Script formatting                              |
| `weasyprint`    | PDF generation from HTML                                    | All ICCI report generation                     |
| `lefthook`      | Git hooks framework                                         | Pre-commit formatting, pre-push privacy checks |
| `openssh`       | SSH client                                                  | Server access                                  |
| `1password-cli` | 1Password CLI (`op`) — secrets, SSH agent, biometric unlock | Credential management, SSH keys                |
| `git-delta`     | Beautiful side-by-side git diffs with syntax highlighting   | Git (configured as pager in .gitconfig)        |

### 1.3 Install Global npm Packages

```bash
npm install -g prettier
```

| Package    | Purpose                                            |
| ---------- | -------------------------------------------------- |
| `prettier` | Markdown/JSON formatter (lefthook pre-commit hook) |

### 1.4 Install Python Packages

WeasyPrint installs its own Python environment via Homebrew. For report generation scripts that use the branding library:

```bash
pip3 install jinja2 pyyaml click
```

---

## Phase 2: GitHub Authentication

**This is where most setup failures happen.** Without GitHub auth, nothing that touches ICCI's private repos will work — not skill updates, not MCP installs, not repo clones.

### 2.1 Authenticate with GitHub CLI

```bash
gh auth login
```

Follow the prompts:

- **Where do you use GitHub?** → `GitHub.com`
- **Preferred protocol?** → `HTTPS` (simplest for new users)
- **Authenticate Git with your GitHub credentials?** → `Yes` ← **CRITICAL**
- **How would you like to authenticate?** → `Login with a web browser`

The "Authenticate Git" step runs `gh auth setup-git` internally, which configures git's credential helper to use `gh` for HTTPS auth. **Without this, `npm install` from private GitHub repos will fail.**

### 2.2 Verify GitHub Access

```bash
# Should show your GitHub username
gh auth status

# Should show your org membership
gh org list

# Should succeed (private repo)
gh repo view icci/icci-skills --json name -q '.name'
```

If the last command returns `icci-skills`, you're good. If it errors, ask Aaron for org access.

### 2.3 Configure Git Identity

```bash
git config --global user.name "Your Name"
git config --global user.email "your-email@icci.com"
```

### 2.4 (Optional) SSH Key for GitHub

If you prefer SSH over HTTPS for git operations:

```bash
# Generate a key
ssh-keygen -t ed25519 -C "your-email@icci.com"

# Add to GitHub
gh ssh-key add ~/.ssh/id_ed25519.pub --title "ICCI Workstation"
```

Most ICCI staff use 1Password SSH agent instead — see Phase 2.5 below.

### 2.5 1Password CLI + SSH Agent

The 1Password CLI (`op`) retrieves secrets from 1Password vaults without exposing them in plaintext. The SSH agent lets 1Password serve SSH keys directly — no `.pem` files on disk.

**Prerequisites:** 1Password 8 desktop app must be installed and signed in first.

**Step 1 — Enable CLI integration and SSH agent:**

1. Open 1Password desktop app
2. Go to **Settings → Developer**
3. Enable **"Show 1Password Developer experience"**
4. Enable **"Integrate with 1Password CLI"**
5. Enable **"Use the SSH Agent"**

**Step 2 — Configure which vaults the SSH agent serves keys from:**

Edit (or create) `~/.config/1Password/ssh/agent.toml`:

```toml
# Each vault needs its own [[ssh-keys]] block.
# IMPORTANT: Do NOT put multiple vault= lines in one block —
# TOML silently drops all but the last, and the agent serves 0 keys.

[[ssh-keys]]
vault = "SSH Keys"

[[ssh-keys]]
vault = "Employee"
```

After editing, lock and unlock 1Password (Cmd+L, then Touch ID) for changes to take effect.

**Step 3 — Configure SSH to use the 1Password agent:**

Add to `~/.ssh/config`:

```
Host *
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
```

With this in place, you do NOT need `IdentityFile` lines pointing to key files on disk — 1Password serves them.

**Step 4 — Add zsh completions** (add to `~/.zshrc`):

```bash
# 1Password CLI
eval "$(op completion zsh)"
compdef _op op
source ~/.config/op/plugins.sh 2>/dev/null
```

**Verify everything works:**

```bash
# Should prompt Touch ID, then list your accounts
op account list

# Should list SSH key fingerprints from 1Password
ssh-add -l

# Should authenticate via 1Password (if GitHub key is imported)
ssh -T git@github.com
```

If `ssh-add -l` returns "The agent has no identities", check:

1. The `agent.toml` vault names match exactly (case-sensitive)
2. Each vault has its own `[[ssh-keys]]` block (no duplicate `vault=` in one block)
3. Lock and unlock 1Password after any config change

**Importing SSH keys into 1Password:**

The `op` CLI **cannot** import existing SSH keys (known limitation since 2022). Use one of:

- **Desktop app** (easiest): New Item → SSH Key → Add Private Key → drag in the `.pem` file
- **Python SDK** (bulk import): `pip install onepassword-sdk`, requires a Service Account token — ask Aaron for the script

---

## Phase 3: Clone ICCI Repositories

### 3.1 Create Standard Directory

```bash
mkdir -p ~/Documents/GitHub
```

### 3.2 Clone Core Repos

```bash
cd ~/Documents/GitHub

# Skills monorepo (required)
git clone https://github.com/icci/icci-skills.git

# Report branding (required for any skill that generates reports)
git clone https://github.com/icci/icci-report-branding.git

# Workspace MCP (required for Google Workspace integration)
git clone https://github.com/icci/icci-workspace-mcp.git
```

> **If clone fails with "authentication" errors:** Go back to Phase 2. Run `gh auth setup-git` and try again. This is the #1 cause of setup failures.

### 3.3 (Optional) Clone Additional Repos

These are only needed if you work on specific projects:

```bash
# Deep Instinct endpoint security
git clone https://github.com/icci/di-shepherd.git

# HappyFox helpdesk bridge
git clone https://github.com/icci/happy-fox-mcp.git

# Helpdesk writing assistant
git clone https://github.com/icci/icci-HD-assistant.git
```

---

## Phase 4: Install Claude Code

### 4.1 Install Claude Code CLI

```bash
brew install claude-code
```

Or via npm:

```bash
npm install -g @anthropic-ai/claude-code
```

### 4.2 First Launch

```bash
claude
```

Follow the prompts to authenticate with your Anthropic account. Ask Aaron for the ICCI team account if needed.

---

## Phase 5: Install ICCI Skills

### 5.1 Create Skills Directory and Symlinks

```bash
mkdir -p ~/.claude/skills

# Core skills (install all — they only load when triggered)
for skill in ~/Documents/GitHub/icci-skills/skills/*/; do
  skill_name=$(basename "$skill")
  ln -sf "$skill" ~/.claude/skills/"$skill_name"
done
```

### 5.2 Verify Skills

```bash
ls -la ~/.claude/skills/
```

You should see symlinks pointing to `~/Documents/GitHub/icci-skills/skills/...` for each skill.

### 5.3 Set Up Lefthook (Git Hooks)

```bash
cd ~/Documents/GitHub/icci-skills
lefthook install
```

This enables:

- **Pre-commit:** Prettier formats all staged `.md` and `.json` files
- **Pre-push:** Verifies the repo is still private before pushing

---

## Phase 6: Install MCPs (Model Context Protocol Servers)

### 6.1 ICCI Workspace MCP (Google Workspace)

This is the one that trips people up. The key insight: **you must have GitHub auth working first** (Phase 2).

**Option A — Install from GitHub directly (preferred):**

```bash
npm install -g git+https://github.com/icci/icci-workspace-mcp.git
```

**Option B — Install from local clone (if Option A fails):**

```bash
cd ~/Documents/GitHub/icci-workspace-mcp
npm install
npm run build
npm install -g .
```

**Then run setup:**

```bash
icci-workspace-mcp setup
```

Follow the prompts:

1. Choose profile: `standard` (recommended for most staff)
2. Choose services: accept defaults (9 services)
3. Browser opens → log in with your Google Workspace account
4. Grant permissions on the consent screen
5. Done — tokens are encrypted and stored in `~/.icci-mcp/`

**Register with Claude Code:**

```bash
claude mcp add icci-workspace -- icci-workspace-mcp
```

**Verify:**

```bash
icci-workspace-mcp   # Should start without errors (Ctrl+C to stop)
```

> **Troubleshooting:** If `npm install -g git+https://...` fails:
>
> - Run `gh auth status` — if not authenticated, go back to Phase 2
> - Run `gh auth setup-git` — this configures git's credential helper
> - Try again
> - If it STILL fails, use Option B (install from local clone)

### 6.2 HappyFox MCP

The HappyFox MCP is a remote server — no local installation needed. It just needs to be registered in Claude.

Ask Aaron for the current MCP endpoint URL and authentication details, then register:

```bash
claude mcp add happyfox --transport sse <endpoint-url>
```

Or add manually to Claude settings if using Claude Desktop.

### 6.3 Cloudflare MCP

If you need Cloudflare management tools:

```bash
claude mcp add cloudflare -- npx @anthropic-ai/mcp-remote https://mcp.cloudflare.com/sse
```

You'll be prompted to authenticate with Cloudflare on first use.

### 6.4 (Optional) Disable Conflicting Built-in Integrations

If you enabled Claude's built-in Google integrations (Gmail, Calendar, Drive), they'll conflict with the ICCI workspace MCP. Disable them:

- **Claude Desktop:** Settings → Integrations → toggle off Google services
- **Claude Code:** Check `~/.claude/settings.json` for duplicate MCP entries

---

## Phase 7: Create Standard Directories

```bash
# Report output directory (all skills write here)
mkdir -p ~/Documents/claude-code

# AWS audit logs
mkdir -p ~/Documents/claude-code/aws

# These get created automatically by skills, but having them ready doesn't hurt
```

---

## Phase 8: Verify Everything

Run the verification script:

```bash
bash ~/Documents/GitHub/icci-skills/setup/verify-setup.sh
```

Or check manually:

```bash
# Homebrew
brew --version

# GitHub CLI (authenticated)
gh auth status

# Node.js (≥20)
node --version

# Python (≥3.12)
python3 --version

# AWS CLI
aws --version

# Skills installed
ls ~/.claude/skills/

# Workspace MCP
which icci-workspace-mcp

# Lefthook
cd ~/Documents/GitHub/icci-skills && lefthook run pre-commit --force

# Version check
bash ~/Documents/GitHub/icci-skills/version-check.sh
```

---

## Phase 9: Optional Tools (Role-Specific)

### For Google Workspace Administrators

GAM (Google Admin Manager) is required for the `icci-gam-pfm` skill:

```bash
# GAM is installed separately — see Aaron for setup
# It lives at ~/bin/gam7/gam with config at ~/.gam/gam.cfg
# OAuth tokens are domain-specific and cannot be shared
```

### For PBXact/VoIP Engineers

```bash
brew install sshpass   # Automated SSH (used by some migration scripts)
```

### For Server Administrators

```bash
brew install rsync telnet tmux screen
```

---

## Common Setup Problems

### "npm install from GitHub fails"

**Cause:** Git can't authenticate with GitHub to clone the private repo.

**Fix:**

```bash
gh auth login          # Authenticate with GitHub
gh auth setup-git      # Configure git to use gh for HTTPS auth
```

Then retry the npm install. If it still fails, clone manually and install from the local directory.

### "Permission denied" during npm global install

**Cause:** npm's global directory has wrong ownership (common after using `sudo npm` once).

**Fix:**

```bash
sudo chown -R $(whoami) $(npm config get prefix)/{lib/node_modules,bin,share}
```

Or better — use Homebrew's node which puts globals in `/opt/homebrew/` (user-writable).

### "icci-workspace-mcp setup" opens browser but nothing happens

**Cause:** The OAuth callback server on localhost:3847 didn't start, or the browser didn't redirect.

**Fix:** Make sure no other process is using port 3847:

```bash
lsof -i :3847
```

If something is blocking it, kill that process and retry setup.

### "Token decryption failed" after new machine / username change

**Cause:** Tokens are encrypted with a machine-specific key (hostname + username).

**Fix:** Delete the old tokens and re-run setup:

```bash
rm ~/.icci-mcp/tokens.json
icci-workspace-mcp setup
```

### Skills not triggering in Claude Code

**Cause:** Skills load at conversation start. Changes mid-conversation don't take effect.

**Fix:** Start a new Claude Code conversation after installing/updating skills.

### "CRITICAL: repo is NOT private" when pushing

**Cause:** The lefthook pre-push hook detected the repo is public (or `gh` isn't authenticated).

**Fix:** Run `gh auth status` and make sure you're authenticated. If the repo really is public, STOP and tell Aaron immediately.

---

## What Each Skill Needs

| Skill                   | Brew               | npm      | MCP          | Credentials          | Notes                         |
| ----------------------- | ------------------ | -------- | ------------ | -------------------- | ----------------------------- |
| icci-happyfox           | —                  | —        | HappyFox MCP | —                    | MCP handles auth              |
| di-shepherd             | —                  | —        | —            | DI API key (session) | Key provided at session start |
| icci-gam-pfm            | —                  | —        | —            | GAM OAuth tokens     | See Aaron for GAM setup       |
| icci-aws                | awscli             | —        | —            | AWS credentials      | `aws configure`               |
| icci-pbxact-maintenance | sshpass (optional) | —        | —            | SSH keys             | Per-client PBX access         |
| icci-plesk-maintenance  | —                  | —        | —            | SSH key              | Plesk server access           |
| pigboats                | —                  | —        | —            | SSH key              | Same server as Plesk          |
| icci-workspace-security | —                  | —        | —            | GAM OAuth tokens     | Uses GAM for data collection  |
| icci-HD-assistant       | —                  | —        | —            | —                    | No external deps              |
| icci-skill-creator      | shellcheck, shfmt  | prettier | —            | —                    | Dev tools for validation      |

---

## Keeping Everything Updated

### Skills Auto-Update Check

Skills check for updates on first trigger each conversation. When you see the update warning:

```bash
cd ~/Documents/GitHub/icci-skills && git pull
```

Then start a new Claude Code conversation.

### Optional: Auto-Pull on Terminal Launch

Add to `~/.zshrc`:

```bash
# Auto-update ICCI skills (silent, background)
(cd ~/Documents/GitHub/icci-skills 2>/dev/null && git pull --quiet &) 2>/dev/null
```

### Updating MCPs

```bash
# Workspace MCP
npm install -g git+https://github.com/icci/icci-workspace-mcp.git

# No re-auth needed — tokens carry over
```

### Updating Brew Packages

```bash
brew update && brew upgrade
```
