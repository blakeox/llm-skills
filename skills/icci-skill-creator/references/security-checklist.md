# Security Checklist for ICCI Skills

Every ICCI skill must pass this security checklist before shipping.

## 1. Repository Privacy

**Rule:** All ICCI skill repos must be PRIVATE. No exceptions.

**Verification (run before every push):**

```bash
gh repo view icci/{repo-name} --json isPrivate -q '.isPrivate'
```

Must return `true`. If it returns `false` or errors, STOP immediately and warn the user.

**Automation:** The standard `lefthook.yml` includes a `pre-push` hook that runs this check automatically. Every skill repo and the icci-skills monorepo must have lefthook configured.

## 2. Credential Handling

### The Golden Rule

**Never store credentials in skill files.** Not in SKILL.md, not in config/, not in scripts/, not in comments, not "just temporarily". Credentials in git history are effectively permanent — even after removal, they're in the reflog.

### Session-Start Prompt Pattern

Build this into every skill that needs credentials:

```markdown
## Credential Handling

On first use each session:

1. Check environment variable `{SKILL_NAME_UPPER}_API_KEY`
2. If not set, prompt: "This skill needs a {Service Name} API key. Provide it now — it will be held in memory for this session only and never written to disk."
3. Validate with a lightweight API call (e.g., list account info, fetch a single record)
4. If validation fails, report the specific error and ask for a corrected key
5. Store in conversation memory for the remainder of the session
```

### Acceptable Credential Storage

| Method                      | When to Use             |
| --------------------------- | ----------------------- |
| Environment variable        | CI/CD, automation       |
| 1Password CLI reference     | Scripts that need creds |
| Conversation memory         | Interactive sessions    |
| Claude memory (auto-memory) | NEVER for credentials   |
| Skill files                 | NEVER                   |

### Credential Types to Watch For

- API keys and tokens
- OAuth client secrets (client IDs are usually safe)
- Database passwords
- SSH private keys
- Service account JSON files
- Bearer tokens
- Basic auth strings (base64-encoded username:password)

## 3. Secret Scanning

Before committing, scan the skill directory for potential secrets:

```bash
# Check for common secret patterns
grep -rn "api[_-]key\|api[_-]token\|password\|secret\|bearer\|Authorization:" \
  --include="*.md" --include="*.json" --include="*.sh" --include="*.py" \
  /path/to/skill/
```

**Known safe patterns:**

- References to environment variable names (e.g., "set `DI_API_KEY`")
- Placeholder values (e.g., `your-api-key-here`, `<API_KEY>`)
- Documentation about how auth works

**Red flags:**

- Actual key values (long alphanumeric strings)
- Base64-encoded strings that decode to credentials
- Connection strings with embedded passwords
- OAuth tokens (typically `ya29.` prefix for Google)

## 4. .gitignore Requirements

Every skill directory should have entries in the repo's `.gitignore` (or a local `.gitignore`) for:

```gitignore
# Credentials
credentials/*.txt
!credentials/README.md
*.pem
*.key
*.p12

# Runtime artifacts
*.pyc
__pycache__/
.env
.env.*

# OS artifacts
.DS_Store
Thumbs.db
```

## 5. Multi-Tenant Isolation

Skills that access APIs serving multiple tenants (like DI-Shepherd's multi-MSP API) must:

1. Document the tenant isolation boundary
2. Hard-code the ICCI tenant/MSP ID as a constant
3. Never allow dynamic tenant selection without explicit confirmation
4. Log all cross-tenant operations to an audit file
5. Document the vulnerability if the API key has broader access than intended

## 6. Destructive Operation Safety

Every skill that can modify, delete, or overwrite data must implement:

```
1. Count affected items
2. Display count in **BOLD**: "WARNING: This will affect {N} items."
3. List a sample (first 5) of what will be affected
4. Ask for explicit "yes" confirmation
5. Default to CANCEL if user says anything other than "yes"
6. Log the operation (timestamp, action, count, user confirmation)
```

## 7. Input Validation

Skills that accept user input for API calls or shell commands must:

- Sanitize input to prevent injection (SQL, shell, XSS)
- Validate input types and ranges
- Reject suspicious patterns (`;`, `|`, `&&`, `$(`, backticks in shell contexts)
- Use parameterized queries for database operations
- Quote all variables in shell scripts

## 8. Audit Logging

Skills that perform write operations should log to a structured audit file:

```json
{
  "timestamp": "2026-03-13T10:30:00Z",
  "skill": "di-shepherd",
  "action": "close_event",
  "target": "event_id:12345",
  "user": "asalsitz",
  "details": "Closed false positive event for Brighton Law tenant"
}
```

Default log location: `~/Documents/claude-code/{skill-name}/audit-log.jsonl`

## 9. Network Security

- Use HTTPS for all API calls (never HTTP)
- Verify TLS certificates (don't disable verification)
- Document API base URLs in references (don't construct from user input)
- Rate-limit API calls to avoid account lockout or throttling
- Handle API errors gracefully (don't leak error details that include tokens)

## 10. File System Security

- Scripts should be `chmod 700` (owner-only execute)
- Config files with any sensitive data should be `chmod 600`
- Never write to system directories
- Output files go to `~/Documents/claude-code/{skill-name}/`
- Temp files should be cleaned up after use

## Pre-Ship Security Audit

Run through this before marking a skill as ready:

- [ ] `gh repo view` confirms private
- [ ] `grep -rn` finds no embedded credentials
- [ ] `.gitignore` blocks credential files
- [ ] Session-start credential prompt implemented (if needed)
- [ ] Destructive operations have safety gates
- [ ] Input is validated before use in API/shell calls
- [ ] All API calls use HTTPS
- [ ] Audit logging implemented for write operations
- [ ] Scripts have correct permissions
- [ ] No credential in git history (check `git log --all -p | grep -i "api.key\|password\|secret"`)
