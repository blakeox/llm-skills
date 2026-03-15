# DI-Shepherd

**Watching over the flock so the Master Bitherders don't have to.**

> *In memory of Molly Jean (2007–2022), who wished to never be forgotten.*
> *She missed 16 by a few days. She would have loved AI.*

DI-Shepherd is ICCI's Deep Instinct endpoint security management skill — built for the ICCI team to report on, remediate, and keep watch over every endpoint across the client base through the Deep Instinct MSP console.

## Capabilities

### The Shepherd's Ledger (Reporting)
- Fleet health reports (device counts, connectivity, agent/brain versions by tenant)
- Threat summaries (events by type, severity, action taken, MITRE ATT&CK categories)
- Policy compliance audits
- Stale device detection
- Version drift analysis
- ICCI-branded PDF reports via WeasyPrint

### The Shepherd's Crook (Remediation)
- Close/reopen/archive events
- Network isolation and release
- Remote file deletion and process termination
- Device enable/disable
- Full audit logging of all remediation actions

### The Shepherd's Eye (Watchover)
- Stale device monitoring
- Open threat tracking
- Version drift alerts
- Agent health checks
- Policy gap detection

## Setup

1. **Clone to skills directory:**
   ```bash
   cp -r . ~/.claude/skills/di-shepherd/
   ```

2. **API key:** Provide at session start or set `DI_API_KEY` environment variable. Key requires READ_AND_REMEDIATION permission level.

3. **Report branding:** Clone the report branding repo:
   ```bash
   gh repo clone icci/icci-report-branding ~/Documents/GitHub/icci-report-branding
   ```

4. **Create output directories:**
   ```bash
   mkdir -p ~/Documents/claude-code/di-shepherd/{reports,cache,exports}
   ```

## API

- **Console:** https://msp360.customers.deepinstinctweb.com/app/
- **API Base:** https://msp360.customers.deepinstinctweb.com/api/v1/
- **Auth:** `Authorization: <API_KEY>` header (no Bearer prefix)
- **Swagger:** https://msp360.customers.deepinstinctweb.com/api/v1/

## Repository Rules

- This repository MUST remain **private** at all times
- Verify before every push: `gh repo view icci/di-shepherd --json isPrivate -q '.isPrivate'`
- Never commit API keys or client-specific data
- All changes get a conventional commit with shepherd emoji prefix

## File Structure

```
di-shepherd/
├── SKILL.md                        # Main skill file (Claude reads this)
├── README.md                       # This file
├── LICENSE.txt                     # Proprietary — ICCI LLC Internal Use Only
├── CHANGELOG.md                    # Version history
├── LESSONS-LEARNED.md              # Append-only institutional memory
├── .gitignore                      # Secrets, cache, OS files excluded
├── references/
│   ├── di-api-reference.md         # Complete API endpoint documentation
│   ├── branding-config.md          # Report branding repo paths and fallback values
│   └── report-fallback.md          # Minimal report format if branding repo unavailable
├── scripts/                        # Helper scripts (populated during usage)
├── assets/                         # Logos, images (populated during usage)
└── evals/
    └── evals.json                  # Skill evaluation test cases
```

## Lessons Learned

See [LESSONS-LEARNED.md](LESSONS-LEARNED.md) for institutional memory accumulated during real usage.

---

*ICCI, LLC — Secure. Governed. Operational.*
*Veteran-owned MSP | 30+ years | Ann Arbor & Brighton, Michigan*
