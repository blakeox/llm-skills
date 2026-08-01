---
name: platform-ship
description: Evidence-based provider release gate for Apple, AWS, Azure, Cloudflare, Google Cloud, Supabase, and Vercel. Use immediately before a platform deployment, App Store submission, production promotion, or provider configuration change to verify identity, environment, runtime configuration, rollout, observability, and rollback using the matching provider reference.
user-invocable: true
argument-hint: "[provider and release target]"
---

Read `../_house-style/house-style.md` and `../_house-style/release-gate.md` before starting.

## Authority

Remain read-only unless the user separately authorizes deployment, submission, promotion, rollback, or another external mutation. Never infer provider state from repository or local evidence.

## Select provider guidance

Read only the references that match the release surface:

- Apple platforms: `references/apple.md`
- AWS: `references/aws.md`
- Azure: `references/azure.md`
- Cloudflare: `references/cloudflare.md`
- Google Cloud: `references/google-cloud.md`
- Supabase: `references/supabase.md`
- Vercel: `references/vercel.md`

If the release spans providers, read each applicable reference and keep evidence ledgers separate. If the provider is unsupported, apply the shared release contract and mark provider-specific controls `Not verified`.

## Gate procedure

1. Resolve the full immutable revision or artifact, provider, account or project, region, environment, and release mechanism.
2. Inventory code, configuration, identity, secrets or parameters, network, data, and traffic changes.
3. Record each applicable check as `Verified`, `Failed`, `Unknown`, or `Not applicable`, with evidence scope and observation time.
4. Apply the matching provider reference. Do not substitute preview, local, or hosted CI evidence for provider control-plane or live-runtime proof.
5. Check mixed-version behavior, migrations, in-flight work, stored data, and partial rollout.
6. Define the kill switch, rollback or forward-recovery boundary, telemetry, notification path, and responsible role when known.
7. Return `PASS`, `BLOCK`, or `INDETERMINATE` under the shared release contract.

## Output

### Release identity

Provider, target, immutable revision or artifact, account or project, region, environment, and evidence timestamp.

### Evidence ledger

Applicable gates with status, evidence, and scope.

### Provider-specific risks

Findings from the selected reference, using the shared finding contract for material issues.

### Rollout and recovery

Traffic progression, stop condition, kill switch, in-flight behavior, data boundary, telemetry, owner or role, and notification path.

### Verdict

- **PASS** — every applicable blocking check is verified
- **BLOCK** — at least one required check failed
- **INDETERMINATE** — required evidence is unavailable

End with what was verified, what was not verified, and the smallest evidence needed to close each gap.
