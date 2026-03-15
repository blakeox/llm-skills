# icci-plesk-maintenance — Usage Guide

## What This Skill Does

This skill gives Claude Code deep knowledge of ICCI's Plesk web hosting server, including:

- All 10 active WordPress sites (instance IDs, system users, PHP pools, domains)
- 35 Cloudflare zones with API access
- Server-level config: MariaDB, PHP-FPM (dual-service), Apache/Nginx, cron
- Proven troubleshooting procedures and lessons from real incidents
- Full audit checklist with ready-to-run commands

## Installation

### Option 1: Copy (recommended for most staff)

```bash
cp -r skills/icci-plesk-maintenance ~/.claude/skills/icci-plesk-maintenance
```

### Option 2: Symlink (for contributors who want changes to sync)

```bash
cd ~/Documents/GitHub/icci-skills
ln -s "$(pwd)/skills/icci-plesk-maintenance" ~/.claude/skills/icci-plesk-maintenance
```

### Verify Installation

Start Claude Code and type `/icci-plesk-maintenance`. If it autocompletes, the skill is installed.

## When It Triggers

The skill triggers automatically when you mention:

- Any hosted domain (beardedlamb.com, icci.com, tappanbands.org, etc.)
- "Plesk", "WordPress hosting", "PHP-FPM", "uploads error"
- Client support tickets about website issues
- Cloudflare zone configuration
- Server optimization or auditing tasks

You can also invoke it directly: `/icci-plesk-maintenance check beardedlamb.com uploads`

## Example Prompts

| What you say | What happens |
|--------------|--------------|
| "Tony can't upload images to beardedlamb.com" | Diagnoses uploads directory permissions, checks ownership, fixes if needed |
| "Run a full audit of the Plesk server" | Executes the audit checklist across all sites and server config |
| "Add a new WordPress site to the server" | Guides through Plesk subscription setup, wp-config constants, system cron, CF zone |
| "Check if HSTS is enabled on all Cloudflare zones" | Queries the CF API across all 35 zones |
| "catalog.formtechinc.com is slow" | Checks PHP-FPM pool config, MariaDB health, plugin list, DB size |
| "Update PHP to 8.4 on all sites" | Checks each site's handler, updates via Plesk CLI, verifies |

## What's in the Skill

```
icci-plesk-maintenance/
├── SKILL.md                         # Main skill (Claude reads this)
├── LICENSE.txt                      # ICCI proprietary license
├── USAGE.md                         # This file
└── references/
    ├── audit-checklist.md           # Full audit commands
    └── cloudflare-zones.md          # All 35 zone IDs
```

## Keeping It Updated

The skill improves over time as we encounter and solve new issues. The "Lessons Learned" section in SKILL.md is especially valuable — it captures real incidents so we don't repeat mistakes.

**After making changes in a session:**

1. Claude should update `~/.claude/skills/icci-plesk-maintenance/` (the live copy)
2. Copy to `~/Documents/GitHub/icci-skills/skills/icci-plesk-maintenance/` (the repo copy)
3. Commit and push with a descriptive message explaining what was learned

**The commit message should always detail what was added or learned**, for example:
- "Add lesson: monthly uploads dir ownership fix when using system cron"
- "Update site inventory: new25.beardedlamb.com promoted to production"
- "Add PHP 8.5 upgrade procedure to audit checklist"

## Prerequisites

- SSH access to 54.208.34.75 (key: `~/.ssh/icciVirgina2020.pem`)
- The SSH key must be configured in `~/.ssh/config` (already set up on Aaron's machine)
- Cloudflare API token is embedded in the skill (no separate config needed)

## Security Notes

- This skill contains server credentials and a Cloudflare API token
- The icci-skills repository is **PRIVATE** — never make it public
- Share with team members via direct repo access, never through public channels
- The CF API token has permissions across all 35 zones — handle with care
