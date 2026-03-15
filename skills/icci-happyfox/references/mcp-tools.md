# HappyFox MCP Tools — Inventory & Parameters

Last verified: 2026-03-12

## Tool Categories

### Configuration (all working)

| Tool                                 | Purpose                | Parameters |
| ------------------------------------ | ---------------------- | ---------- |
| `happyfox_categories_list`           | List ticket categories | None       |
| `happyfox_priorities_list`           | List priorities        | None       |
| `happyfox_staff_list`                | List staff members     | None       |
| `happyfox_statuses_list`             | List statuses          | None       |
| `happyfox_ticket_custom_fields_list` | List custom fields     | None       |
| `happyfox_canned_actions_list`       | List canned actions    | None       |

### Ticket Read (all working)

| Tool                           | Purpose             | Key Parameters                                                                                                                                                                                                                                   |
| ------------------------------ | ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `happyfox_ticket_get`          | Get ticket by ID    | `ticket_id` (string, numeric only e.g. "6823")                                                                                                                                                                                                   |
| `happyfox_ticket_latest`       | Recent tickets      | `limit` (int, max 100), `status` (string, optional)                                                                                                                                                                                              |
| `happyfox_ticket_search`       | Search tickets      | TBD — needs testing                                                                                                                                                                                                                              |
| `happyfox_ticket_filter`       | Filter tickets      | `category_id` (int), `status` (string), `assignee_id` (int), `priority` (int), `page` (int), `size` (int, max 100). **⚠️ Sorts by `updated_at` DESC, NOT `created_at`** — cannot paginate to a date boundary. No date-range params (see FR-009). |
| `happyfox_ticket_threads_list` | Full thread content | `ticket_id` (string)                                                                                                                                                                                                                             |

### Ticket Write

| Tool                                   | Status                            | Parameters                                                                                                                                           |
| -------------------------------------- | --------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `happyfox_ticket_create`               | **WORKING**                       | `subject`_, `description`_, `requester_email`\*, `category_id`, `priority`, `assignee_id`, `cc_emails`, `bcc_emails`, `custom_fields`, `attachments` |
| `happyfox_ticket_action`               | **BROKEN (405)**                  | `ticket_id`_, `action`_, `assignee_id`, `status`, `priority`, `note`, `category_id`, `tags`                                                          |
| `happyfox_ticket_staff_update`         | **BROKEN (staff field stripped)** | `ticket_id`_, `payload`_                                                                                                                             |
| `happyfox_ticket_private_note`         | **BROKEN (staff field stripped)** | `ticket_id`_, `payload`_                                                                                                                             |
| `happyfox_ticket_manage`               | **BROKEN (staff field stripped)** | `ticket_id`_, `action`_, `payload`                                                                                                                   |
| `happyfox_ticket_contact_reply`        | **BROKEN (user field stripped)**  | `ticket_id`_, `payload`_                                                                                                                             |
| `happyfox_ticket_update_status`        | **WORKING**                       | `ticket_id`_, `status`_ (int ID), `staff_id` (string), `note` (string, **PLAIN TEXT ONLY — HTML is escaped/rendered as raw tags, see BUG-009**)      |
| `happyfox_ticket_update_tags`          | Untested                          | TBD                                                                                                                                                  |
| `happyfox_ticket_update_custom_fields` | Untested                          | TBD                                                                                                                                                  |
| `happyfox_ticket_forward`              | Untested                          | TBD                                                                                                                                                  |
| `happyfox_ticket_merge`                | Untested                          | TBD                                                                                                                                                  |
| `happyfox_ticket_move`                 | Untested                          | TBD                                                                                                                                                  |
| `happyfox_ticket_delete`               | Untested                          | `ticket_id`\*                                                                                                                                        |
| `happyfox_ticket_subscribe`            | Untested                          | TBD                                                                                                                                                  |
| `happyfox_ticket_unsubscribe`          | Untested                          | TBD                                                                                                                                                  |
| `happyfox_ticket_attachment_add`       | Untested                          | `ticket_id`_, `payload`_                                                                                                                             |

### Contact Operations

| Tool                                  | Status                   | Parameters                                                       |
| ------------------------------------- | ------------------------ | ---------------------------------------------------------------- |
| `happyfox_contacts_list`              | Untested                 | TBD                                                              |
| `happyfox_contacts_search`            | **WORKING (fuzzy only)** | `q` (string), `page` (int), `size` (int, max 100)                |
| `happyfox_contacts_create`            | **WORKING**              | `email`\*, `name`, `phones`, `is_login_enabled`, `custom_fields` |
| `happyfox_contact_get`                | Untested                 | TBD                                                              |
| `happyfox_contact_update`             | Untested                 | TBD                                                              |
| `happyfox_contact_upsert`             | Untested                 | TBD                                                              |
| `happyfox_contact_delete`             | Untested                 | TBD                                                              |
| `happyfox_contact_groups_list`        | Untested                 | TBD                                                              |
| `happyfox_contact_group_*`            | Untested                 | Multiple group management tools                                  |
| `happyfox_contact_custom_fields_list` | Untested                 | TBD                                                              |

### Knowledge Base

| Tool                            | Status   | Parameters                        |
| ------------------------------- | -------- | --------------------------------- |
| `happyfox_kb_articles_external` | Untested | TBD                               |
| `happyfox_kb_articles_internal` | Untested | TBD                               |
| `happyfox_kb_article_get`       | Untested | TBD                               |
| `happyfox_kb_article_create`    | Untested | TBD                               |
| `happyfox_kb_article_update`    | Untested | TBD                               |
| `happyfox_kb_article_delete`    | Untested | TBD                               |
| `happyfox_kb_sections_list`     | Untested | TBD                               |
| `happyfox_kb_section_*`         | Untested | Multiple section management tools |
| `happyfox_kb_export`            | Untested | TBD                               |

### Reports

| Tool                                | Status                     | Parameters                                                                             |
| ----------------------------------- | -------------------------- | -------------------------------------------------------------------------------------- |
| `happyfox_reports_list`             | **TESTED — returns empty** | None. No pre-configured reports exist in the HappyFox instance (confirmed 2026-03-12). |
| `happyfox_report_get`               | Untested                   | TBD                                                                                    |
| `happyfox_report_summary`           | Untested                   | TBD                                                                                    |
| `happyfox_report_tabular`           | Untested                   | TBD                                                                                    |
| `happyfox_report_staff_activity`    | Untested                   | TBD                                                                                    |
| `happyfox_report_staff_performance` | Untested                   | TBD                                                                                    |
| `happyfox_report_contact_activity`  | Untested                   | TBD                                                                                    |
| `happyfox_report_response_stats`    | Untested                   | TBD                                                                                    |
| `happyfox_report_sla_entries`       | Untested                   | TBD                                                                                    |

### Scripting

| Tool                          | Status     | Notes                                             |
| ----------------------------- | ---------- | ------------------------------------------------- |
| `happyfox_execute`            | **BROKEN** | JS parser rejects all async arrow function syntax |
| `happyfox_javascript_execute` | **BROKEN** | Deprecated alias for happyfox_execute, same bug   |

### Assets

| Tool                   | Status   | Notes                             |
| ---------------------- | -------- | --------------------------------- |
| `happyfox_assets_list` | Untested | TBD                               |
| `happyfox_asset_*`     | Untested | Full CRUD + custom fields + types |

## Parameter Notes

### ticket_id format

- `happyfox_ticket_get`: use numeric string e.g. `"6823"` (not `"#IT00006823"`)
- `happyfox_ticket_create` returns ID in format `"#IT00006823"`
- Strip the `#IT0000` prefix when passing to other tools

### priority format

- Use the integer ID as a string: `"3"` for High, `"2"` for Critical, etc.
- Name strings like `"High"` also work in ticket_create

### category_id format

- Integer ID as string: `"1"` for ICCI IT Support

### assignee_id format

- Integer ID as string: `"5"` for Bowen Geng
