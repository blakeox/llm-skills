# HappyFox MCP vs Skill — Division of Responsibility

Last updated: 2026-03-10

## Principle

The MCP is a **stateless proxy** to the HappyFox API. It handles authentication, request routing, payload validation, and response formatting. It does NOT store state, manage identity, or contain ICCI-specific business logic.

The Skill is the **intelligence layer** that runs locally on each tech's machine. It provides context (who am I, what are our workflows, what's broken), directs Claude to call the right MCP tools with the right parameters, and handles output formatting (reports, PDFs, bulk processing).

**Rule: If it talks to HappyFox, it goes through the MCP. If it talks to the tech, it lives in the skill.**

## Current Division

### MCP Owns (Cloudflare Worker — `icci/happy-fox-mcp`)

| Responsibility              | Tools / Implementation                                                                                                                                                                           |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| HappyFox API authentication | API key + auth code (Worker secrets)                                                                                                                                                             |
| Client authentication       | Per-client API keys, `mcp_clients` registry                                                                                                                                                      |
| Ticket CRUD                 | `ticket_create`, `ticket_get`, `ticket_latest`, `ticket_search`, `ticket_filter`, `ticket_threads_list`                                                                                          |
| Ticket mutations            | `ticket_contact_reply`, `ticket_private_note`, `ticket_staff_update`, `ticket_update_status`, `ticket_action`, `ticket_manage`, `ticket_delete`, `ticket_move`, `ticket_forward`, `ticket_merge` |
| Contact CRUD                | `contacts_list`, `contacts_search`, `contacts_create`, `contact_get`, `contact_update`, `contact_upsert`, `contact_delete`                                                                       |
| Contact groups              | `contact_groups_list`, `contact_group_create`, `_update`, `_delete`, `_add_contacts`, `_remove_contacts`, `_manage`                                                                              |
| Instance config             | `categories_list`, `priorities_list`, `staff_list`, `statuses_list`, `ticket_custom_fields_list`, `canned_actions_list`                                                                          |
| Knowledge base              | `kb_articles_*`, `kb_sections_*`, `kb_export`                                                                                                                                                    |
| Reports (raw data)          | `reports_list`, `report_get`, `report_summary`, `report_tabular`, `report_staff_*`, `report_contact_activity`, `report_response_stats`, `report_sla_entries`                                     |
| Assets                      | `assets_list`, `asset_*`                                                                                                                                                                         |
| Payload sanitization        | `sanitizeManagePayload` + allowlists                                                                                                                                                             |
| Rate limiting               | Per-client rate limits from `mcp_clients`                                                                                                                                                        |
| Request logging             | Correlation IDs, request tracing                                                                                                                                                                 |

### Skill Owns (Local — `~/.claude/skills/icci-happyfox/`)

| Responsibility                | Implementation                                                                           |
| ----------------------------- | ---------------------------------------------------------------------------------------- |
| Tech identity                 | `config/default-tech.json` — who is operating, staff_id injection                        |
| ICCI business context         | Staff roles, client relationships, category assignments, escalation rules                |
| Workflow orchestration        | Multi-step recipes (DI audit → ticket, cross-skill data gathering → ticket)              |
| Token efficiency              | Progressive disclosure (read summary before threads), bulk processing via Python scripts |
| MCP tool documentation        | `references/mcp-tools.md` — parameter formats, working/broken status                     |
| Bug tracking                  | `references/known-issues.md`, GitHub issue filing workflow                               |
| Feature requests              | `references/mcp-feature-requests.md`                                                     |
| Report generation (formatted) | ICCI-branded PDFs via `icci-report-branding`, WeasyPrint                                 |
| Bulk data processing          | `scripts/bulk_ticket_search.py` — filters/aggregates MCP output outside context          |
| Safety guardrails             | Destructive operation warnings, confirmation prompts                                     |
| Formatting standards          | HTML descriptions, no hard line breaks, professional tone                                |
| Self-improvement              | Session learning protocol, reference file updates                                        |
| Version management            | Skill version check, sync to GitHub repo                                                 |

### Shared / Gray Area

| Data       | MCP Source                 | Skill Cache              | Notes                                                                                      |
| ---------- | -------------------------- | ------------------------ | ------------------------------------------------------------------------------------------ |
| Categories | `happyfox_categories_list` | SKILL.md table (6 rows)  | Skill cache saves a tool call per conversation. **Risk: goes stale if categories change.** |
| Priorities | `happyfox_priorities_list` | SKILL.md table (5 rows)  | Same tradeoff. Priorities rarely change.                                                   |
| Staff      | `happyfox_staff_list`      | SKILL.md table (6 rows)  | **Higher stale risk** — staff turnover means wrong IDs.                                    |
| Statuses   | `happyfox_statuses_list`   | SKILL.md table (14 rows) | Same tradeoff. Statuses change more often than priorities.                                 |

**Recommendation for the gray area:** Keep the cached tables for token efficiency, but add a freshness check. On first use in a conversation, the skill could silently call `happyfox_staff_list` and compare against the cached table. If they differ, update the cache and warn the user. This is a small token cost (one call per conversation) that prevents stale data bugs.

## Ideal Division (what we're working toward)

### MCP Changes Needed

1. **Deploy existing fixes** — #1 (ticket_action 405) and #2 (staff field stripping) are fixed in repo but not deployed
2. **Fix #7** — add `"user"` to `contact_reply` allowlist
3. **Better error messages** — pre-validate required fields and return clear errors before forwarding to HappyFox (e.g., `"contact_reply requires 'user' (staff ID) in the payload"`)
4. **No identity management** — the MCP should never store or inject default staff IDs. If the caller doesn't provide `user`/`staff`, the request fails. That's correct.

### Skill Changes Needed

1. **Freshness check for cached tables** — compare against MCP on first use, auto-update if stale
2. **Status change** — `update_status` is confirmed working; update USAGE.md to reflect this
3. **Test untested tools** — systematically work through the "Untested" tools in mcp-tools.md
4. **Expand recipes** — as more tools are confirmed working, add real-world workflow recipes

### What Should NEVER Move

| Never in the MCP                          | Never in the Skill                        |
| ----------------------------------------- | ----------------------------------------- |
| ICCI branding/report generation           | HappyFox API calls (even via curl/Python) |
| Tech identity storage                     | Payload sanitization or validation        |
| Business workflow logic                   | Authentication or rate limiting           |
| Bug tracking / known issues               | Request routing                           |
| Destructive operation guardrails          | Response formatting from HappyFox         |
| Cross-skill orchestration (DI, GAM, etc.) |                                           |

## Anti-Patterns to Avoid

1. **Skill calling HappyFox directly** (via curl, Python requests, etc.) — always go through MCP tools
2. **MCP storing ICCI-specific config** — business rules belong in the skill, not the proxy
3. **Duplicating MCP logic in the skill** — e.g., writing a Python script that implements ticket search instead of using `happyfox_ticket_search`
4. **Skill caching MCP data without freshness checks** — leads to stale IDs, wrong assignments
5. **MCP silently defaulting missing fields** — fail loud, let the caller fix their request
