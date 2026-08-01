---
name: reliability-review
description: Evidence-backed reliability and operability review for services, distributed workflows, queues, scheduled jobs, integrations, and critical user paths. Use when evaluating timeouts, retries, backpressure, partial failure, degradation, alerting, recovery, capacity limits, or silent data and processing failures under real production conditions.
user-invocable: true
argument-hint: "[service, job, workflow, incident-prone path, or architecture area]"
---

Read `../_house-style/house-style.md`, `../_house-style/finding-contract.md`, and `../_house-style/active-testing.md` before starting.

## Boundary

Own failure handling, degradation, recovery, capacity safety, and operational detection. Use `/paranoid-review` for broad code correctness, `/postmortem` after an incident, `/migration-review` for transition safety, and `/platform-ship` for provider release evidence.

Remain read-only unless the user explicitly requests fixes. Do not generate load, interrupt dependencies, drain queues, or exercise failover against shared or production systems without exact authorization.

## Review procedure

1. Lock the target, revision, environment, traffic assumptions, and service-level objective if one exists.
2. Trace the request, job, or event lifecycle across dependencies and stored state.
3. Identify bounded and unbounded work, timeouts, retries, concurrency, queue growth, fan-out, and resource ceilings.
4. Model dependency slowdown, outage, malformed response, duplicate delivery, restart, partial success, and recovery.
5. Verify degradation behavior, idempotency, backpressure, reconciliation, and operator controls.
6. Check whether telemetry detects user impact, cause, scope, and recovery—not merely component activity.
7. Separate measured behavior from source-backed expectations and untested hypotheses.

## Required failure analysis

- Most likely failure mode
- Most expensive failure mode
- Silent failure mode

For each, state trigger, propagation, detection, containment, recovery, and residual risk. Do not invent traffic, latency, capacity, or incident frequency.

## Output

### Operational path

Dependencies, state, queues, timeouts, retries, control points, and observability.

### Findings

Use the shared finding contract. Prioritize corruption, silent loss, cascading failure, retry amplification, unbounded work, and unrehearsed recovery.

### Degradation and recovery

Expected degraded mode, kill switch, in-flight behavior, reconciliation, recovery proof, and responsible role when known.

### Evidence gaps

Name unmeasured runtime behavior and the smallest contained test that would establish it.

### Verdict

- **OPERATIONALLY SOUND** — material failure paths are bounded, detectable, and recoverable with evidence
- **NEEDS RESILIENCE WORK** — the design is viable but required controls are incomplete
- **INCIDENT RISK** — a confirmed material failure path is unbounded, silent, or unrecoverable
- **INDETERMINATE** — required runtime or operational evidence is unavailable

End with `What I did not verify`.
