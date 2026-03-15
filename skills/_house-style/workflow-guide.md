# Workflow Guide — Blake Oxford LLM Skills

## The skills

| Skill | When to use | Cognitive mode |
|---|---|---|
| `/plan-product-review` | Before deciding what to build | Is this the right thing? |
| `/plan-eng-review` | After product direction is locked | Is the architecture sound? |
| `/section-review` | Reviewing existing code/UI in depth | What's the real quality? |
| `/paranoid-review` | Before merging a branch | Will this survive production? |
| `/ship` | Branch is ready, land it | Pass the gate or fix it |
| `/api-review` | Reviewing API design | Use it, then break it |
| `/dep-audit` | Periodic or before adding deps | Does every dep earn its place? |
| `/tech-debt` | Sprint planning, quarterly review | What's the real cost of carrying this? |
| `/onboarding-audit` | New project setup, periodic check | Can a stranger get this running? |
| `/postmortem` | After an incident | What happened and why did we allow it? |
| `/retro` | End of week/sprint | What actually happened? (git, not vibes) |

## Feature lifecycle

The skills form a pipeline. Each one has a different job at a different stage.

```
Idea
 │
 ▼
/plan-product-review ─── Is this the right thing to build?
 │                        Verdict: Build / Rethink / Don't build
 │
 ▼
/plan-eng-review ──────── Is the architecture sound?
 │                        Verdict: Ready / Needs work / Wrong approach
 │
 ▼
[implement]
 │
 ▼
/paranoid-review ──────── Will this survive production?
 │                        Verdict: Ship / Fix then ship / Rethink
 │
 ▼
/ship ─────────────────── Pre-flight gate
 │                        Verdict: PASS / BLOCK
 │
 ▼
Merged
```

## Periodic audits

These aren't tied to a feature. Run them on a schedule.

| Cadence | Skill | Why |
|---|---|---|
| Weekly | `/retro` | What actually shipped, who did what, what to change |
| Monthly | `/dep-audit` | Catch CVEs, abandoned deps, unnecessary deps |
| Monthly | `/tech-debt` | Track cost trends, reprioritize |
| Quarterly | `/onboarding-audit` | Test the new-developer experience before it rots |
| After any incident | `/postmortem` | Find the process failure, not just the code failure |

## Deep dives

Use these when you need focused analysis on a specific area.

| Trigger | Skill |
|---|---|
| "This section feels wrong" | `/section-review [section]` |
| "Is our API well-designed?" | `/api-review [routes]` |
| "We keep having bugs in X" | `/section-review [X]` then `/tech-debt [X]` |
| "New hire couldn't get set up" | `/onboarding-audit` |

## Combining skills

Skills are more powerful in sequence:

- **Product → Eng → Implement → Review → Ship** — the full feature lifecycle
- **Section review → Tech debt** — find what's wrong, then quantify the cost
- **Dep audit → Paranoid review** — audit deps, then review the code that uses them
- **Postmortem → Retro** — investigate the incident, then zoom out to the week
- **Onboarding audit → Tech debt** — friction points often reveal structural debt

## When NOT to use a skill

- Don't use `/plan-product-review` when the product direction is already locked and validated. It will question decisions that have already been made.
- Don't use `/paranoid-review` on a prototype. Use `/section-review` with prototype stage instead.
- Don't use `/ship` before `/paranoid-review`. The gate checks hygiene, not correctness.
- Don't use `/retro` mid-sprint for planning. It looks backward, not forward.
- Don't use `/postmortem` for near-misses that didn't impact users. Use `/paranoid-review` on the code instead.
