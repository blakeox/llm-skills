# ICCI Skills

Skills for Claude Code used by the ICCI organization. Each skill is a self-contained folder of instructions, scripts, and resources that Claude loads dynamically to improve performance on specialized tasks.

> **This is a PRIVATE repository.** Some skills contain server credentials and API tokens. Never make this repository public.

## Repository Structure

```
icci-skills/
├── setup/                # Full workstation setup (bootstrap + verify scripts)
├── INSTALL.md            # Quick setup guide for skills only
├── version-check.sh      # Auto-update version checker
├── skills/               # Skill implementations
│   ├── di-shepherd/              # Deep Instinct endpoint security
│   ├── icci-aws/                 # AWS infrastructure management
│   ├── icci-gam-pfm/            # Google Workspace admin (GAM)
│   ├── icci-happyfox/            # HappyFox helpdesk (MCP)
│   ├── icci-HD-assistant/        # Helpdesk writing & communication filter
│   ├── icci-pbxact-maintenance/  # PBXact/FreePBX systems
│   ├── icci-plesk-maintenance/   # Plesk web hosting
│   ├── icci-skill-creator/       # Meta-skill for building new ICCI skills
│   ├── icci-workspace-security/  # Workspace security auditing
│   └── pigboats/                 # PigBoats.COM wiki ops
├── template/             # Skill template for creating new skills
└── spec/                 # Agent Skills specification
```

## New Workstation Setup

Setting up a new Mac from scratch? See **[setup/SETUP.md](setup/SETUP.md)** — it covers everything from Homebrew to MCPs, including the bootstrap script that automates most of it.

```bash
bash setup/icci-bootstrap.sh   # Install everything
bash setup/verify-setup.sh     # Verify it worked
```

## Skills-Only Installation

If you already have the prerequisites (Node.js, gh, etc.) and just need skills, see **[INSTALL.md](INSTALL.md)**.

```bash
git clone git@github.com:icci/icci-skills.git ~/Documents/GitHub/icci-skills
mkdir -p ~/.claude/skills
for skill in ~/Documents/GitHub/icci-skills/skills/*/; do
  ln -sf "$skill" ~/.claude/skills/"$(basename "$skill")"
done
```

Skills auto-detect when updates are available and prompt you to `git pull`.

## Available Skills

| Skill                                                      | Description                                                                                   |
| ---------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| [di-shepherd](skills/di-shepherd/)                         | Deep Instinct endpoint security — device compliance, threat remediation, audit reports        |
| [icci-aws](skills/icci-aws/)                               | AWS infrastructure — 12 PBXact systems, cost optimization, security reviews, fleet management |
| [icci-gam-pfm](skills/icci-gam-pfm/)                       | Google Workspace admin via GAM — 29 managed domains, user provisioning, bulk operations       |
| [icci-happyfox](skills/icci-happyfox/)                     | HappyFox helpdesk — ticket creation, search, contact management, reporting via MCP            |
| [icci-HD-assistant](skills/icci-HD-assistant/)             | Helpdesk writing filter — client responses, ticket docs, log analysis, communication polish   |
| [icci-pbxact-maintenance](skills/icci-pbxact-maintenance/) | PBXact/FreePBX — migrations, golden master builds, Yealink provisioning, trunk config         |
| [icci-plesk-maintenance](skills/icci-plesk-maintenance/)   | Plesk web hosting — 10 WordPress sites, 35 Cloudflare zones, PHP-FPM, SSL                     |
| [icci-skill-creator](skills/icci-skill-creator/)           | Meta-skill — create, validate, and improve ICCI skills with full standards enforcement        |
| [icci-workspace-security](skills/icci-workspace-security/) | Google Workspace security — login analysis, credential attacks, MFA audits, PDF reports       |
| [pigboats](skills/pigboats/)                               | Pigboats.com submarine history MediaWiki — server ops, upgrades, Cloudflare CDN               |

## Version System

Each skill has a `VERSION` file with a changelog. On first trigger in any conversation, the skill runs `version-check.sh` to compare your local checkout against `origin/main`. If you're behind, it tells you what changed and how to update.

```bash
# Manual check
~/Documents/GitHub/icci-skills/version-check.sh icci-happyfox
```

## Creating a New Skill

Use the **[icci-skill-creator](skills/icci-skill-creator/)** skill: `/icci-skill-creator build a skill for [your domain]`. It handles scaffolding, standards enforcement, security checks, branding integration, and cross-skill delegation automatically.

For manual creation, copy `template/SKILL.md` into a new folder under `skills/` and customize it. See the [Agent Skills standard](http://agentskills.io) for the full specification.
