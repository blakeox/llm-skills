# HappyFox Recipes — Common Workflows

## Recipe 1: Create ticket from DI-Shepherd audit

```
1. Read the PS1 script from ~/Documents/claude-code/di-shepherd/reports/remediation-scripts/
2. Look up client admin email and category
3. Create ticket:
   - Subject: "MACHINE (Client) — Brief description from DI Audit"
   - Category: ICCI IT Support (1) or client-specific
   - Priority: High (3) for online machines, Medium (1) for offline
   - Assignee: Bowen (5) for L1, Aaron (1) for escalations
   - Description: Single flowing paragraphs. Include background, script content, how-to-run steps, source reference.
```

## Recipe 2: Check recent ticket activity

```
happyfox_ticket_latest(limit=10)
```

Returns compact summaries — good for a quick status check without burning context.

## Recipe 3: Look up a specific ticket

```
happyfox_ticket_get(ticket_id="6823")  # numeric ID only
```

Returns ticket details with summarized thread. Only use `ticket_threads_list` if you need the full conversation.

## Recipe 4: Create a contact before ticketing

```
happyfox_contacts_create(email="admin@client.com", name="Client Admin Name")
```

Does upsert behavior — safe to call even if contact exists.

## Recipe 5: Find tickets by status

```
happyfox_ticket_latest(limit=50, status="New")
```

Good for finding unassigned/new tickets.

## Context Efficiency Lessons (learned 2026-03-10)

- **ticket_create responses echo the full description back twice** (plaintext + HTML). For bulk ticket creation (3+), use a Python script that calls MCP and returns only ticket IDs — saves ~90% context per ticket.
- **Don't re-test known-broken MCP tools** in the same session. One confirmation is enough.
- **Delegate to other skills** (di-shepherd, icci-gam-pfm) instead of reimplementing their API calls inline.
- **Keep GitHub issue comments focused** — root cause + fix + Claude Code prompt. Skip the prose.

## Recipe 6: Count tickets by creation month (date-range analysis)

**Problem**: `ticket_filter` has no date-range parameters and sorts by `updated_at`, not `created_at`. You can't paginate to a date boundary and stop. You must fetch ALL tickets.

**Correct approach — Agent subagent + Python script**:

```
1. Launch an Agent subagent to:
   a. Page through ticket_filter(size=100, page=1..N) until empty
   b. Write the raw JSON array to /tmp/hf_all_tickets.json
   c. Run: python3 ~/.claude/skills/icci-happyfox/scripts/ticket_count_by_month.py \
        --input /tmp/hf_all_tickets.json \
        --output /tmp/hf_counts.json \
        --months 2025-11,2025-12,2026-01
   d. Return only the stdout summary (3-5 lines) to the main conversation
2. The main conversation gets ONLY the count summary — no raw ticket data in context.
```

**Why this matters**: A full ticket dump is 800+ tickets with descriptions, email signatures, and forwarded messages. Pulling that into Claude's main context wastes 50K+ tokens and risks running out of context before completing the task.

**Quick estimate alternative**: If exact counts aren't needed, ticket IDs are globally sequential by creation date. Fetch a few tickets at month boundaries to find the ID range, then subtract. Yields ±5 accuracy in seconds with minimal token cost.

**Feature request**: FR-009 asks Blake to add `created_after`/`created_before` to `ticket_filter`, which would make this trivial.

## Anti-Patterns (Don't Do This)

- Don't pull `ticket_threads_list` for multiple tickets in a row — context explosion
- Don't use `contacts_search` to verify existence — unreliable fuzzy matching
- Don't try to reassign via MCP — use HappyFox web UI (BUG-001/002)
- Don't put hard line breaks in ticket descriptions — looks terrible to recipients
- **Don't paginate `ticket_filter` into the main conversation for counting/analytics** — use an Agent subagent + Python script. The raw data stays in subagent context and only the summary comes back. See Recipe 6.
