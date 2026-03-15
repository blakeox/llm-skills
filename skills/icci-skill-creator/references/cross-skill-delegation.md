# Cross-Skill Delegation Protocol

Skills and MCPs in the ICCI ecosystem must be aware of each other. The goal is intelligent delegation — not duplication. A skill should never re-engineer functionality that another skill already provides.

## The Problem

Without awareness, each skill becomes an island:

- The HappyFox skill might try to format DI-Shepherd report data instead of delegating to di-shepherd
- A new skill might call HappyFox MCP tools directly, bypassing the icci-happyfox safety protocol
- Multiple skills might independently implement ICCI branding instead of using the branding repo

## The Discovery Protocol

Every ICCI skill should include this section in its SKILL.md:

```markdown
## Cross-Skill Delegation

### Sibling Skills

On first trigger, scan `~/.claude/skills/*/SKILL.md` frontmatter to discover available skills.

### MCP Tools

Check the conversation context for available MCP tools. Never call MCP tools directly if a wrapper skill exists.

### Delegation Rules

- [Skill-specific delegation rules]
- For HappyFox ticket operations → delegate to `icci-happyfox` (never call MCP directly)
- For DI endpoint data → delegate to `di-shepherd`
- For Google Workspace admin → delegate to `icci-gam-pfm`
- For formatted output → use `~/Documents/GitHub/icci-report-branding/`
```

## Current ICCI Ecosystem Map

### Skills (as of March 2026)

| Skill                     | Domain              | Owns                                                                                                                |
| ------------------------- | ------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `icci-happyfox`           | Helpdesk ticketing  | Ticket CRUD, contact management, canned actions. **Wraps HappyFox MCP — always use this instead of raw MCP calls.** |
| `di-shepherd`             | Endpoint security   | Device compliance, threat events, remediation, DI API. Provides data that other skills consume.                     |
| `icci-gam-pfm`            | Google Workspace    | User provisioning, group management, Classroom, Drive, Gmail, Calendar, MFA, reporting across 29 domains.           |
| `icci-aws`                | AWS infrastructure  | EC2 fleet, S3, EBS, EIPs, cost monitoring, security review for 12 PBXact systems.                                   |
| `icci-pbxact-maintenance` | Telecom/VoIP        | PBXact/FreePBX config, migration, Telnyx trunks, Yealink provisioning, call recording.                              |
| `icci-plesk-maintenance`  | Web hosting         | 10 WordPress sites, Cloudflare zones, PHP-FPM, Apache, MariaDB, SSL.                                                |
| `pigboats`                | MediaWiki ops       | pigboats.com: MW upgrades, extensions, Cloudflare CDN, Plesk backups.                                               |
| `icci-HD-assistant`       | Writing filter      | Client communication polish. Delegates research to domain skills, handles writing only.                             |
| `icci-workspace-security` | Security auditing   | Login analysis, credential attacks, MFA audits, forensics, PDF reports.                                             |
| `icci-skill-creator`      | Meta/skill building | Skill creation, improvement, validation, standards enforcement.                                                     |

### MCPs

| MCP                                      | Domain                        | Routing Rule                                                                                                                                                |
| ---------------------------------------- | ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| HappyFox MCP (`happyfox_*`)              | Helpdesk                      | **ALWAYS route through `icci-happyfox` skill.** The skill wraps MCP with tech identity injection, cache validation, HTML formatting, known bug workarounds. |
| ICCI Workspace MCP (`icci-workspace__*`) | Google Workspace (user-level) | For Gmail, Drive, Calendar, Contacts, Tasks. Use directly for user-level operations. For admin operations → use `icci-gam-pfm` instead.                     |
| Cloudflare MCP (`Cloudflare_*`)          | DNS, Workers, KV, R2, D1      | Use directly for Cloudflare operations. Zone IDs are documented in skill references.                                                                        |

## Delegation Patterns

### Pattern 1: Data Producer → Consumer

DI-Shepherd produces a fleet health report. The user wants it attached to a HappyFox ticket.

```
User: "Generate a DI fleet health report and create a ticket for it"

Step 1: Delegate to di-shepherd for the report
        → di-shepherd generates PDF at ~/Documents/claude-code/di-shepherd/reports/
Step 2: Delegate to icci-happyfox to create the ticket
        → icci-happyfox creates ticket with ICCI-branded HTML description
        → References the PDF location or summarizes findings
```

The key insight: the skill handling the user's request orchestrates — it doesn't do everything itself.

### Pattern 2: MCP Wrapper

The user asks to search HappyFox tickets.

```
WRONG: Call happyfox_ticket_search MCP tool directly
RIGHT: Invoke icci-happyfox skill → skill calls MCP with proper protocol
```

Why: The skill injects tech identity, validates cache, applies HTML formatting, works around known bugs (BUG-001 through BUG-009), and enforces destructive operation safety.

### Pattern 3: Research → Writing

The user asks to draft a client response about a security incident.

```
Step 1: icci-workspace-security gathers the forensic data
Step 2: di-shepherd checks for related endpoint events
Step 3: icci-HD-assistant drafts the client-facing response
```

HD-Assistant owns the writing domain. It doesn't independently research — it consumes data from domain experts.

### Pattern 4: Branding Integration

Any skill that produces formatted output (PDF, HTML, email):

```
Before generating output:
1. Read ~/Documents/GitHub/icci-report-branding/brand/identity.md
2. Use brand colors, fonts, logo paths from the branding repo
3. Use WeasyPrint for PDFs (never reportlab, wkhtmltopdf, Puppeteer)
4. No AI-attribution signatures
5. Closing line: "ICCI, LLC — Secure. Governed. Operational."
```

## Anti-Patterns

### 1. Direct MCP Bypass

**Wrong:** Skill calls `happyfox_ticket_create` directly.
**Right:** Skill delegates to `icci-happyfox` which wraps the MCP call.

### 2. Domain Duplication

**Wrong:** New skill implements its own GAM commands for Google Workspace.
**Right:** New skill delegates to `icci-gam-pfm` for Workspace operations.

### 3. Branding Reimplementation

**Wrong:** Skill hardcodes CSS colors and fonts for its reports.
**Right:** Skill reads from `icci-report-branding/brand/identity.md`.

### 4. Island Skills

**Wrong:** Skill has no Cross-Skill Delegation section, no awareness of neighbors.
**Right:** Skill documents what it delegates, to whom, and when.

## Building Delegation into a New Skill

When creating a new skill with icci-skill-creator:

1. **During Phase 2 (Research):** Scan all existing skills and MCPs. Document overlaps.
2. **During Phase 4 (Write SKILL.md):** Add a Cross-Skill Delegation section listing:
   - What this skill delegates (and to whom)
   - What other skills might delegate TO this skill
   - Which MCPs this skill should/shouldn't call directly
3. **During Phase 7 (Supporting Files):** Add `references/ecosystem.md` if the delegation map is complex.
4. **After shipping:** Update the ecosystem map in THIS file (`cross-skill-delegation.md`) to include the new skill.
