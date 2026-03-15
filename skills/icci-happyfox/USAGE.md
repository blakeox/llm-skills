# ICCI HappyFox Skill — Usage Guide

## Version History

### v1.0.0 — 2026-03-10 (Initial Release)

- Created skill framework based on Aaron's design brief
- Documented all MCP tools (working and broken)
- Cataloged HappyFox instance config (categories, priorities, staff, statuses)
- First ticket created via MCP: #IT00006823 (St. Joseph PUA cleanup)
- Known issues documented (ticket_action 405, staff field stripping, JS execute parser)
- Python script framework for token-efficient bulk operations
- Integrated with icci-report-branding for PDF generation

**Aaron's original design brief (2026-03-10, spell-checked):**

> Let's start a HappyFox skill. Base the skill on the self-learning skill in the Anthropic repository https://github.com/anthropics/skills — the objective of the skill is masterful use of the HappyFox MCP. The MCP may get updated so the skill will need to adapt. If the MCP needs a feature that would improve speed or efficiency (context wasting), we need a full report. The MCP repository is available in the ICCI org GitHub account. The MCP is published to a CF worker, so the availability of the MCP repository is for read-only use — modifying Blake's code is a bad idea directly. If we are going to make MCP code improvements, I will ask to remove this guardrail — read-only for now please. When the HappyFox skill is updated including memory and reports, please sync to the GitHub repository as well. A major reason for this skill is efficient use of tokens. If a new codebase needs to be part of the skill, make it so. For example, large reads of tickets looking for something in the description may be better done in Python than in context. We will be adding features to this skill for sure so keep the framework open. Make .md files for yourself that will help be efficient, but don't let these files become stale. If possible, when asked to perform large tasks and context is running out, offer the user to save memories, make a runbook.md and compact the context before running the report or task. It is not okay to hallucinate. Ask questions of the user — the user also has context in their head. All reporting should use the repository icci-report-branding. This repository was created by you, Claude, so you ALWAYS get my branding right the first time. Read it and follow the instructions in the repo when generating reports, don't just copy it. The branding will change someday and we may just make improvements to the instructions, so read it. When generating tickets never use hard returns mid-sentence as that actually looks SUPER LAME to the recipient. Be careful with actions that may delete a lot of data. Put up a warning in BOLD RED that says "hey dummy, are you sure you want to delete 42 tickets." Make them confirm or default to canceling.

---

## Quick Start

### Creating a ticket

```
/icci-happyfox create a ticket for stjosadmin@stjos.com about the server cleanup
```

### Searching tickets

```
/icci-happyfox find all open tickets for dahlmannproperties.com
```

### Ticket reports

```
/icci-happyfox generate a weekly summary report for Aaron
```

## Available Operations

### Working (confirmed 2026-03-10)

- **Ticket creation** — full parameters (subject, description, requester_email, category_id, priority, assignee_id)
- **Ticket reading** — get by ID, latest tickets, search, filter
- **Contact management** — search, create, upsert, update, delete, groups
- **Configuration** — list categories, priorities, staff, statuses, custom fields, canned actions
- **Knowledge Base** — articles, sections, export

### Not Working (MCP bugs, see `references/known-issues.md`)

- **Ticket updates** — staff_update, private_note, ticket_action all fail
- **Ticket reassignment** — blocked by staff field stripping bug
- **Raw JS execute** — parser broken, can't bypass typed tools

### Workarounds

- **Reassignment**: Must be done in HappyFox web UI until MCP is fixed
- **Ticket notes/updates**: Must be done in HappyFox web UI
- **Large searches**: Use `scripts/bulk_ticket_search.py` to avoid context bloat

## Recipes

### Create a DI-Shepherd remediation ticket

1. Read the PS1 script from `~/Documents/claude-code/di-shepherd/reports/remediation-scripts/`
2. Identify the target machine and client
3. Create ticket with:
   - requester: client admin email
   - category: ICCI IT Support (or client-specific if it exists)
   - priority: High (3) for online machines, Medium (1) for offline
   - assignee: Bowen (5) for L1 tasks, Aaron (1) for escalations
   - description: Background from DI audit, full script content, instructions, source reference

### Weekly ticket summary

1. Pull latest tickets via `happyfox_ticket_latest`
2. Group by status and category
3. Generate ICCI-branded PDF via `icci-report-branding`
4. Save to `~/Documents/claude-code/happyfox/`

## Examples for Staff

These examples show how to talk to Claude when the HappyFox skill is active. You can invoke the skill with `/icci-happyfox` followed by your request in plain English, or just mention HappyFox in conversation and the skill will trigger automatically.

---

### Example 1: Create a new ticket

**You say:**

> /icci-happyfox Create a ticket for Brian Nelson at Form Tech. His CNC machine workstation won't connect to the network printer. Assign to Bowen, priority medium.

**What Claude does:**

- Looks up or creates contact for `BNelson@FORMTECHINC.COM`
- Creates ticket in the "Form Tech" category (ID 2)
- Sets priority to Medium (1), assigns to Bowen (5)
- Writes a professional description with the issue details

---

### Example 2: Check what's in the queue

**You say:**

> /icci-happyfox Show me the latest 10 tickets

**What Claude does:**

- Calls `happyfox_ticket_latest(limit=10)`
- Returns a summary table: ticket ID, subject, status, requester, assignee, last updated

---

### Example 3: Look up a specific ticket

**You say:**

> /icci-happyfox What's the status on ticket 6666?

**What Claude does:**

- Calls `happyfox_ticket_get(ticket_id="6666")`
- Shows ticket details, current status, assignee, and a summary of the thread
- Only pulls full thread content if you ask to see the conversation

---

### Example 4: Create a ticket from a DI-Shepherd audit finding

**You say:**

> /icci-happyfox Create a ticket for the SCHOOLSVR1 keygen cleanup. Use the PS1 script from the DI reports. Assign to Bowen, high priority. Requester is stmaryadmin@stmarypinckney.org

**What Claude does:**

- Reads `~/Documents/claude-code/di-shepherd/reports/remediation-scripts/SCHOOLSVR1.ps1`
- Creates the ticket with DI audit background context, full script content, step-by-step instructions
- References the source audit report
- Professional formatting (no ugly hard line breaks)

---

### Example 5: Find tickets for a specific client

**You say:**

> /icci-happyfox Show me all open tickets for Oxford Center

**What Claude does:**

- Searches/filters tickets by category "The Oxford Center" (ID 6)
- Returns matching open tickets with status and assignee

---

### Example 6: Generate a report

**You say:**

> /icci-happyfox Generate a weekly ticket summary PDF for the last 7 days

**What Claude does:**

- Pulls recent tickets from HappyFox
- Groups by status, category, and assignee
- Generates ICCI-branded PDF using the `icci-report-branding` system
- Saves to `~/Documents/claude-code/happyfox/`

---

### Example 7: Bulk operation (with safety check)

**You say:**

> /icci-happyfox Close all tickets with status "Waiting on Client" that haven't been updated in 60 days

**What Claude responds:**

> **WARNING: This will close {N} tickets. Are you sure? (yes/no, default: CANCEL)**

Claude will count the affected tickets and make you confirm before taking action. This safety check applies to all bulk modifications and deletions.

---

### Example 8: Count tickets by month

**You say:**

> /icci-happyfox How many tickets were created in November, December, and January?

**What Claude does:**

- Launches an Agent subagent to page through ALL tickets via `ticket_filter`
- Writes raw data to a temp file (keeps it out of your conversation context)
- Runs `scripts/ticket_count_by_month.py` to count by `created_at` month
- Returns only the summary counts (e.g., "Nov: 83, Dec: 96, Jan: 111")

**Why it works this way:** HappyFox's `ticket_filter` has no date-range parameter and sorts by `updated_at` not `created_at`, so all tickets must be fetched. The Python script keeps the heavy data out of context. See FR-009 for the feature request to fix this upstream.

---

### What's NOT working yet (use HappyFox web UI)

These operations are blocked by MCP bugs and need to be done in the web interface:

- **Reassigning tickets** to a different staff member
- **Adding notes** or staff updates to existing tickets
- **Changing status** on existing tickets
- **Replying** to tickets

Blake is aware — see `references/mcp-feature-requests.md` for the fix list.

---

## Tips

- Ticket IDs in HappyFox are formatted as `#IT00006823` but most MCP tools want just the numeric part: `6823`
- Contact search is fuzzy and unreliable — if you need an exact match, create/upsert instead
- The `happyfox_ticket_latest` tool is the most efficient way to see recent activity
- Always check `references/known-issues.md` before trying a new MCP tool operation
- You don't need to memorize category IDs or staff IDs — just say the name and Claude will look it up
