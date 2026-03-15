# Section Review Rating Rubric

## Score Scale

The scale is intentionally harsh. Most sections in the real world are a 4-6. A 7 is genuinely good. An 8+ is rare. Hand out high scores like they cost you money.

| Score | Verdict | Definition |
|---|---|---|
| 9-10 | Revolutionary | Does something competitors don't or can't. Users would switch products for this section alone. Clear differentiation that is hard to replicate. You should almost never give this score. |
| 7-8 | Standard (good) | Works correctly, handles edge cases, low friction. Meets or slightly exceeds market expectations. Not differentiated, but well-executed. |
| 5-6 | Standard (mediocre) | Works for the happy path. Falls apart on edge cases, has friction, or requires the user to already know how it works. This is where most software lives. Do not be afraid to score here. |
| 3-4 | Bad | Creates friction, confusion, or extra work. Users tolerate it but complain, work around it, or avoid it. The section exists but actively costs users time or confidence. |
| 1-2 | Disaster | Actively harms the user or the product. Breaks trust, blocks task completion, or introduces risk. Would be better if the section did not exist. |
| 0 | Hostile | The section makes things worse by existing. It misleads, destroys data, or creates liability. Delete it. |

### Score justification rules

- **Any score above 5 requires you to name what specifically elevates it.** "It works" is a 5. What makes it a 6? A 7? Say it or lower the score.
- **Any score of 8+ requires extraordinary evidence.** Name the specific thing that no competitor does as well.
- **If the section has a single Disaster-level finding, the score cannot exceed 4.** One critical failure poisons the whole section.
- **If the section has no Revolutionary findings, the maximum score is 8.** You cannot be Revolutionary without something Revolutionary in it.
- **Any security vulnerability in a production-facing section caps the score at 2.** Security is not a feature — it's a prerequisite. A section with great UX and an XSS vector is a Disaster.
- **Default assumption: the section is a 5 until proven otherwise.** Move the score up or down from there based on evidence.

## Scoring Emphasis by Section Type

Different section types have different failure modes. Weight your scoring accordingly.

### Onboarding/Setup

- **Primary weight:** Time-to-first-value. How fast does a new user go from zero to doing real work?
- **Secondary weight:** Error recovery. What happens when the user enters wrong credentials, skips a step, or hits an edge case?
- **Failure signal:** User gives up before completing setup, or completes setup but doesn't understand what happened.
- **Revolutionary bar:** Setup that eliminates manual steps competitors require, or that teaches domain concepts while configuring.

### Navigation/Search

- **Primary weight:** Can the user find what they need in under 3 actions?
- **Secondary weight:** Does the structure match the user's mental model, not the developer's data model?
- **Failure signal:** User repeatedly uses browser search, asks a colleague, or navigates to the wrong place first.
- **Revolutionary bar:** Navigation that surfaces what the user needs before they search for it.

### Dashboard/Reporting

- **Primary weight:** Does it answer the question the user actually has, without requiring a second tool?
- **Secondary weight:** Is the default view useful, or does every user need to customize it?
- **Failure signal:** Users export to a spreadsheet to get the answer. Dashboard loads but doesn't change behavior.
- **Revolutionary bar:** Dashboard that drives action, not just displays data. Shows what to do, not just what happened.

### Editor/Form/Workflow

- **Primary weight:** Can the user complete the task without making a mistake that is hard to undo?
- **Secondary weight:** Does the workflow match the real-world sequence, or does it force the user to think in system terms?
- **Failure signal:** User submits, gets an error, loses work, or has to redo steps. Or completes the workflow but the result isn't what they expected.
- **Revolutionary bar:** Workflow that prevents errors by design, or that handles edge cases the user didn't anticipate.

### Settings/Admin

- **Primary weight:** Can the user make a change confidently, knowing what will happen?
- **Secondary weight:** Are dangerous settings clearly separated from routine ones?
- **Failure signal:** User changes a setting and breaks something unexpectedly. Or avoids touching settings because the consequences are unclear.
- **Revolutionary bar:** Settings that explain their impact in concrete terms, or that preview the effect before applying.

### Trust-Sensitive Flow

- **Primary weight:** Does the system do exactly what it says it will do? No surprises, no silent failures, no ambiguous states.
- **Secondary weight:** Can the user verify what happened after the fact? Is there an audit trail?
- **Failure signal:** User doesn't trust the output and manually double-checks. Or the system does something the user didn't expect and there's no way to trace why.
- **Revolutionary bar:** Flow that builds more trust the more you use it. Clear provenance, reversible actions, and honest error reporting.

### API Surface / Data Contract

- **Primary weight:** Can a developer integrate correctly on the first attempt using only the docs and types?
- **Secondary weight:** Does the API fail loudly and clearly, or does it silently accept bad input?
- **Failure signal:** Developer has to read source code to understand behavior. Error messages don't explain what went wrong or how to fix it.
- **Revolutionary bar:** API that makes incorrect usage impossible through types and design, not just documentation.

### State Management / Data Flow

- **Primary weight:** Is the data flow predictable? Can you trace where a value comes from and what changes it?
- **Secondary weight:** Are there impossible states that the code doesn't prevent?
- **Failure signal:** Bugs that only reproduce "sometimes." State that gets out of sync. Props drilled through 5+ layers.
- **Revolutionary bar:** State model that eliminates entire categories of bugs by making invalid states unrepresentable.

### Error Handling / Resilience

- **Primary weight:** Does the system fail gracefully, or does it fail silently or catastrophically?
- **Secondary weight:** Can the user (or developer) understand what went wrong and what to do about it?
- **Failure signal:** Generic error messages. Swallowed exceptions. Retry loops with no backoff. Errors that leave the system in an inconsistent state.
- **Revolutionary bar:** Error handling that recovers automatically when possible, and when it can't, tells you exactly what happened, why, and what to do.

### Build / Deploy / Infra

- **Primary weight:** Can a new developer go from clone to running in under 5 minutes?
- **Secondary weight:** Is the deployment process repeatable, auditable, and reversible?
- **Failure signal:** "It works on my machine." Undocumented environment variables. Manual deployment steps. No rollback path.
- **Revolutionary bar:** Zero-config setup. Deployments that verify themselves. Infrastructure that self-heals.

### Security / Auth / Data Protection

- **Primary weight:** Does the section handle authentication, authorization, input validation, and data exposure correctly? Are there open attack surfaces?
- **Secondary weight:** Are secrets managed properly? Is sensitive data encrypted at rest and in transit? Are permissions enforced at the right layer (not just the UI)?
- **Failure signal:** SQL injection, XSS, CSRF, IDOR, or privilege escalation vectors. Secrets in source code or environment variables without rotation. Auth checks only in the frontend. Overly permissive CORS. Logging sensitive data. Returning more data than the client needs.
- **Revolutionary bar:** Security model where incorrect usage is structurally impossible — not just documented, but enforced by types, middleware, or architecture. Defense in depth that doesn't rely on any single layer.
- **Special scoring rule:** Any unpatched security vulnerability in a production-facing section is an automatic Disaster (0-2), regardless of how well the rest of the section works. Security failures are not weighted — they override.

## Severity Tags

Use these tags on Bad and Disaster findings to indicate impact type:

| Tag | Meaning |
|---|---|
| `Creates drag` | Slows the user down but doesn't stop them. Adds steps, confusion, or cognitive load. Cumulative cost is high over time. |
| `Blocks task completion` | Prevents the user from finishing what they started. Dead end, unrecoverable error, or missing capability. |
| `Breaks trust` | Makes the user question whether the system is correct. Silent failures, inconsistent state, misleading feedback, or data loss. |
| `Security exposure` | Creates an attack surface, leaks data, or fails to enforce authorization. Severity scales with the sensitivity of the data and the exposure of the endpoint. |
| `Disaster waiting to happen` | The failure hasn't occurred yet, but is structurally guaranteed under realistic growth or usage. Score at full Disaster severity — the distinction between "has blown up" and "will blow up" doesn't change the score. |

## Reversibility Tags

Use these tags on Needs improvement and Needs removal findings:

| Tag | Meaning |
|---|---|
| `Reversible` | Can be changed or removed without migrating data, breaking integrations, or retraining users. Safe to iterate on. |
| `Hard-to-reverse` | Changing this later requires migration, coordination, or will break existing workflows. Get it right now or accept the cost later. |

## Confidence Levels

| Level | When to use |
|---|---|
| High | You have read the code, seen the behavior, or have clear evidence. Your claims are directly supported. |
| Medium | You have partial evidence — e.g., you read the code but didn't run it, or you saw the UI but didn't test edge cases. Reasonable inferences but gaps remain. |
| Low | You are reasoning from architecture, naming, or patterns without direct evidence. Flag this explicitly so the reader knows. |

Low confidence is not an excuse to be gentle. You can be uncertain about the evidence and still be blunt about what you see.

## Calibration Guidelines

These are anchors to keep scores consistent across reviews. Default to the harsher reading — the user is here for honesty, not comfort.

- **Most software is a 5.** It works on the happy path and that's it. If you're giving out 7s regularly, your standards are too low.
- **A section that works correctly but looks ugly is Standard mediocre (5-6).** Don't penalize appearance unless it causes usability problems — but don't reward bare functionality either.
- **A section that looks polished but has silent data loss is Disaster (0-2).** Don't reward appearance when correctness is broken.
- **A section that requires 3 workarounds but technically works is Bad (3-4).** Workarounds are a tax on every user, every time.
- **A section that only 1 user needs but serves them perfectly can still be Revolutionary.** Audience size doesn't determine quality.
- **A missing section is not automatically Bad.** If it's not needed, its absence is fine. Only flag it as Missing if the workflow is incomplete without it.
- **A section with good bones but one critical bug should score for the bug, not the bones.** A bridge with one broken support beam is not a 7/10 bridge.
- **When in doubt between two scores, pick the lower one.** The review should push toward improvement, not reassurance.
- **Do not grade on a curve.** Compare against what the section should be, not against how hard it was to build.
- **"It works" is not praise — it's the minimum.** Only call something out as good if it genuinely exceeds expectations.
- **Do not give credit for intent.** The code does what it does, not what the developer meant it to do.
- **Partial implementations score for what's missing, not what's present.** A half-built feature is worse than no feature because it sets false expectations.

## Concrete Scoring Examples

Abstract calibration guidelines are not enough. These are real-code-shaped examples that anchor what each score level looks like in practice.

### Error handling: score 2 (Disaster)

```js
try {
  const data = await fetchUser(id);
  return data;
} catch (e) {
  return null;
}
```

Why it's a 2: Swallows every error type — network, auth, 404, server crash — and returns `null`. The caller has no idea what happened. This hides bugs in production. It's worse than no error handling because it creates the illusion of resilience.

### Error handling: score 5 (Standard mediocre)

```js
try {
  const data = await fetchUser(id);
  return { ok: true, data };
} catch (e) {
  console.error("Failed to fetch user:", e);
  return { ok: false, error: e.message };
}
```

Why it's a 5: The error is logged and surfaced to the caller. But `e.message` loses the error type, stack, and context. The caller can't distinguish a 404 from a network timeout from an auth failure. It works but it doesn't help you debug.

### Error handling: score 7 (Standard good)

```ts
type FetchResult<T> =
  | { ok: true; data: T }
  | { ok: false; error: ApiError };

type ApiError =
  | { type: "not_found"; id: string }
  | { type: "network"; cause: Error }
  | { type: "unauthorized" };

async function fetchUser(id: string): Promise<FetchResult<User>> {
  // Each error path returns a typed, actionable error
}
```

Why it's a 7: Typed errors that the caller can pattern-match on. Each error variant carries the context needed to handle it differently. The caller can show "user not found" vs. "please log in" vs. "network error, retry." No information is lost.

### Component structure: score 3 (Bad)

A single 1,500-line file that mixes API calls, business logic, state management, and UI rendering. To change a button label, you scroll past 800 lines of math.

Why it's a 3: Functional but creates drag on every change. New developers can't understand it without the author explaining it. Every merge conflict touches the same file. Testable only as an integration test.

### Component structure: score 7 (Standard good)

Business logic in pure functions (tested independently). State management in a custom hook. UI in small, focused components that receive props. API layer separated behind an interface.

Why it's a 7: Each concern can be understood, tested, and changed independently. A new developer can navigate by reading file names. Not revolutionary — this is just good separation of concerns — but it's well-executed.

### API design: score 1 (Disaster)

An endpoint that accepts a raw SQL string in the request body and executes it.

Why it's a 1: This is not an API, it's a remote code execution vulnerability. The fact that it works is the problem.

### API design: score 9 (Revolutionary)

An API where the type system makes invalid requests unrepresentable. If you can construct the request object, the request is valid. No runtime validation needed because the compiler already proved it. Errors return machine-readable codes with human-readable explanations and links to docs.

Why it's a 9: Eliminates entire categories of integration bugs by design, not documentation. Competitors' APIs require you to read the docs to avoid mistakes; this one makes mistakes impossible.

## What Makes a Finding "Revolutionary" vs "Standard"

A feature is Revolutionary only if:

1. It solves a problem that users of competing products still have, AND
2. It would be non-trivial for a competitor to replicate, AND
3. Users would notice and care if it were removed.

If it only meets one of these, it's Standard. Good execution of a known pattern is Standard, not Revolutionary. Reserve Revolutionary for genuine differentiation.

If you're tempted to call something Revolutionary, ask: "Would I switch products for this?" If the answer is no, it's not Revolutionary.

## What Makes a Finding "Bad" vs "Disaster"

- **Bad:** The user can work around it. They'll complain, but they'll get the job done.
- **Disaster:** The user cannot work around it, or working around it introduces new risk. The section is actively worse than not having it.

The dividing line is: **does the problem compound?** A Bad finding costs the user time once per occurrence. A Disaster finding gets worse the more the system is used (e.g., silent data corruption, trust erosion, state divergence).

When a problem is both common and compounding, it's a Disaster even if each individual occurrence seems small.

## Disasters Waiting to Happen

**A problem does not need to have caused harm yet to be a Disaster.** If the failure is structurally guaranteed given a realistic scenario, it scores as a Disaster *now* — not when it explodes.

Score these as Disaster (1-2) even if they currently "work fine":

- **Race conditions that only trigger under load.** If two concurrent requests can corrupt data, that's a Disaster — even if you've only ever had one user at a time.
- **Missing indexes on tables that are small today.** A full table scan on 100 rows is invisible. On 100,000 rows it takes down the page. The code is the same; the score should be the same.
- **Auth checks only in the frontend.** Works until someone opens the network tab. This is a security Disaster even if no one has exploited it.
- **Unbounded queries or lists with no pagination.** Returns 50 items today. Returns 50,000 items next year. The endpoint didn't change — the data did.
- **Hardcoded secrets, credentials, or API keys in source.** No one has stolen them yet. That doesn't make the code secure.
- **State that can diverge but hasn't yet.** Duplicated state between two stores, client and server, or cache and database — if there's no sync mechanism, divergence isn't a risk, it's a certainty on a long enough timeline.
- **Silent data loss paths.** A write that can fail without the user knowing. A migration that drops a column nobody queries *yet*. A cache eviction that deletes uncommitted work.
- **Dependencies with known CVEs that haven't been exploited.** The vulnerability exists whether or not someone has used it against you.

### How to identify them

Ask: **"Is there a realistic scenario — not a contrived edge case, but a scenario that will naturally occur as the product grows — where this breaks?"** If yes, it's a Disaster waiting to happen, and it scores as a Disaster.

The word "waiting" is not a discount. A bomb that hasn't gone off is still a bomb.

### Severity tag

Tag these findings with `Disaster waiting to happen` in addition to any other applicable tags (`Security exposure`, `Breaks trust`, etc.). This tells the reader that the harm is latent, not yet observed — but the finding is scored at full severity because the failure is structural, not speculative.

### Score justification rule

**If a section contains a Disaster waiting to happen, the score cannot exceed 4.** Same rule as an active Disaster. The distinction between "has blown up" and "will blow up" does not change the score — it changes the urgency.
