# Shared release-gate contract

Apply this contract to generic and provider-specific ship gates.

## Scope and authority

- A release gate is read-only unless the user separately asks to deploy, publish, submit, promote, merge, or push.
- Never retrieve or print secret values. Report only the secret type, location, and a redacted fingerprint when needed.
- If a real credential is exposed, block the release and require revocation or rotation plus history/log cleanup without reproducing the value.

## Evidence ledger

Identify the exact immutable revision or artifact and the exact account, project, region, and environment. For every applicable gate record:

- **Status:** Verified / Failed / Unknown / Not applicable
- **Evidence:** Command, artifact, source, and observation time
- **Scope:** Local / CI / provider control plane / live runtime

`Unknown` is not a pass. A `PASS` requires verified evidence for every applicable blocking check. Use `INDETERMINATE` when required evidence is inaccessible and `BLOCK` when a check fails.

## Rollout and kill switch

Every release recommendation must state:

- how traffic or behavior is disabled safely
- what happens to in-flight work and stored data on failure
- rollback or forward-recovery limits, especially after migrations
- telemetry and logs that detect failure
- the responsible owner or role and notification path, if known

Do not invent owners, alerts, or rollback capability. Mark them `Unknown` and block when they are required.

## Required ending

End with:

1. `PASS`, `BLOCK`, or `INDETERMINATE`
2. blocking evidence in dependency order
3. rollback and kill-switch reality
4. what was verified
5. what was not verified and what evidence would close each gap
