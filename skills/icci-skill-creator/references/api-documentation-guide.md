# API Documentation Guide for ICCI Skills

When a skill talks to an external API, document it thoroughly. Future sessions, other team members, and other skills all benefit from complete API references. This guide defines the standard format.

## Why This Matters

API documentation in skills serves two purposes:

1. **Claude's context** — When the skill triggers, Claude reads the reference to understand how to call the API correctly without trial and error
2. **Institutional memory** — Quirks, undocumented behavior, and gotchas get captured once and benefit everyone

## Standard API Reference Structure

Create `references/api-reference.md` in the skill directory:

````markdown
# {Service Name} API Reference

## Base URL

`https://api.example.com/v1/`

## Authentication

- Method: Bearer token / API key header / OAuth2
- Header: `Authorization: Bearer {token}` or `X-API-Key: {key}`
- Token lifetime: {duration}
- Rate limit: {requests/minute}
- Note any quirks (e.g., "No 'Bearer' prefix — just the raw key")

## Pagination

- Style: cursor-based / offset / page number
- Page size: {default} (max {max})
- Cursor field: `next_cursor` / `offset` / `page`
- Example: `GET /devices?limit=50&cursor=abc123`

## Common Endpoints

### GET /resource

**Purpose:** List or search resources
**Parameters:**
| Param | Type | Required | Notes |
|-------|------|----------|-------|
| `limit` | int | No | Default 50, max 100 |
| `cursor` | string | No | From previous response |
| `filter` | string | No | Query syntax: `field:value` |

**Response:**

```json
{
  "data": [...],
  "next_cursor": "abc123",
  "total_count": 154
}
```
````

**Quirks:**

- total_count is approximate above 10,000
- Empty results return 200 with empty array, not 404

### POST /resource

**Purpose:** Create a resource
**Body:**

```json
{
  "name": "required",
  "type": "required — enum: typeA, typeB",
  "config": "optional object"
}
```

**Response:** 201 with created resource
**Quirks:**

- Duplicate names return 409, not 400
- Config object is validated asynchronously — creation succeeds but resource may fail later

## Error Codes

| Code | Meaning      | Action                             |
| ---- | ------------ | ---------------------------------- |
| 400  | Bad request  | Check payload against schema       |
| 401  | Auth failed  | Re-prompt for credentials          |
| 403  | Forbidden    | Check scope/permissions            |
| 404  | Not found    | Verify resource ID                 |
| 429  | Rate limited | Back off, retry after header value |
| 500  | Server error | Retry once, then report            |

## Known Quirks & Gotchas

- [Document EVERY undocumented behavior, inconsistency, or surprise]
- [Include the date you discovered each quirk]
- [Note if the vendor has acknowledged it]

## Rate Limits & Throttling

- Requests per minute: {N}
- Burst allowance: {N}
- Throttle response: 429 with `Retry-After` header
- Best practice: Add 100ms delay between sequential calls

## Webhook Support (if applicable)

- Endpoint configuration
- Payload format
- Signature verification method
- Retry behavior

```

## What to Document

### Always Document
- Auth method and any non-obvious header format
- Pagination style and page size limits
- Error codes and what they actually mean (not just what the docs say)
- Rate limits (documented AND observed)
- Any field that behaves differently than its name suggests
- Date/time formats used (ISO 8601? Unix epoch? Something custom?)
- Null vs missing field behavior
- Array fields that are sometimes strings (yes, this happens)

### Document When Discovered
- **Quirks:** API returns 200 for errors, pagination off-by-one, fields that change type
- **Undocumented endpoints:** Discovered via browser dev tools or API exploration
- **Deprecated features:** Still working but marked for removal
- **Vendor bugs:** With dates, workarounds, and whether a support ticket was filed
- **Performance characteristics:** Slow endpoints, large responses, timeout-prone queries

### Community & Vendor Notes

When researching an API, check:
- Official API documentation
- Official changelogs and migration guides
- GitHub issues on the vendor's SDK repos
- Stack Overflow and developer forums
- Reddit communities
- Vendor's community forums / support portal
- Swagger/OpenAPI spec (if available — fetch and save locally)

Document the source for each quirk so future sessions can verify if it's still relevant.

## Example: Deep Instinct API (from di-shepherd)

The DI-Shepherd skill's API reference is a good model. Key elements:

1. **Auth quirk documented:** "Authorization header uses raw key, NO 'Bearer' prefix"
2. **Multi-tenant vulnerability documented:** "FULL_ACCESS key can see all 153 MSPs — CVSS 9.9 — hard-code MSP ID 1003"
3. **Pagination documented:** "Cursor-based, 50 items per page, cursor in response body"
4. **Swagger spec saved:** Full endpoint reference in `references/di-api-swagger-reference.md`

## Example: HappyFox API (from icci-happyfox)

1. **MCP abstraction:** API access is through MCP tools, not direct HTTP
2. **Known bugs cataloged:** BUG-001 through BUG-009 with workarounds
3. **Instance cache:** Categories, priorities, staff, statuses cached locally to avoid MCP calls
4. **HTML rendering limitation:** Staff updates don't render HTML — use plain text with CAPS headers

## Maintaining API References

- Update after every session where new behavior is discovered
- Add date stamps to quirk entries
- Mark resolved quirks as such (don't delete — the history is valuable)
- Check vendor changelogs when updating skills
- If the API has a version header, note which version the reference was built against
```
