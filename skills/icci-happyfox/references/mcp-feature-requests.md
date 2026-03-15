# HappyFox MCP — Feature Requests & Improvement Ideas

For Blake Oxford — things that would make the MCP more efficient or fix gaps.

Last updated: 2026-03-12

## Priority: HIGH

### FR-001: Fix ticket update operations

- **Bug refs**: BUG-001, BUG-002
- The `ticket_action` tool returns 405 for all actions. The `staff_update`/`private_note`/`manage` tools strip the `staff` field from payloads. Without working update tools, the MCP is create-and-read-only.
- This blocks: ticket reassignment, adding notes, status changes, priority changes — all core helpdesk workflows.

### FR-002: Pass through HappyFox error details

- When HappyFox returns a 400, the response body contains field-level errors (e.g., `{"error":{"staff":"This field is required"}}`). The typed tools (like `ticket_create`) only show the generic "HappyFox rejected request with status 400" — the detail is swallowed. Only `ticket_manage`/`ticket_staff_update` pass through the detail field.
- All tools should include the upstream error detail in their response.

### FR-003: Fix `happyfox_execute` JavaScript parser

- No syntax variant of async arrow function is accepted. This prevents bypassing broken typed tools to test the raw API. See BUG-003 for syntax attempts.

### FR-009: Date-range filtering on `ticket_filter`

- This is the #1 missing feature for reporting and analytics
- **Current behavior**: `ticket_filter` accepts `category_id`, `status`, `assignee_id`, `priority`, `page`, `size`. No date parameters. Results are sorted by `updated_at` (not `created_at`), which means you cannot stop paginating at a date boundary — you must fetch ALL tickets to count by creation month.
- **Requested**: Add `created_after`, `created_before` (ISO 8601 date strings) to `ticket_filter`. Optionally also `updated_after`, `updated_before`.
- **Impact**: Without this, any date-based analysis requires fetching the entire ticket history (800+ tickets, growing monthly). This wastes API calls, time, and tokens.
- **Workaround**: Use a Python script (`scripts/ticket_count_by_month.py`) with an Agent subagent to paginate, dump to JSON, and count outside Claude's context. Works but slow and brittle.
- **Also note**: `happyfox_reports_list` returns empty (no configured reports in the instance), so HappyFox's built-in reporting can't help either.

## Priority: MEDIUM

### FR-004: Exact email match in contact search

- `happyfox_contacts_search` only does fuzzy/fulltext matching. An exact email lookup would save a tool call (currently have to create/upsert just to confirm a contact exists).

### FR-005: Bulk ticket creation

- For workflows like creating tickets from a DI-Shepherd audit (5-10 tickets at once), a batch creation endpoint would save significant API round-trips and context tokens.

### FR-006: Ticket update without message

- Sometimes you just need to reassign a ticket or change status without adding a message. The current tools require a `staff` author for every update. A simple "patch ticket fields" tool would be cleaner.

## Priority: LOW

### FR-007: Attachment support documentation

- The `happyfox_ticket_create` schema shows an `attachments` array but the item schema is empty (`{}`). No documentation on what format attachments should be in (base64? URL? multipart?). Similarly, `happyfox_ticket_attachment_add` takes a `payload` object with no schema.

### FR-008: Pagination for ticket_latest

- `happyfox_ticket_latest` returns up to 100 tickets but has no offset/cursor. For historical analysis, pagination would allow walking through the full ticket history.

## Completed / Resolved

(None yet)
