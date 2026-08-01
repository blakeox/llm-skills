---
name: tech-debt
description: Systematic technical-debt inventory with an operational cost model. Use when reviewing a codebase, directory, subsystem, or backlog to quantify recurring cost, incident likelihood, blast radius, remediation effort, dependency order, and disasters waiting to happen instead of producing a vague cleanup list.
user-invocable: true
argument-hint: "[codebase, directory, or specific area]"
---

Read `../_house-style/house-style.md` before starting.

## Anchor phrases

- Tech debt is not a feeling. It's a measurable cost.
- "This code is messy" is not a finding. Name the evidenced recurring drag, failure path, blast radius, and complexity of remediation.
- The most expensive debt is the debt you don't know you're paying.
- Some debt is cheap to carry. The inventory tells you which.

## Domain-specific examples

**Debt item — wrong way:**

"The payment service could use some refactoring. The code is a bit messy and hard to follow. We should clean it up when we have time."

**Debt item — right way:**

"**Payment service god class**
- **Location:** `app/services/payment_service.rb` (847 lines)
- **Recurring cost:** Source-backed: 14 merge conflicts in the last quarter and 3 active consumers. Time cost is unavailable.
- **Incident risk:** High. The `charge_customer` method (line 234-298) has no test coverage for the concurrent charge path. Race condition: two requests can double-debit. See incident #47.
- **Blast radius:** User-facing. Incorrect charges, refund manual work, customer trust damage.
- **Compounding:** Yes. Every new payment feature adds to this file. It was 400 lines 6 months ago.
- **Fix complexity:** High. Extract explicit service boundaries and add a concurrency control after regression coverage exists.
- **Fix risk:** Medium. Payment code. Needs integration tests against Stripe test mode before and after.
- **If you don't fix it:** Merge conflict frequency and concurrent-charge exposure continue. Incident timing is unavailable."

## Debt sources to scan

Structural, data/schema, test, dependency, infrastructure, documentation, API debt.

## Per-item measurement

- **Recurring cost** (measured or source-backed when available; otherwise unavailable)
- **Incident risk** (High/Medium/Low + specific scenario)
- **Blast radius** (function → page → service → system → user data)
- **Compounding?** (getting worse as more code builds on it?)
- **Fix complexity** (Low/Medium/High, with dependencies)
- **Fix risk** (could the refactor introduce bugs?)

## Output format

### Debt summary

| Total items | Critical/high items | Measured recurring cost | Highest priority |
|---|---|---|---|

### Inventory (priority order)
Each item: location, evidence class, recurring cost, incident risk, blast radius, compounding, fix complexity, fix risk, dependencies, recommended fix, and cost of carrying. Never fill missing measurements with guesses.

### Cost/benefit
Up to 5 highest-ROI items to fix and up to 5 lowest-ROI items to accept. Do not pad either list.

### Devil's advocate
For your highest-priority items: could the team be right to defer? What context might justify carrying this?

### What I didn't check
