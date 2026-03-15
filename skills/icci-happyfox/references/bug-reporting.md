# MCP Bug Reporting — GitHub Workflow

## Issue Tracker

- **Repo**: `icci/happy-fox-mcp`
- **List issues**: `gh issue list -R icci/happy-fox-mcp`
- **Create issue**: `gh issue create -R icci/happy-fox-mcp --title "..." --body "..." --label "bug"`
- **Close issue**: `gh issue close N -R icci/happy-fox-mcp -c "Fixed — verified via MCP on YYYY-MM-DD"`

## When to File

File a GitHub issue when an MCP tool:

- Returns an unexpected HTTP error (400, 405, 500)
- Silently drops fields from payloads
- Parses valid input incorrectly
- Returns results that don't match the query
- Behaves differently than its tool description suggests

Do NOT file for:

- User error (wrong parameters, missing required fields)
- HappyFox API limitations that the MCP correctly passes through
- Features that don't exist yet (use `mcp-feature-requests.md` instead)

## Before Filing

1. **Reproduce** — try at least 2 parameter variations to confirm it's not user error
2. **Read the source** — clone/read `icci/happy-fox-mcp` to find the root cause:
   ```bash
   gh repo clone icci/happy-fox-mcp /tmp/happy-fox-mcp
   ```
3. **Identify** the exact file, function, and line causing the issue

## Issue Template

Every issue filed should include these sections:

```markdown
## Description

One-sentence summary of what's broken.

## Steps to Reproduce

1. Call `happyfox_tool_name` with parameters...
2. Observe error...

## Expected Behavior

What should happen.

## Actual Behavior

What actually happens (include exact error messages).

## Root Cause Analysis

- **File**: `src/happyfox/domains/example.ts` ~line N
- **Code**: (paste the problematic code block)
- **Why it fails**: (explain the logic error)

## Suggested Fix

(Code snippet showing the fix — keep it minimal and targeted)

## Claude Code Prompt for Blake
```

(A ready-to-paste prompt Blake can give Claude Code to implement the fix)

```

## Environment
- MCP connector on Cloudflare Worker
- Discovered: YYYY-MM-DD
```

## Key Source Files (as of 2026-03-10)

These are the files most likely to contain bugs. Read them when investigating:

| File                                    | Contains                                                                                |
| --------------------------------------- | --------------------------------------------------------------------------------------- |
| `src/happyfox/domains/tickets.ts`       | Ticket CRUD, `performTicketAction`, `MANAGE_PAYLOAD_ALLOWLIST`, `sanitizeManagePayload` |
| `src/happyfox/domains/contacts.ts`      | Contact search, create, upsert, `listContacts`                                          |
| `src/happyfox/javascriptUtils.ts`       | JS code validation, `looksLikeAsyncArrowFunction`, `loadAsyncArrowFunction`             |
| `src/happyfox/core.ts`                  | HTTP client, request routing, auth                                                      |
| `src/tools/ticketTools.ts`              | Tool registration for ticket operations                                                 |
| `src/tools/contactTools.ts`             | Tool registration for contact operations                                                |
| `src/tools/codemode/codemodeExecute.ts` | Sandbox execution for `happyfox_execute`                                                |

## Closing Issues

When Blake deploys a fix:

1. Re-test the MCP tool that was broken
2. If fixed: `gh issue close N -R icci/happy-fox-mcp -c "Verified fixed — tested via MCP on YYYY-MM-DD"`
3. Move the bug from "Active" to "Resolved" in `references/known-issues.md`
4. Update `references/mcp-tools.md` if a tool's status changed (e.g., Broken → Working)
