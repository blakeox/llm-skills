# Changelog

## v1.0 — 2026-03-08

**Initial release.** Built from Deep Instinct Swagger API spec research and ICCI skill conventions.

- SKILL.md with three-pillar architecture (Ledger/Crook/Eye)
- Complete API reference (105+ endpoints documented from tenant Swagger spec)
- Branding config integrated with icci-report-branding repo
- Report fallback format for offline generation
- Evaluation test cases (3 scenarios)
- Safety guardrails: privacy checks, remediation confirmation, audit logging
- GitHub repo: `icci/di-shepherd` (private)

### Contributors
- Aaron Salsitz (ICCI, LLC)
- Claude (Anthropic)

## v1.1 — 2026-03-08

**First remediation session.** Full fleet triage, event cleanup, policy hardening, and configuration audit.

### Remediation (32 operations logged)
- Allow-listed PIconStartup + 4 infrastructure tools across all Windows policies
- Closed 60+ false positive event hashes (VSS, PUA, Dual Use, Office macros, TurboTax, etc.)
- Archived 39 stale REMOVED/DEACTIVATED devices
- Created Praxis Properties policy (10627) with Tenant Pro 7 entries
- Cleaned MKM policy of orphaned Praxis/TP7 entries from previous tech

### Policy Hardening
- Enabled `automatic_brain_upgrade` on all 9 policies (was false on all)
- Hardened SC Server: 6 protections DETECT→PREVENT, weekly scan enabled
- Enabled weekly scheduled scan on JacksonFamilyNC

### Security
- Discovered and documented multi-tenant isolation vulnerability (CVSS 9.9)
- Generated 13-page ICCI-branded disclosure report
- Dual-verification guardrails for all FULL_ACCESS write operations

### Skill Improvements
- Added comprehensive Swagger API reference (`references/di-api-swagger-reference.md`)
- Updated LESSONS-LEARNED.md with API gotchas and policy management patterns
- Generated 5 PowerShell cleanup scripts for ScreenConnect deployment
- Full audit log: `audit-log.jsonl` (32 entries)
