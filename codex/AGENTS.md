# LLM Skills — Codex Agent Instructions

This repository contains reusable skills and specialist agents for code review, architecture, design, testing, security, performance, reliability, and delivery.

## Skills

Skills live in `skills/*/SKILL.md`. Each skill is a self-contained methodology. Invoke with `$skill-name`.

## Agents

Specialist agents live in `codex/agents/`. Each agent wraps one or more skills into a focused role.

### Available agents

| Agent | File | Role |
|---|---|---|
| The Orchestrator | `codex/agents/orchestrator.md` | Meta-router — picks the right specialist lineup |
| The Product Mind | `codex/agents/product-mind.md` | Feature-value gatekeeper |
| The Architect | `codex/agents/architect.md` | Design-before-code specialist |
| The Designer | `codex/agents/designer.md` | UX flow + UI hierarchy critic |
| The Accessibility Engineer | `codex/agents/accessibility.md` | Keyboard, semantics, screen reader, contrast |
| Product Design Review | `codex/agents/product-design-review.md` | Combined UX + UI verdict |
| The Executor | `codex/agents/executor.md` | Smallest correct implementation |
| The Debugger | `codex/agents/debugger.md` | Root-cause bug fixer |
| The Tester | `codex/agents/tester.md` | High-signal test strategist |
| The Breaker | `codex/agents/breaker.md` | Adversarial hardening specialist |
| The Security Engineer | `codex/agents/security.md` | Trust boundary and exploit hunter |
| The Performance Engineer | `codex/agents/performance.md` | Latency, throughput, scale specialist |
| The Reliability Engineer | `codex/agents/reliability.md` | Failure handling and operability |
| The Migration Engineer | `codex/agents/migration.md` | Schema, data, API transition safety |
| The Contract Tester | `codex/agents/contract-tester.md` | API compatibility guardian |
| The Builder | `codex/agents/builder.md` | API + dependency + onboarding reviewer |
| The Enforcer | `codex/agents/enforcer.md` | Final pre-merge gate |
| The Investigator | `codex/agents/investigator.md` | Incident, retro, and debt analyst |

### Platform shippers

| Agent | File | Platform |
|---|---|---|
| The Cloudflare Shipper | `codex/agents/cloudflare-ship.md` | Workers, Pages, KV, R2, D1 |
| The Apple Shipper | `codex/agents/apple-ship.md` | iOS, macOS, TestFlight, App Store |
| The AWS Shipper | `codex/agents/aws-ship.md` | Lambda, ECS, EKS, API Gateway |
| The Google Cloud Shipper | `codex/agents/google-cloud-ship.md` | Cloud Run, GKE, Cloud Functions |
| The Azure Shipper | `codex/agents/azure-ship.md` | App Service, Functions, AKS |
| The Supabase Shipper | `codex/agents/supabase-ship.md` | Postgres, RLS, Edge Functions |
| The Vercel Shipper | `codex/agents/vercel-ship.md` | Next.js, Edge Middleware, Functions |
| The Platform Administrator | `codex/agents/platform-administrator.md` | Auto-selects the right shipper |

## Operating principles

- Specialists over generalists. Each agent has one job.
- First principles over fashionable patterns.
- Deletion over addition. Remove before you abstract.
- Direct over hedged. Say what is wrong and what to do.
- Evidence over opinion. File:line or it didn't happen.
- Smallest viable team. Two agents is better than five when two answer the question.

## Routing

Use The Orchestrator when the task spans multiple concerns. It picks the smallest effective lineup and sequences the work. See `codex/agents/orchestrator.md` for decision rules, recommended lineups, and anti-stall safeguards.
