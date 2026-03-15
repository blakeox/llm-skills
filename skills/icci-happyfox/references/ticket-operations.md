# Ticket Operations Reference

## Creating Tickets

### Required Parameters

- `subject` (string) — ticket subject line
- `description` (string) — ticket body. MUST use single long lines per paragraph. No hard returns mid-sentence.
- `requester_email` (string) — must be a valid email. Contact auto-created if doesn't exist.

### Recommended Parameters

- `category_id` (string) — integer ID as string, e.g. "1" for ICCI IT Support
- `priority` (string) — integer ID as string: "2"=Critical, "3"=High, "1"=Medium, "4"=Low, "5"=Really Low
- `assignee_id` (string) — staff ID: "1"=Aaron, "2"=Emilie, "3"=Adam, "4"=Evan, "5"=Bowen, "6"=Blake

### Optional Parameters

- `cc_emails` (array of strings) — CC recipients
- `bcc_emails` (array of strings) — BCC recipients
- `custom_fields` (object) — key-value pairs (none configured currently)
- `attachments` (array) — format unknown, needs testing (see FR-007)

### Example

```
happyfox_ticket_create(
  subject="SERVER (St. Joseph) — PUA Cleanup from DI Audit",
  requester_email="stjosadmin@stjos.com",
  category_id="1",
  priority="3",
  assignee_id="5",
  description="Background paragraph as a single long line.\n\nSecond paragraph also as a single long line. Include all details, scripts, and instructions."
)
```

## Reading Tickets

### Get by ID

- `happyfox_ticket_get(ticket_id="6823")` — returns ticket with summarized threads
- Use numeric ID only (strip #IT0000 prefix)

### Latest Tickets

- `happyfox_ticket_latest(limit=10)` — most recently updated tickets
- Optional: `status="New"` to filter by status name
- Returns compact summaries (no thread content, includes thread_count)

### Full Thread Content

- `happyfox_ticket_threads_list(ticket_id="6823")` — all messages/updates
- Use sparingly — can be large. Read ticket_get summary first.

### Search & Filter

- `happyfox_ticket_search` — needs testing
- `happyfox_ticket_filter` — needs testing
- For large searches, prefer Python script `scripts/bulk_ticket_search.py`

## Updating Tickets (CURRENTLY BROKEN)

All update operations are blocked by MCP bugs. Use HappyFox web UI until fixed.

See `known-issues.md` for details on BUG-001 and BUG-002.

## Deleting Tickets

**DESTRUCTIVE OPERATION** — always show bold red warning and require confirmation.

- `happyfox_ticket_delete(ticket_id="6823")` — untested
- NEVER delete without counting affected items and getting explicit "yes"
