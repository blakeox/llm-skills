# ICCI GAM PFM — Usage Guide

**Pure Fucking Magic for Google Workspace Administration**

Last updated: 2026-03-04

## What This Skill Does

This skill gives Claude expert-level GAM (GAMADV-XTD3) mastery for managing ICCI's 29 Google Workspace client domains. It handles everything from single user operations to bulk school year provisioning across all managed domains.

## Quick Start

Just tell Claude what you need. Examples:

```
"Create a new user jsmith@dahlmannproperties.com in the Staff OU"
"Reset the password for frontdesk@wvhcares.com"
"How many users without MFA across all our domains?"
"Set up 50 new student accounts for stpatschool.org from this CSV"
"Generate an MFA coverage report for Phoenix Co"
"Offboard departing employee from iraniwise.com"
"Show me all forwarding rules on wvhcares.com"
"Promote all students to the next grade at stpatschool.org"
```

## Managed Domains

### Reseller (24 domains) — @icci.com admin credentials
icci.com, icciadmin.com, dahlmannproperties.com, dahlmannhotels.com, annarborregent.com, wvhcares.com, phoenixco.biz, iraniwise.com, a2max.com, aaobserver.com, benkerner.com, bidlack.com, grafaktri.com, jbcaa.com, kozservices.com, m3marc.com, mkmventures.com, ngiammarco.com, oxfordhbot.net, praxisproperties.com, shaffran.com, societyofseniors.com, tamulevich.com, wholemindesign.com

### Non-Profit / Schools (5 domains) — per-domain admin credentials
stpatschool.org (590 users), stpaulannarbor.org (675 users), stmarypinckney.org (163 users), stjos.com (24 users), oxfordkidsfoundation.org (15 users)

## Capabilities by Category

### User Management
- Create, update, suspend, unsuspend, delete users
- Password resets (random, specific, with notification)
- OU moves, email renames, alias management
- Custom schema management (student metadata)
- Admin role assignment

### Group Management
- Create, update, delete groups
- Add/remove members, managers, owners
- Sync membership from CSV (with add-only option)
- Group settings (posting, moderation, visibility)

### School Operations
- **Student provisioning** from SIS CSV exports
- **Classroom course** creation, enrollment, and archiving
- **Guardian** invitations and management
- **Grade promotion** (end-of-year OU moves)
- **Chrome device** assignment and fleet management
- **School year lifecycle** (summer prep, fall setup, mid-year, spring)

### Gmail & Calendar
- Forwarding rules (set, check, disable)
- Delegates (read/send-as access)
- Filters (create, delete, list)
- Signatures (set from template with tag replacement)
- Vacation responders
- Calendar ACLs and resource management

### Drive Management
- File upload, download, search
- Permissions and sharing
- Drive transfers (employee offboarding)
- Shared Drive management

### Security
- MFA/2SV status checking and enforcement
- Backup codes (generate, show, delete)
- Force signout, deprovision
- OAuth token audit and revocation
- Full account lockdown (compromised accounts)

### Reporting
- Login, admin, Drive, Gmail, Chrome, Calendar reports
- Usage reports (storage, apps)
- Cross-domain reporting (all clients at once)
- ICCI-branded PDF report generation

### Bulk Operations
- CSV-driven commands for any operation
- Batch processing (parallel execution)
- Multi-process output aggregation
- User collection targeting (OU, group, query, file, license)

### MSP Operations
- Multi-domain management (29 domains)
- Cross-domain reporting sweeps
- Reseller customer and subscription management
- New client onboarding workflow

### Offboarding
- Full employee offboarding workflow (8 steps)
- Data transfers (Drive, Calendar)
- Student exit procedures
- Account reactivation

## Safety Features

This skill includes safety checks for destructive operations:

- **Bulk deletes**: Before deleting users, the skill will count affected accounts and ask for confirmation
- **Suspensions**: Before bulk suspending, shows the user count and asks "are you sure?"
- **OU moves**: Before moving large groups, previews the operation
- **Deprovisioning**: Warns that this revokes all access and is hard to reverse
- **Grade promotion**: Shows the full promotion plan before executing

## Report Generation

The skill generates ICCI-branded PDF reports using WeasyPrint with:
- Navy/Gold/Cream color scheme
- Georgia headings, Inter body text
- ICCI logo and contact information
- Professional tables and statistics
- Marketing CTA footer

Branding pulls from the ICCI website refresh project. See `references/report-generation.md`.

## Team Setup

See `references/team-setup.md` for instructions on setting up GAM on other ICCI team members' computers. Key points:
- Reseller domains: each person creates their own OAuth token with their @icci.com account
- Non-profit domains: copy the shared OAuth tokens from the `credentials/` directory
- Service account key and client secrets are shared across all team members

## Skill Sync

This skill stays in sync between:
- `~/.claude/skills/icci-gam-pfm/` (local Claude Code skill)
- `~/Documents/GitHub/icci-skills/skills/icci-gam-pfm/` (GitHub repo)

Every update to the skill triggers a sync to the GitHub repo. The repo MUST remain private (contains OAuth credentials).

## Reference Files

| File | Contents |
|------|----------|
| `references/user-management.md` | User CRUD, passwords, aliases, schemas, admin roles |
| `references/group-management.md` | Groups, membership, sync, settings |
| `references/ou-management.md` | OUs, user moves, grade promotion |
| `references/classroom-education.md` | Courses, rosters, guardians, school year ops |
| `references/device-management.md` | Chrome devices, remote commands, fleet management |
| `references/gmail-calendar.md` | Forwarding, delegates, filters, signatures, calendar |
| `references/drive-management.md` | Files, sharing, transfers, Shared Drives |
| `references/security-mfa.md` | 2SV, backup codes, deprovision, tokens |
| `references/reporting.md` | Activity and usage reports, export options |
| `references/bulk-operations.md` | CSV commands, batch processing, user collections |
| `references/msp-multi-domain.md` | Multi-domain config, cross-domain ops |
| `references/reseller-operations.md` | Customer/subscription management |
| `references/offboarding-lifecycle.md` | Full offboarding workflow, data transfers |
| `references/recipes.md` | Shortcuts, tricks, and PFM-level combinations |
| `references/team-setup.md` | Setting up GAM on team computers |
| `references/report-generation.md` | ICCI-branded PDF report generation |
| `references/branding-config.md` | Current branding repo URL and fallback values |

## Version History

| Date | Change |
|------|--------|
| 2026-03-04 | Initial skill creation. 29 domains, 17 reference files, full GAM command coverage. |
