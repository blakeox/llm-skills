---
name: security-review
description: Evidence-backed security review that traces concrete exploit and abuse paths across trust boundaries. Use when reviewing authentication, authorization, admin actions, uploads, parsers, webhooks, secrets, sensitive data, exposed APIs, background jobs, or other surfaces where an attacker or careless operator could gain access, escalate privilege, alter data, or cause material harm.
user-invocable: true
argument-hint: "[branch, files, endpoint, workflow, or trust boundary]"
---

Read `../_house-style/house-style.md`, `../_house-style/finding-contract.md`, and `../_house-style/active-testing.md` before starting.

## Boundary

Own security reachability, exploitability, trust boundaries, and abuse resistance. Use `/api-review` for consumer-facing contract quality, `/dep-audit` for dependency portfolio health, and `/paranoid-review` for broad production correctness.

Remain read-only unless the user explicitly requests fixes. Never probe a live or external target without authorization for that exact active test.

## Review procedure

1. Lock the target, revision, environment, and evidence scope.
2. Map identities, roles, entry points, assets, data classifications, privilege transitions, and external dependencies.
3. Trace realistic attack paths from reachable input to protected action or asset.
4. Check existing controls and whether they operate at the correct boundary.
5. Seek evidence that disproves each suspected path before reporting it.
6. Use safe static analysis or local fixtures by default. Mark runtime exploitability `Not verified` when active proof is unsafe or unavailable.
7. Report only reachable, material findings using the shared finding contract.

## Required checks

- Authentication establishment, session lifecycle, and credential recovery
- Object- and action-level authorization, tenant isolation, and admin boundaries
- Input handling, injection, unsafe deserialization, path traversal, and file processing
- SSRF, redirects, callbacks, webhooks, and outbound-request controls
- Secret handling, logging, error disclosure, and sensitive-data retention
- Replay, idempotency, rate limits, enumeration, resource exhaustion, and abuse economics
- Background jobs, queues, race conditions, approval bypass, and fail-open behavior
- Audit evidence for privileged or irreversible actions

Do not list generic checklist risks without a trigger, reachable path, asset, impact, and control analysis.

## Output

### Trust-boundary map

Actors, entry points, assets, privilege transitions, and assumptions.

### Confirmed findings

Order by severity. Include the full shared finding contract and an attack sequence for each material issue.

### Unconfirmed hypotheses

State missing evidence and the smallest safe proof step. Do not promote hypotheses into findings.

### Control strengths

Name controls that materially break attack paths, with evidence.

### Verdict

- **FIX BEFORE EXPOSURE** — a reachable material security failure is confirmed
- **NO CONFIRMED MATERIAL FINDING** — reviewed paths have no confirmed material issue; this is not a universal safety claim
- **INDETERMINATE** — critical reachability or control evidence is unavailable

End with `What I did not verify`.
