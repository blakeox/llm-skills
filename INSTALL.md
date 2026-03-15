# ICCI Skills — Installation Guide

## Prerequisites

- **Claude Code** installed (`brew install claude-code` or via npm)
- **GitHub access** to the `icci` organization (ask Aaron if you need access)
- **SSH key** configured for GitHub (`ssh -T git@github.com` should greet you)
- **MCP connectors** enabled in Claude settings (per-skill — see skill-specific notes below)

## One-Time Setup

### 1. Clone the repo

```bash
git clone git@github.com:icci/icci-skills.git ~/Documents/GitHub/icci-skills
```

### 2. Create the skills directory

```bash
mkdir -p ~/.claude/skills
```

### 3. Symlink the skills you need

Pick the skills relevant to your role. Symlinks mean updates flow through automatically — no copying.

```bash
# HappyFox helpdesk (requires HappyFox MCP in Claude settings)
ln -s ~/Documents/GitHub/icci-skills/skills/icci-happyfox ~/.claude/skills/icci-happyfox

# Deep Instinct endpoint security
ln -s ~/Documents/GitHub/icci-skills/skills/di-shepherd ~/.claude/skills/di-shepherd

# Google Workspace admin (requires GAM installed)
ln -s ~/Documents/GitHub/icci-skills/skills/icci-gam-pfm ~/.claude/skills/icci-gam-pfm

# AWS infrastructure
ln -s ~/Documents/GitHub/icci-skills/skills/icci-aws ~/.claude/skills/icci-aws

# PBXact/FreePBX systems
ln -s ~/Documents/GitHub/icci-skills/skills/icci-pbxact-maintenance ~/.claude/skills/icci-pbxact-maintenance

# Plesk web hosting
ln -s ~/Documents/GitHub/icci-skills/skills/icci-plesk-maintenance ~/.claude/skills/icci-plesk-maintenance

# Google Workspace security auditing
ln -s ~/Documents/GitHub/icci-skills/skills/icci-workspace-security ~/.claude/skills/icci-workspace-security

# Helpdesk writing assistant
ln -s ~/Documents/GitHub/icci-skills/skills/icci-HD-assistant ~/.claude/skills/icci-HD-assistant

# Skill creation and validation meta-skill
ln -s ~/Documents/GitHub/icci-skills/skills/icci-skill-creator ~/.claude/skills/icci-skill-creator

# Pigboats.com wiki management
ln -s ~/Documents/GitHub/icci-skills/skills/pigboats ~/.claude/skills/pigboats
```

### 4. Verify

```bash
ls -la ~/.claude/skills/
```

You should see symlinks pointing to `~/Documents/GitHub/icci-skills/skills/...`

## Updating Skills

Skills are actively maintained. When Aaron and Claude refine a skill, updates are pushed to this repo. **Skills auto-detect when they're out of date** — on first use in a conversation, Claude checks the repo and warns you if updates are available.

When you see the update warning:

```bash
cd ~/Documents/GitHub/icci-skills && git pull
```

Then **start a new Claude Code conversation** to load the updated skill. Skills are read into context when a conversation begins — updating files on disk mid-conversation won't take effect until the next one.

### Optional: auto-update on terminal launch

Add this to your `~/.zshrc` to silently pull updates every time you open a terminal:

```bash
# Auto-update ICCI skills (silent, background)
(cd ~/Documents/GitHub/icci-skills 2>/dev/null && git pull --quiet &) 2>/dev/null
```

### Manual version check

```bash
# Check all skills
~/Documents/GitHub/icci-skills/version-check.sh

# Check a specific skill
~/Documents/GitHub/icci-skills/version-check.sh icci-happyfox
```

## How It Works

```
GitHub (icci/icci-skills)
        │
        │  git pull
        ▼
~/Documents/GitHub/icci-skills/skills/icci-happyfox/
        │
        │  symlink
        ▼
~/.claude/skills/icci-happyfox/  ◄── Claude Code reads from here
```

- You never edit files in `~/.claude/skills/` directly
- `git pull` is the only update mechanism
- Each skill has a `VERSION` file with a changelog
- On first trigger, the skill runs `version-check.sh` to detect staleness

## Skill-Specific Setup

### icci-happyfox

Requires the **HappyFox MCP connector** enabled in your Claude settings:

1. Go to Claude settings → MCP servers
2. Enable the HappyFox MCP
3. Grant write permissions when prompted

### icci-gam-pfm

Requires **GAMADV-XTD3** installed at `~/bin/gam7/gam` with a valid config at `~/.gam/gam.cfg`. See Aaron for OAuth token setup — tokens are domain-specific and cannot be shared.

### di-shepherd

Requires a **Deep Instinct API key**. Keys are role-scoped (read-only vs full-access). See Aaron for key provisioning.

## Troubleshooting

### "Not a git repository"

You copied the files instead of cloning. Remove and re-clone:

```bash
rm -rf ~/Documents/GitHub/icci-skills
git clone git@github.com:icci/icci-skills.git ~/Documents/GitHub/icci-skills
```

Then re-create your symlinks (step 3 above).

### Symlink is broken (red in `ls -la`)

The repo directory moved or was deleted. Re-clone and re-link.

### Skill not triggering in Claude Code

- Verify the symlink exists: `ls -la ~/.claude/skills/icci-happyfox`
- Verify SKILL.md is readable: `cat ~/.claude/skills/icci-happyfox/SKILL.md | head -5`
- Start a new conversation — skills load at conversation start

### "Could not reach GitHub" during version check

You're offline or GitHub SSH isn't configured. The skill still works — it just can't check for updates. Fix SSH access when you're back online.

### Permission denied on version-check.sh

```bash
chmod +x ~/Documents/GitHub/icci-skills/version-check.sh
```

## For Skill Developers (Aaron + Claude)

- **Edit in the repo** (`~/Documents/GitHub/icci-skills/skills/...`), not in `~/.claude/skills/`
- **Bump VERSION** after meaningful changes so staff see the update prompt
- **Commit and push** — staff only see what's on `origin/main`
- The local `~/.claude/skills/` copy auto-updates via symlink — no extra sync step needed
- If you have local (non-symlinked) copies in `~/.claude/skills/`, those are YOUR working copies and won't auto-update. The symlink pattern is for distribution to staff.
