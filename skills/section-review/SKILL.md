---
name: section-review
description: First-principles review of a named codebase or product section, calibrated to project stage. Use when a module, service, workflow, page, subsystem, or architecture area needs an evidence-backed general quality assessment and no narrower specialist skill owns the primary question. Route API, test, UX, accessibility, dependency, or release-readiness work to the dedicated skill first.
user-invocable: true
argument-hint: "[section name]"
---

Read `../_house-style/house-style.md`, `../_house-style/finding-contract.md`, and `references/rating-rubric.md` before writing the review.

## Role boundary

Review one named section as a general systems reviewer. Do not absorb specialist work:

- API contracts and consumer ergonomics → `/api-review`
- Test-suite confidence → `/test-audit`
- Dependency portfolio → `/dep-audit`
- Workflow and mental model → `/ux-designer`
- Visual hierarchy and components → `/ui-designer`
- Accessibility conformance → `/a11y-audit`
- Release readiness → `/ship` or `/platform-ship`
- Quantified debt portfolio → `/tech-debt`

If one specialist owns the primary question, route there. Use this skill when the section crosses concerns or needs a bounded first-principles quality verdict.

## Workflow

### 1. Lock stage and scope

State:

- stage: prototype / active development / production / legacy
- exact section boundary
- adjacent dependencies required to understand it
- evidence available and inaccessible

Narrow broad requests to the smallest useful section. Do not review the whole repository by default.

### 2. Define the job

State in one sentence what the section must accomplish and for whom. Name the simplest correct shape if built from scratch. Separate real constraints from inherited implementation choices.

### 3. Walk the public behavior

Use the section as its consumer would:

- UI: walk the primary path and recovery path
- API or library: trace the public contract from input to output
- service: trace one request or job end to end
- infrastructure: trace build, deploy, failure, and recovery

If runtime access is unavailable, inspect the contract statically and label behavior `Not verified`.

### 4. Inspect only relevant dimensions

Do not force every category into the report.

- **Correctness:** invalid states, boundary inputs, silent failure, data loss
- **Boundaries:** ownership, coupling, source of truth, duplicated state
- **Failure behavior:** dependency outage, retry, partial success, recovery
- **Security:** trust boundaries, authorization, exposure, unsafe input
- **Scale and efficiency:** dominant cost, unbounded work, first bottleneck
- **Testability:** critical unproved behavior and false confidence
- **Maintainability:** cognitive load, hidden invariants, bus factor, dependency risk

Route a deep domain audit to the specialist instead of recreating it here.

### 5. Form findings

Use the shared finding contract. A finding needs evidence, trigger, impact, smallest fix, confidence, and verification. Missing evidence lowers confidence; it does not raise severity.

Use `Disaster waiting to happen` only when the trigger and failure mechanism are evidenced. State reachability and compensating controls.

### 6. Rate the section

Use `references/rating-rubric.md` for the selected section type.

- **Score:** 0–10
- **Verdict:** Revolutionary / Standard / Bad / Disaster
- **Confidence:** High / Medium / Low

Any score above 5 requires concrete evidence of quality beyond basic operation.

### 7. Produce three next moves

Give exactly three dependency-ordered moves:

1. immediate correction
2. structural improvement
3. subtraction or differentiated investment

If fewer than three changes are justified, say so instead of inventing work.

## Output format

### Worst findings

Critical and high findings first. Use the shared finding contract.

### Section rating

| Section | Type | Stage | Score | Verdict | Confidence | Evidence |
|---|---|---|---:|---|---|---|

### Public-behavior walkthrough

What was observed, what was only inferred, and where the consumer path failed or succeeded.

### First-principles judgment

Core job, simplest correct shape, real constraints, and accidental complexity. End with **Keep**, **Fix**, or **Cut**.

### Relevant system findings

Only the dimensions that materially apply. Do not emit empty sections.

### What should be deleted

Name exact low-value code, abstractions, states, controls, tests, or dependencies. If deletion is not supported, omit this section.

### Devil's advocate

For the three strongest findings, state what evidence would change the conclusion and which missing constraint might justify the current approach.

### Next moves

Exactly three dependency-ordered actions, or fewer when the evidence supports fewer.

### Forward plan

Use only the stages needed: Foundation, Core changes, Stabilization, Hardening, Optimization. Each item needs an action, evidence-backed reason, success signal, dependency, and rollback for hard-to-reverse work.

### What I did not verify

Name the surface, why it was not verified, and the evidence needed to close the gap.
