# HappyFox MCP — Known Issues & Workarounds

Last updated: 2026-03-12

## GitHub Issue Status

**All 10 issues on `icci/happy-fox-mcp` are CLOSED as of 2026-03-12.** Several MCP-side limitations remain (HappyFox platform behavior, not MCP bugs). See "Remaining Limitations" below.

## Remaining Limitations

### LIMIT-001: Cannot assign tickets via MCP

- **GitHub (closed)**: #5 (create), #9 (action)
- **Behavior**: `assignee_id` on `ticket_create` is silently ignored. `ticket_action` with `assign` strips `assignee_id` from payload.
- **Workaround**: Assign manually in HappyFox web UI after creation.

### LIMIT-002: `contact_reply` rejects staff ID as `user`

- **GitHub (closed)**: #7
- **MCP fix deployed**: `user` field now passes through the allowlist.
- **HappyFox rejects it**: Staff ID 1 returns `"Invalid user id"`. The API expects an internal HappyFox user account ID, not the staff list ID. The correct ID is unknown and not exposed by any MCP tool.
- **Impact**: Cannot send client-facing replies (with email notification) via MCP.
- **Workaround**: Reply via HappyFox web UI or Gmail.

### LIMIT-003: `html` field not in `staff_update` allowlist (MOOT — see LIMIT-004)

- **GitHub (closed)**: #10 — Blake's fix normalized `message` → `text` via alias, but never added `html` to the `staff_update` allowlist.
- **Current allowlist for `staff_update`**: `text`, `body`, `cc`, `bcc`, `staff`, `staff_only`, `status`, `priority`, `assigned_to`
- **`html` exists in**: `contact_reply` and `forward` allowlists only.
- **`body` field**: In the allowlist but HappyFox rejects it with "Nothing to update" — the API doesn't accept `body` for staff updates.
- **Impact**: Moot — even if `html` were in the allowlist, HappyFox doesn't render HTML in staff updates (LIMIT-004).
- **No new issue needed** — filing a bug would waste Blake's time since the platform doesn't support it anyway.
- **Discovered**: 2026-03-12 (source code analysis of `tickets.ts` ~line 746)

### LIMIT-004: HappyFox does NOT render HTML in staff updates — CONFIRMED

- **Status**: **CONFIRMED BROKEN** — 2026-03-12, tested on #IT00005602.
- **This is a HappyFox platform limitation, not an MCP bug.** There is nothing Blake can fix.
- **Behavior**: HTML tags in the `text` field render as literal visible text in the HappyFox web UI. Tags like `<h3>`, `<p>`, `<code>` appear as raw characters, not as formatted HTML.
- **HTML only works in ticket CREATION** — the `description` field on `happyfox_ticket_create` renders HTML correctly. Staff updates do NOT.
- **Confirmed on**: #IT00006831 (2026-03-10), #IT00005602 (2026-03-12)
- **Rule**: **DO NOT use HTML tags in staff updates. Ever.** Use plain text: CAPS for headers, `- ` for bullets, `\n` for line breaks.

## Learnings

### HTML descriptions (discovered 2026-03-10)

- **HappyFox renders ticket descriptions as HTML.** Plain text becomes an unreadable wall of text.
- Use `<h3>` for sections, `<p>` for paragraphs, `<ol>/<ul>/<li>` for lists, `<strong>` for emphasis, `<pre><code>` for scripts/code blocks.
- Do NOT use CDATA wrappers — they leak into rendered output.
- Each `<p>` should be one long line — no hard breaks mid-sentence.
- Confirmed working on #IT00006824: clean section headers, numbered lists, properly formatted code block with preserved indentation.

### Staff update content field (discovered 2026-03-10, updated 2026-03-12)

- **Only `text` works** for `staff_update` action content. `message` is aliased to `text`. `html` is silently stripped. `body` passes allowlist but HappyFox rejects it.
- **Delete uses `staff_id`** (not `staff`) — inconsistent field naming.
- **Correct pattern for closing a ticket with a note:**
  1. `ticket_manage` → `action: "staff_update"`, `payload: {"staff": 1, "text": "plain text note"}`
  2. `ticket_update_status` → `status: "4"`, `staff_id: "1"` (no note field)

### Staff updates and HTML rendering (CONFIRMED BROKEN — HappyFox platform limitation)

- **2026-03-10**: HTML tags in `text` field rendered as literal text on #IT00006831.
- **2026-03-12**: Re-tested on #IT00005602 with styled `<h3>` and `<p>` tags. Aaron confirmed raw tags visible in web UI.
- **Verdict**: HappyFox does not render HTML in staff update threads. Only ticket descriptions (`happyfox_ticket_create` → `description` field) render HTML.
- **Rule**: Plain text only for staff updates. CAPS for headers, `- ` for bullets, `\n` for line breaks. See LIMIT-004.

## Future Work

### Ticket routing

- Assignment and routing is a separate workflow from ticket creation — not every ticket needs an assignee at creation time.
- Routing rules (auto-assign by category, priority, client) will be added to the skill later.
- For now, assignment is done manually in HappyFox web UI (blocked by BUG-001 and BUG-002).

## Resolved Issues

### RESOLVED-001: Ticket creation returning 400 (2026-03-09)

- **Symptom**: Every `happyfox_ticket_create` call returned generic 400 VALIDATION_ERROR
- **Root cause**: MCP permissions not enabled in Claude settings
- **Fix**: Aaron adjusted MCP preferences in Claude — write operations enabled
- **Date resolved**: 2026-03-10

## Debug Files

- Full investigation log: `~/Documents/claude-code/happyfox-mcp-debug-2026-03-09.md`
