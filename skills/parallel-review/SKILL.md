---
name: parallel-review
description: Orchestrate multiple specialist reviews against one target and synthesize a prioritized, deduplicated verdict. Use when a pre-merge review, deep audit, project-health check, post-incident review, test overhaul, design audit, or operational-risk review genuinely needs several independent review skills or subagents.
user-invocable: true
argument-hint: "<mode> <target> — modes: pre-merge | deep-audit | health | post-incident | test | design | operational-risk"
---

Read `../_house-style/house-style.md` and `../_house-style/active-testing.md` before starting.

## What this skill does

You are a review coordinator. You do not review code yourself. You spawn parallel subagents — each running a specialized review skill — wait for all to finish, then synthesize their findings into a single, prioritized, deduplicated report.

## Modes

Parse the first argument to determine the mode. If no mode is given, infer from context or ask.

### `pre-merge` — Before merging a PR or branch

Spawn **three** parallel subagents:

1. **Paranoid reviewer** — Run `/paranoid-review` on the target. Hunt for production killers, race conditions, silent failures, missing error handling.
2. **Dependency auditor** — Run `/dep-audit` on the target. Check for CVEs, abandoned deps, unnecessary deps, license risk.
3. **Ship gate** — Run `/ship` on the target. Pre-flight checklist: debug artifacts, secrets, test coverage, PR hygiene, rollback readiness.

### `deep-audit` — Comprehensive quality review

Spawn **three** parallel subagents:

1. **Section reviewer** — Run `/section-review` on the target. First-principles decomposition, architecture, scalability, security, and testability.
2. **Tech debt assessor** — Run `/tech-debt` on the target. Evidence-backed inventory: recurring cost, incident exposure, blast radius, and fix complexity.
3. **API reviewer** — Run `/api-review` on the target. Consumer-first audit of contracts, error shapes, auth, pagination, idempotency. *Skip this subagent if the target has no API surface — state that you skipped it and why.*

### `health` — Monthly project health check

Spawn **three** parallel subagents:

1. **Dependency auditor** — Run `/dep-audit` on the target.
2. **Tech debt assessor** — Run `/tech-debt` on the target.
3. **Onboarding auditor** — Run `/onboarding-audit` on the target. Zero-knowledge new-developer experience.

### `post-incident` — After an outage or incident

Spawn **three** parallel subagents:

1. **Postmortem investigator** — Run `/postmortem` on the target. Reconstruct the evidence-backed timeline and causal chain.
2. **Retrospective analyst** — Run `/retro` on the target. Git-data-backed analysis of what actually happened.
3. **Paranoid reviewer** — Run `/paranoid-review` on the target. Find related bugs that haven't fired yet.

### `test` — Read-only test suite assessment

Spawn **three read-only** parallel subagents:

1. **Test auditor** — Run `/test-audit` on the target. Measure real confidence vs. false confidence. Classify every test as valuable, decoration, or harmful. Identify critical untested paths.
2. **Coverage diagnostician** — Use `/test-write` in plan-only mode. Identify the highest-risk missing behaviors and specify tests, but do not edit files.
3. **Failure diagnostician** — Use `/test-fix` in diagnosis-only mode. Analyze supplied or safely reproduced failures, but do not edit product or test files.

After synthesis, recommend a sequential mutation phase only if the user asked for changes: run `/test-fix` first, revalidate, then `/test-write`. Never run multiple writers in one shared worktree. Isolated worktrees require an explicit merge protocol.

### `design` — Full UX, UI, and accessibility audit

Spawn **three** parallel subagents:

1. **UX designer** — Run `/ux-designer` on the target. Walk every core flow as a new user. Find friction, dead ends, confusion, broken mental models. Score time-to-value, flow clarity, information architecture, state coverage, recovery.
2. **UI designer** — Run `/ui-designer` on the target. Evaluate visual hierarchy, typography, color, spacing, component consistency, responsiveness. Find design system violations, weak affordances, missing states.
3. **Accessibility auditor** — Run `/a11y-audit` on the target. Audit against WCAG 2.2 AA. Keyboard navigation, screen reader compatibility, color contrast, semantic HTML, form accessibility. Every violation references the specific WCAG criterion.

### `operational-risk` — Security, migration, and reliability pressure

Spawn **three read-only** parallel subagents:

1. **Security reviewer** — Run `/security-review` on the target. Trace reachable exploit and abuse paths across trust boundaries.
2. **Migration reviewer** — Run `/migration-review` on the target. Check mixed-version operation, data invariants, sequencing, and recovery.
3. **Reliability reviewer** — Run `/reliability-review` on the target. Check partial failure, retries, backpressure, observability, and recovery.

Skip a reviewer only when the target has no meaningful surface for that specialty; state the evidence for skipping it.

## Execution rules

1. **Spawn all subagents in a single message.** Do not run them sequentially. The entire point is parallelism.
2. **Each subagent gets the full target path/branch/PR as context.** Pass the user's target argument to each one.
3. **Each subagent must read `../_house-style/house-style.md`** — this is already in each skill's instructions, but verify the subagent follows house style in its output.
4. **Wait for all subagents to complete before synthesizing.** Do not start the synthesis until every subagent has returned.
5. **Do not soften or editorialize subagent findings.** Your job is to deduplicate, prioritize, and structure — not to add diplomacy.
6. **Keep review modes read-only.** Do not let reviewers edit the target, install dependencies, send active production probes, or mutate external systems.

## Synthesis rules

After all subagents return:

### 1. Deduplicate

Multiple reviewers will find the same issue. Merge duplicates into a single finding and credit the reviewers. If reviewers disagree on severity, retain the severity best supported by trigger, impact, reachability, and evidence; note the disagreement.

### 2. Prioritize

Rank all findings by severity:

1. **Critical** — active or imminent severe impact
2. **High** — realistic material failure path
3. **Medium** — compounding quality or operational risk
4. **Low** — contained improvement

Use `Disaster waiting to happen` only as a tag under the shared finding contract.

### 3. Resolve conflicts

If reviewers contradict each other (one says ship, another says block), surface the contradiction explicitly. Do not silently pick a side. Present both arguments and state which has stronger evidence.

## Output format

### Mode and target

State the mode, target, and which subagents were spawned.

### Unified findings

All findings from all reviewers, deduplicated and priority-ordered. Each finding includes:

- **Severity** (Critical / High / Medium / Low)
- **Source** (which reviewer(s) flagged it)
- **File:line** and evidence
- **The fix** — specific, not "add error handling"

### Reviewer verdicts

| Reviewer | Verdict | Key concern |
|---|---|---|
| (name) | (their verdict) | (one-line summary) |

### Conflicts

Where reviewers disagreed. Both sides. Which has stronger evidence.

### Combined verdict

One of:

- **Ship it** — no critical/high findings across all reviewers
- **Fix then ship** — list the blockers, in priority order
- **Rethink** — fundamental problems identified by multiple reviewers
- **Investigate** — (post-incident mode) action items before any code changes

### Top 5 action items

Dependency-ordered. File:line, what to do, why, which reviewer identified it.

### What was checked

Which skills ran, what each covered.

### What was NOT checked

Gaps across all reviewers. If all three reviewers say they didn't check X, that's a blind spot worth highlighting.
