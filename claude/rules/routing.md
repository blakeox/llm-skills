---
description: Specialist routing table. The main conversation is the orchestrator — use this to decide which agents to spawn.
---

# Routing

You are the orchestrator. Do not delegate routing — route directly.

## Single-agent routing (one specialist clearly owns it)

| Task | Spawn agent |
|---|---|
| Feature value, scope, MVP | `product-mind` |
| Architecture, RFC, system boundaries | `architect` |
| UX/UI review | `designer` or `product-design-review` |
| Accessibility audit | `accessibility` |
| Implementation from approved plan | `executor` |
| Root-cause bug work | `debugger` |
| Test strategy, regression coverage | `tester` |
| Adversarial hardening | `breaker` |
| Security, auth, trust boundaries | `security` |
| Performance, latency, scale | `performance` |
| Reliability, observability, retries | `reliability` |
| Schema/data/API migration | `migration` |
| Consumer compatibility | `contract-tester` |
| API, dependencies, onboarding | `builder` |
| Pre-merge safety gate | `enforcer` |
| Incident, retro, tech debt | `investigator` |
| Platform release (unknown provider) | `platform-administrator` |
| Cloudflare release | `cloudflare-ship` |
| Apple release | `apple-ship` |
| AWS release | `aws-ship` |
| Google Cloud release | `google-cloud-ship` |
| Azure release | `azure-ship` |
| Supabase release | `supabase-ship` |
| Vercel release | `vercel-ship` |

## Multi-agent routing (task crosses boundaries)

Spawn agents in parallel when independent, sequential when dependent.

| Scenario | Agents | Order |
|---|---|---|
| New feature | `product-mind` → `architect` → `designer` | Sequential |
| Accessibility-sensitive UI | `designer` + `accessibility` then `enforcer` | Parallel then gate |
| Feature execution | `architect` then `executor` | Sequential |
| Bug fix + regression | `debugger` then `tester` | Sequential |
| Security-sensitive API | `security` + `builder` then `enforcer` | Parallel then gate |
| Performance-sensitive | `architect` + `performance` then `tester` | Parallel then gate |
| Data migration | `migration` + `architect` then `enforcer` | Parallel then gate |
| Pre-merge backend | `enforcer` + `builder` | Parallel |
| Pre-release hardening | `breaker` + `tester` then `enforcer` | Parallel then gate |
| Post-incident | `investigator` then `architect` | Sequential |
| Platform release | platform shipper then `enforcer` | Sequential |

## Agent teams (parallel coordination with inter-agent discussion)

Use agent teams when specialists need to challenge each other's findings:

- **Pre-merge review team**: enforcer + builder + tester — argue about what's shippable
- **Security hardening team**: security + breaker + enforcer — find and validate exploit paths
- **Architecture review team**: architect + performance + reliability — stress-test the design
- **Feature planning team**: product-mind + architect + designer — converge on scope and shape

Spawn teams with: "Create an agent team with [specialist 1], [specialist 2], [specialist 3] to [task]"

## Rules

- Prefer the smallest viable lineup. Two agents beats five.
- If one specialist clearly owns it, spawn one and stop.
- If unsure, pick the best single specialist with a stated assumption.
- For multi-agent work, spawn independent agents in parallel via background.
- Use agent teams when findings need cross-validation, not just collection.
