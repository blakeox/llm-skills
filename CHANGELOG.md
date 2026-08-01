# Changelog

## 0.10.0 — Skill bench consolidation and hardening

### Consolidated provider release skills

- replaced seven duplicated provider skills with `platform-ship` and conditional Apple, AWS, Azure, Cloudflare, Google Cloud, Supabase, and Vercel references
- retained provider-specific agents as focused routers through the consolidated release contract
- added ownership-checked cleanup for retired Codex skill directories

### Added operational review lanes

- added `security-review`, `migration-review`, and `reliability-review`
- added DevEx planning and live-review skills
- added a read-only `parallel-review operational-risk` mode

### Hardened evidence and execution contracts

- added shared finding, active-testing, and release-gate contracts
- separated parallel diagnosis from sequential mutation and added dirty-worktree, secret, deletion, and external-action safeguards
- corrected unsupported accessibility, personnel, incident, test-diagnosis, and estimate claims
- reduced large skill entrypoints through conditional references and narrowed `section-review`

### Added validation and Codex-native installation

- added deterministic Codex rendering, UI metadata generation, ownership protection, install verification, and retired-skill cleanup
- added manifest, reference, trigger-case, line-budget, retired-invocation, README, and generated-YAML checks
- added positive and negative trigger cases for every published skill and adversarial forward tests for the highest-risk workflows

Migration: replace provider-specific skill invocations with `/platform-ship <provider>` or `$platform-ship <provider>`. Provider-specific agents remain available.

## 0.7.0 — OpenClaw, Claude Code, and Codex integration

### Added OpenClaw support

- `openclaw/skills/` — 26 agent-as-skills (SKILL.md wrappers for each specialist role)
- `scripts/install-openclaw.sh` — installs raw skills via extraDirs + agent skills to `~/.openclaw/skills/`
- OpenClaw loads skills from the repo via `skills.load.extraDirs` (live watch, no copy)
- ACP bridge documentation for spawning Claude/Codex sessions from OpenClaw

### Added Claude Code best-practice setup

- `claude/agents/` — all 26 agents updated with `skills:` frontmatter for auto-preloading
- `claude/agents/orchestrator.md` — references actual `subagent_type` names instead of prose
- `claude/rules/house-style.md` — auto-loaded rule (replaces explicit Read instructions)
- `scripts/install-claude.sh` — symlinks skills, copies agents+rules to `~/.claude/`

### Added Codex support

- `scripts/install-codex.sh` — symlinks skills + agent-as-skills to `~/.codex/skills/`

### Updated

- `INSTALL.md` — setup guides for all four platforms (Copilot, Claude Code, OpenClaw, Codex)
- `README.md` — cross-platform install section and updated layout
- `VERSION` bumped to `0.7.0`

### Architecture note

All platforms share the same skill bench from `skills/`. Platform-specific wiring:
- **Copilot**: `.github/agents/` (agent definitions) + `~/.copilot/skills/` (rsync copy)
- **Claude Code**: `claude/agents/` (with `skills:` frontmatter) + `~/.claude/skills/` (symlinks)
- **OpenClaw**: `openclaw/skills/` (agent-as-skills) + `extraDirs` (live reference)
- **Codex**: `~/.codex/skills/` (symlinks to both raw skills and agent-as-skills)

---

## 0.6.0

### Previous build-out

### Added skills

- `skills/plan-devex-review/`
- `skills/devex-review/`
- `skills/ux-designer/`
- `skills/ui-designer/`

### Added provider-specific shipping lanes

- `skills/cloudflare-ship/`
- `skills/apple-ship/`
- `skills/aws-ship/`
- `skills/google-cloud-ship/`
- `skills/azure-ship/`
- `skills/supabase-ship/`
- `skills/vercel-ship/`
- `.github/agents/cloudflare-ship.agent.md`
- `.github/agents/apple-ship.agent.md`
- `.github/agents/aws-ship.agent.md`
- `.github/agents/google-cloud-ship.agent.md`
- `.github/agents/azure-ship.agent.md`
- `.github/agents/supabase-ship.agent.md`
- `.github/agents/vercel-ship.agent.md`

### Added custom agents

- `orchestrator.agent.md`
- `enforcer.agent.md`
- `architect.agent.md`
- `product-mind.agent.md`
- `builder.agent.md`
- `investigator.agent.md`
- `designer.agent.md`
- `product-design-review.agent.md`
- `executor.agent.md`
- `debugger.agent.md`
- `tester.agent.md`
- `breaker.agent.md`
- `security.agent.md`
- `performance.agent.md`
- `reliability.agent.md`
- `migration.agent.md`
- `contract-tester.agent.md`
- `accessibility.agent.md`

### Added installation and verification tooling

- `scripts/install-copilot-agents.sh`
- `scripts/verify-copilot-agents.sh`
- `scripts/bootstrap-copilot.sh`

### Added routing and workflow support

- `.github/copilot-instructions.md`
- `.github/instructions/skills.instructions.md`
- `.github/instructions/agents.instructions.md`
- `templates/fleet-phase-prompts.md`
- `recipes/feature-workflow.md`
- `recipes/incident-workflow.md`
- `recipes/platform-change-workflow.md`

### Added guide set

- `guide/operating-model.md`
- `guide/quick-reference.md`
- `guide/change-checklist.md`
- `guide/prompt-patterns.md`
- `guide/agent-contracts.md`
- `guide/glossary.md`
- `guide/troubleshooting.md`
- `guide/evaluation-rubric.md`
- `guide/pruning-guide.md`
- `guide/release-checklist.md`
- `guide/self-audit.md`

### Added examples and goldens

- `examples/orchestrator-transcript.md`
- `examples/fleet-review-transcript.md`
- `examples/executor-transcript.md`
- `examples/security-review-transcript.md`
- `examples/migration-transcript.md`

### Added operational maturity support

- `VERSION`
- bumped to `0.8.0` for README sync automation, shared-repo bootstrap support, and the DevEx review lane

### Added evaluation harness

- `eval/README.md`
- `eval/cases.md`

### Added cross-tool setup

- `AGENTS.md`
- `CLAUDE.md`
- `.cursor/rules/llm-skills.mdc`
- `.clinerules/01-llm-skills.md`
- `DEVIN_TASKS.md`
- `orchestration/crewai/agents.yaml`
- `orchestration/crewai/tasks.yaml`
- `orchestration/langchain/agent-map.yaml`
- `orchestration/README.md`

### Behavioral shift

The repo now supports:
- routing with a lightweight orchestrator
- execution, debugging, testing, security, reliability, migration, contract, design, and accessibility specialists
- evaluation of answer quality with reusable cases and rubrics
- one-command installation and verification for Copilot assets
