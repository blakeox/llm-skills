---
name: postmortem
description: Evidence-backed, blameless incident postmortem. Use after an outage, security event, failed deployment, data incident, or material near miss to reconstruct the timeline from git, deploys, metrics, and logs; identify technical and control failures; and define owned corrective actions.
user-invocable: true
argument-hint: "[incident description, PR, or commit]"
---

Read `../_house-style/house-style.md` before starting.

## Anchor phrases

- "Human error" is not a root cause. Processes exist to catch human error. If they didn't, the process failed.
- The comfortable root cause is the one that doesn't implicate the process. Push past it.
- "We were moving fast" is not an explanation. Moving fast without catching bugs is moving forward and backward at the same time.
- Every incident that surprises you is a monitoring failure on top of a code failure.

## Domain-specific examples

**Root cause — wrong way:**

"The incident was caused by a developer accidentally dropping a column that was still in use. This was an unfortunate oversight. Going forward, we should be more careful with migrations."

**Root cause — right way:**

"The column was dropped in migration `20240301_remove_legacy_fields.rb` and deployed at 14:32 UTC. The reporting service still reads it at `app/queries/revenue_report.rb:67`. The supported contributing conditions are: no cross-service dependency map, no downstream-consumer migration test, and a review scope limited to the migrating service. The corrective control is automated cross-service schema compatibility validation before deployment."

## Investigation process

### 1. Reconstruct timeline from evidence
Git history, deploy logs, monitoring. Not from memory. Include the **detection gap** (deploy → detection).

### 2. Build an evidence-backed causal chain
Continue until the actionable contributing conditions are supported. Do not force exactly five layers or predetermine a process-only root cause. Technical, design, control, organizational, and external causes can coexist. State confidence for every causal link.

### 3. Question the process
For each link: was there a review? Tests? Monitoring? Rollback plan? Which role owned the decision or control? Separate decision ownership from personal blame.

### 4. Challenge the narrative
- "We didn't have time to test" → What was prioritized instead?
- "Edge case" → How many users hit it?
- "Requirements were unclear" → Who was responsible for clarifying?
- "Worked in staging" → What's different about production?

### 5. Evaluate the fix
Root cause or symptom? Would recurrence be prevented? Similar patterns elsewhere?

## Output format

### Incident summary
One paragraph: what happened, who or what was affected, observed duration, and measured impact. Mark unavailable data instead of estimating it.

### Timeline
Chronological table: timestamp, event, source. Detection gap prominently displayed.

### Causal chain
Contributing conditions with evidence, confidence, and the point where evidence runs out.

### Process failures
What should have caught this: review, test, monitoring, docs, communication gaps. Why each failed.

### Fix assessment
Symptom or root cause? Similar vulnerabilities elsewhere?

### Devil's advocate
Could the team's narrative be right? What context might justify the decisions that led here?

### Action items
Specific and verifiable. Name the responsible role when known; do not invent a person or deadline. Sequence by dependency and state the verification condition.

### Recurrence risk

Likelihood, impact, controls, and confidence. Avoid fake numeric precision.

### What I didn't investigate

Missing evidence, inaccessible systems, redacted sensitive data, and what would close each gap.
