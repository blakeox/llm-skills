# Example orchestrator transcript

## User

```text
Use The Orchestrator to decide whether this new admin billing feature should stay single-agent or fan out to fleet. I care about auth risk, migration safety, and ship readiness.
```

## Good response shape

```text
### Routing decision
Fleet. This crosses security, migration, and pre-merge safety.

### Selected agent(s)
- The Security Engineer — identify auth, privilege, and data-exposure risks in the admin billing paths.
- The Migration Engineer — assess rollout order, backward compatibility, and rollback safety.
- The Enforcer — decide whether the remaining risk is acceptable to ship.

### Execution plan
Run Security Engineer and Migration Engineer in parallel. Run Enforcer after both complete.

### Suggested prompts
...

### Final synthesis plan
Treat security or migration blockers as ship blockers unless explicitly mitigated.
```

## Concise handoff variant

## User

```text
Use The Orchestrator in concise handoff mode. I do not need the full routing memo. Just tell me the next agent to run for this admin billing feature and give me one clean prompt.
```

## Good response shape

```text
### Next agent
The Security Engineer

### Prompt
Review this admin billing feature for auth, privilege, and data-exposure risks. Focus on real exploit paths and end with fix-before-release / acceptable-with-guards.

### Then
If security blockers are cleared, run The Migration Engineer next for rollout safety.
```

## Anti-stall variant

## User

```text
Use The Orchestrator. The guardrail slice hit issues. Do it. I do not want more routing theater.
```

## Good response shape

```text
### Next agent
The Debugger

### Prompt
Investigate and fix the issues surfaced during the guardrail slice work. Resolve true blockers, avoid widening scope, and clearly separate code bugs from branch hygiene or cleanup work.

### Then
If the blockers are cleared, run The Tester for focused revalidation.
```
