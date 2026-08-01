---
name: retro
description: Evidence-backed engineering retrospective grounded in delivery artifacts. Use when reviewing a week, sprint, release, or other period to identify what shipped, where system flow stalled, how review and change load were distributed, and which process changes are justified. Do not use commit volume, LOC, or working hours as individual performance evidence.
user-invocable: true
argument-hint: "[time range, e.g. 'last week', 'last 2 weeks', 'march']"
---

Read `../_house-style/house-style.md` before starting.

## Evidence boundary

Git is one delivery artifact, not the source of truth about effort, performance, intent, or wellbeing. Pull-request, issue, CI, incident, and deployment claims require those systems; do not infer them from commits.

Do not:

- rank people by commits, LOC, test ratio, active days, or timestamps
- infer burnout, productivity, availability, or motivation
- turn individual attribution into performance evaluation
- expose personal data, credentials, customer payloads, or sensitive internal identifiers

Use names only when the user explicitly requests legitimate attribution and the source supports it. Default to roles, workflow stages, and system conditions.

## Data collection

For the requested range, collect only accessible, relevant artifacts:

- shipped changes and affected product/system areas
- change size and hotspots, without treating size as value
- review and merge latency from forge data when available
- CI failures, reverts, incident links, and deployment outcomes
- unresolved or repeatedly reopened work
- concentration risk in components, review queues, or ownership

Label each datum `Measured`, `Source-backed`, `Inferred`, or `Unavailable`. Do not fill missing forge or planning data from git guesses.

## Analysis

### 1. Delivery outcomes

What reached users or operations? Separate merged, deployed, released, and merely committed work.

### 2. Flow constraints

Where did work wait, loop, fail, or require manual recovery? Name the evidence and system condition. Do not call a person a bottleneck without corroborating workflow evidence and relevant context.

### 3. Quality signals

Examine reverts, recurring CI failures, incident links, missing proof on high-risk changes, and hotspot concentration. State what the artifacts cannot prove.

### 4. Control and ownership gaps

Identify unclear review ownership, missing automated gates, fragile single-owner components, and shadow processes. Recommend a role or control, not a personal judgment.

## Output format

### Period summary

What shipped and what did not, with evidence classes.

### Outcomes worth preserving

Up to three specific delivery or control outcomes and why they mattered.

### System constraints

Up to three evidence-backed flow, quality, or ownership problems. Use the shared finding contract.

### Hotspots and concentration risk

Components, queues, or review surfaces with repeated change or unresolved ownership. Do not equate LOC with value.

### Three changes

Dependency-ordered actions. Name the responsible role if known and the verification condition. Do not invent a person or deadline.

### Devil's advocate

What planning, coordination, support, or external context could change the strongest conclusion?

### What I didn't verify

Missing planning context, inaccessible forge/CI/deploy data, unobserved work, and the evidence needed to close each gap.
