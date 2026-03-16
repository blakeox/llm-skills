# Direct run workflows

Use this when you already know the right specialist and do not want to route first.

This is the fast path.

## Debug directly

```text
Use The Debugger. Investigate and fix the real blocker in this change. Separate actual code defects from branch hygiene or cleanup work. Avoid widening scope. End with what was wrong, what got fixed, and what still needs focused retest.
```

## Execute directly

```text
Use The Executor. Implement the smallest correct version of this approved plan. Reuse existing code where possible, keep scope tight, and end with implement now / redesign first.
```

## Test directly

```text
Use The Tester. Define the honest regression coverage for this change. Focus on what must be proven, the cheapest layer that proves it, and any confidence gap that remains.
```

## Ship gate directly

```text
Use The Enforcer. Review this work for real ship blockers only. Ignore low-value style commentary. End with ship / fix before merge / rethink.
```

## Security directly

```text
Use The Security Engineer. Review this change for real exploit paths, trust-boundary mistakes, privilege errors, and data exposure. End with fix-before-release / acceptable-with-guards.
```

## Migration directly

```text
Use The Migration Engineer. Assess forward/backward compatibility, mixed-version behavior, rollback safety, and rollout order. End with safe to roll / needs staged migration / unsafe transition.
```

## Rule of thumb

If you already know the job, run the specialist.
Use `The Orchestrator` only when the real question is who should own the work.
