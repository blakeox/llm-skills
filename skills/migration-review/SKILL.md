---
name: migration-review
description: Evidence-backed transition review for database schemas, stored data, APIs, events, queues, files, and cross-service contracts. Use when a change requires staged rollout, backfill, mixed-version operation, expand-contract sequencing, compatibility validation, data preservation, rollback, or forward recovery while systems remain live.
user-invocable: true
argument-hint: "[migration plan, schema change, backfill, API transition, or rollout diff]"
---

Read `../_house-style/house-style.md`, `../_house-style/finding-contract.md`, and `../_house-style/active-testing.md` before starting.

## Boundary

Own transition safety and deploy sequencing. Use `/plan-eng-review` for the wider architecture, `/api-review` for steady-state contract quality, `/platform-ship` for provider release evidence, and `/execute` only after the transition plan is settled.

Remain read-only unless the user explicitly requests implementation. Never run a migration, backfill, cleanup, or production query without exact environment and write authorization.

## Review procedure

1. Identify every producer, consumer, schema, stored representation, deployment unit, and environment in the transition.
2. State the current state, target state, invariant to preserve, and irreversible boundary.
3. Build the dependency sequence: expand, deploy compatible readers and writers, migrate or backfill, verify, then contract.
4. Test coexistence of old and new versions, including delayed jobs, retries, caches, replicas, offline clients, and rollback after partial progress.
5. Check idempotency, restartability, batching, throttling, checkpoints, and reconciliation for data movement.
6. Define stop conditions, telemetry, kill switch, rollback limits, and forward-recovery path.
7. Prove destructive cleanup is unreachable until compatibility and data gates pass.

## Required failure analysis

- Most likely: deployment-order or compatibility mismatch
- Most expensive: irreversible corruption, loss, or access-control regression
- Silent: partial backfill, stale reads, dropped events, or divergent representations without detection

For each, state trigger, detection, containment, and recovery.

## Output

### Transition map

Current state, target state, actors, data or contract surfaces, and invariants.

### Dependency-ordered rollout

Explicit expand, coexist, migrate, verify, and contract gates. Avoid calendar estimates.

### Findings

Use the shared finding contract for compatibility, integrity, sequencing, and recovery failures.

### Recovery reality

Kill switch, stop condition, rollback boundary, forward recovery, reconciliation, telemetry, and ownership when known.

### Verdict

- **READY TO STAGE** — transition gates and recovery controls are evidence-backed
- **NEEDS STAGED MIGRATION** — the direction is viable but required sequencing or controls are incomplete
- **UNSAFE TRANSITION** — a confirmed path risks irreversible or material failure
- **INDETERMINATE** — required schema, consumer, data, or environment evidence is unavailable

End with `What I did not verify`.
