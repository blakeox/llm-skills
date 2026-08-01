---
name: ship
description: Evidence-based pre-flight release gate that passes or blocks a branch or pull request. Use immediately before merge, deployment, or release to verify branch state, debug residue, secrets, tests, CI, review hygiene, migrations, observability, rollback readiness, and explicit ownership of remaining risk.
user-invocable: true
argument-hint: "[branch name or PR number]"
---

Read `../_house-style/house-style.md` and `../_house-style/release-gate.md` before starting.

This skill owns repository, branch, CI, review, migration, and generic release-control readiness. Use `/platform-ship` for provider control-plane and runtime evidence, then synthesize both gates. Neither gate may borrow evidence from the other.

## Anchor phrases

- The gate has no feelings. It passes or it blocks.
- "We'll fix it after deploy" is how you get paged at 2am.
- If there's no rollback plan, you're not shipping — you're gambling.
- A branch that's "almost ready" is not ready.

## Domain-specific examples

**Gate result — wrong way:**

"The branch looks mostly ready to ship. There are a couple of minor things that could be cleaned up but overall it should be fine to merge. The tests pass and the code looks reasonable."

**Gate result — right way:**

"**BLOCK.** 3 failures: (1) `src/utils/debug.ts:14` — `console.log('DEBUG:', payload)` left in production code. (2) `app/config.ts:3` — hardcoded payment-provider API key `[redacted]` committed to source. Revoke or rotate it and clean retained history without reproducing the value. (3) No tests for the new `/api/orders` endpoint — the only coverage is a happy-path integration test that doesn't verify auth, validation, or error responses. Fix all 3 before this ships."

## First principles

Before the checklist: **should this ship at all?**

- What does this change do? One sentence.
- Does the PR description match the code? If not, which is wrong?

## The gate checklist

Every item is pass/fail. Cite file:line for failures.

### 1. No debug artifacts
- [ ] No `console.log/debug`, `debugger`, `print()` in non-logging code
- [ ] No `TODO/FIXME/HACK/XXX` introduced in this diff
- [ ] No commented-out code added
- [ ] No `.only`, `.skip`, or hardcoded test bypasses

### 2. No secrets
- [ ] No API keys, tokens, passwords, credentials
- [ ] No `.env` files committed
- [ ] No hardcoded prod/internal URLs
- [ ] No PII in test fixtures

### 3. Tests
- [ ] Tests exist for changed code
- [ ] Tests pass (run them)
- [ ] New paths have coverage beyond happy path
- [ ] No tests deleted or weakened to make build pass

### 4. Code hygiene
- [ ] No merge conflict markers
- [ ] Branch is up to date with target
- [ ] No large binaries added (>1MB)
- [ ] No dependency changes without justification

### 5. PR hygiene
- [ ] Title under 70 chars, clear
- [ ] Description matches actual changes
- [ ] Bug fixes explain root cause
- [ ] Features describe user-facing behavior

### 6. Rollback readiness
- [ ] Revertable with single commit?
- [ ] DB migrations reversible?
- [ ] Breaking API changes have compatibility plan?
- [ ] Blast radius documented?

## Adversarial check

- What if this ships and the feature is broken?
- What if performance is 10x worse than expected?
- What if a user hits an edge case in the first 5 minutes?
- Is there monitoring that would catch it, or would it be silent?

## Output format

### Pre-flight result

**PASS**, **BLOCK**, or **INDETERMINATE** under the shared release-gate contract.

### Checklist results
Each section pass/fail. Failures: file:line and what's wrong.

### Ship blockers *(only if BLOCK)*
Numbered. File:line, what's wrong, the fix.

### Rollback plan
How to revert. If no clean path, that's a finding.

### Devil's advocate
For any borderline calls: what might justify shipping anyway? (Usually nothing.)

### What I verified / What I didn't check

### Proposed ship command *(only if PASS and requested)*
Exact git commands for the user to evaluate. Do not execute merge, push, deploy, publish, or release actions unless separately and explicitly requested.
