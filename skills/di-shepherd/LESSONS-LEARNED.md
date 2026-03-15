# Lessons Learned

Append-only institutional memory. Never delete entries — only add new ones.

---

## 2026-03-08 — Initial build: API research findings

**Context**: Building DI-Shepherd skill from scratch with Deep Instinct API research.

**Discoveries**:
- The deprecated Python wrapper (`pvz01/deepinstinct-rest-api-wrapper`) is abandoned — use direct API calls
- Swagger spec is live at the tenant URL (`/api/v1/`) and contains the full OpenAPI spec at `/api/v1/swagger.json`
- Our READ_AND_REMEDIATION key cannot modify allow/deny lists or policies — those require FULL_ACCESS
- Device actions (disable, enable, remove, file delete, process terminate) are queued and execute at next agent check-in, not immediately
- Pagination is 50 items hard limit — no way to increase batch size
- No quarantine restore API endpoint exists — GUI only
- Suspicious events endpoints return 401 if the feature isn't enabled on the tenant license

**Takeaway**: Always check the actual Swagger spec for the tenant rather than relying on third-party documentation. Permission level boundaries matter — document what our key can and cannot do.

---

## 2026-03-08 — First remediation session: API response formats & policy management

**Context**: Full fleet remediation using both RR and FULL_ACCESS keys with dual-verification guardrails.

**API Response Format Gotchas**:
- Events endpoint returns `{"last_id": N, "events": [...]}` — NOT a plain list. Broke pagination code multiple times.
- Devices endpoint returns a plain list — inconsistent with events.
- `POST /events/actions/close` requires `{"ids": [...]}` (plural). Using `{"id": [...]}` returns 400.
- `PUT /policies/{id}/data` needs `{"data": {...}}` envelope. Must include `"model": "WindowsPolicyData"`. Must EXCLUDE password hash fields (`uninstall_password_hash`, `disable_password_hash`, `uninstall_password`, `disable_password`) or returns 422. Also remove null fields.
- `POST /policies/` requires `base_policy_id` field to clone from — can't create empty.
- Allow-list path endpoints can't have spaces in URL — use bulk `POST /policies/{id}/allow-list/paths` with `{"items": [...]}` instead of single `POST /policies/{id}/allow-list/paths/{path}`.
- `POST /events/search` supports `status`, `threat_severity`, `type`, `action` filters. Does NOT support `file_hash` filter.
- `GET /events/file/{hash}` returns global threat intel (paths from ALL tenants across DI platform) — useful for identifying what a file actually is.

**Policy Management Lessons**:
- Previous tech (EG, JUN-JUL 2025) used sledgehammer approach: turned off 5+ behavioral protections to fix FPs instead of using targeted allow-lists. The allow-lists EG built actually cover most of the FP sources — the protection disabling was unnecessary overkill.
- Allow-list entries were frequently placed on wrong client policies (TP7 on MKM instead of Praxis, Impromed mislabeled). Always verify which client a software belongs to before adding allow-list entries.
- DASSISTANTW7 W3i folder is part of Tenant Pro 7 install chain — DO NOT DELETE. Aaron has experienced past breakage from FP remediation on TP7.
- When creating client-specific allow-list entries, use a client-specific policy (create one if needed) rather than the Windows Default Policy. Fleet-wide policies should only contain fleet-wide entries.

**Operational Lessons**:
- ScreenConnect WOL is GUI-only (right-click > Wake). No CLI/API to invoke from SSH.
- ScreenConnect "Run Command" is also GUI-only. Scripts must be pasted via the web UI.
- DI `delete-remote-files` requires event IDs and only works on the NEXT device check-in. If events are already closed, may not work — use PowerShell cleanup via ScreenConnect instead.
- Brain updates have no API endpoint — GUI only. But `automatic_brain_upgrade` in policy data controls whether agents auto-update their brain.
- `requests` Python module is not installed on Aaron's Mac — use `urllib` for all API calls.

**Takeaway**: Build and reference the comprehensive Swagger API reference (`references/di-api-swagger-reference.md`) before making API calls. The response format inconsistencies cost significant tokens in debugging. Always verify policy → group → device mapping before modifying allow-lists.

---

## 2026-03-08 — MSP360 Backup API integration

**Context**: First integration with the MSP360 Backup API at api.mspbackups.com.

**Discoveries**:
- Login requires username + password (separate fields), not a single API key. Username is `TmVrTFfQPr`, password provided separately.
- Auth returns a Bearer token valid for 14 days. Use `Authorization: Bearer {token}` on all subsequent calls.
- Image backup plans (`BackupDiskImagePlan`) CANNOT be started or modified via the API — returns HTTP 500 with "Unknown application deepinst". Must use MSP360 web console.
- The DI licensing is integrated into MSP360 — 127 of 191 licenses are "Deep Instinct" type. This is the connection between the two platforms.
- The backup API is properly tenant-scoped (unlike the DI API). Only ICCI's 23 companies and 177 endpoints are visible.
- Computer history endpoint returns `{"Computers": [{"Plans": [{"Sessions": [...]}]}]}` — deeply nested, not a flat list.
- Monitoring status codes: 0=Success, 1=Warning, 2=Error, 3=Interrupted, 4=Running, 5=Overdue, 6=Failed, 7=NoStatus.

**Operational lessons**:
- Joy's (DAssistantW7) backup fails because she leaves Tenant Pro 7 open. TP7 locks database files, VSS can't snapshot. Fix: scheduled reboot before backup.
- HYPERBARICS (Oxford Kids Foundation) is on LEGAL HOLD — never archive, delete, or modify. Keep as-is.
- 35 endpoints in "Unknown" company need reassignment — orphaned from previous setup.
- `POST /api/Builds/RequestCustomBuilds` can generate branded installers programmatically.

**Takeaway**: The MSP360 backup API is more limited than the DI API for write operations on image plans. Use the web console for plan modifications. The API is best for monitoring, reporting, and user/company management.
