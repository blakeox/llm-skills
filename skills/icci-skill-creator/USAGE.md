# ICCI Skill Creator — Usage Guide

## Quick Start

Tell Claude what you want to build. The skill handles the rest — research, scaffolding, writing, validation, and shipping.

```
/icci-skill-creator build a skill for managing Telnyx SIP trunks across our PBX fleet
```

## Examples

### Example 1: Create a Brand-New Skill from Scratch

**User prompt:**

```
I need a new skill for managing our Datto RMM integration. It should pull device status,
run scripts remotely, and generate compliance reports. The API key is provided at runtime.
```

**What happens:**

1. Claude interviews you about edge cases, output formats, and which existing skills overlap
2. Researches the Datto RMM API — endpoints, auth, pagination, quirks
3. Scaffolds the full directory structure with `scaffold-skill.sh`
4. Writes SKILL.md with critical rules, workflows, cross-skill delegation, and credential handling
5. Writes USAGE.md with real examples
6. Writes README.md with your origin prompt as a blockquote
7. Creates API reference in `references/api-reference.md`
8. Runs `validate-skill.sh` to verify all ICCI standards
9. Creates symlink and updates the icci-skills README

**Result:** A production-ready skill directory at `~/Documents/GitHub/icci-skills/skills/icci-datto-rmm/`, validated, documented, and ready to commit.

---

### Example 2: Turn an Existing Workflow into a Skill

**User prompt:**

```
We just spent the last hour building a Cloudflare WAF audit workflow. Turn what we did into a reusable skill.
```

**What happens:**

1. Claude extracts the workflow from conversation history — tools used, sequence of steps, corrections made
2. Identifies which parts are reusable vs. one-off
3. Scaffolds the skill and writes SKILL.md capturing the workflow as repeatable procedures
4. Bundles any scripts that were written during the session into `scripts/`
5. Documents the Cloudflare API quirks discovered during the session in `references/api-reference.md`

**Result:** The ad-hoc work becomes institutional knowledge that any team member can invoke with `/icci-cf-waf-audit`.

---

### Example 3: Audit an Existing Skill Against ICCI Standards

**User prompt:**

```
Audit the icci-aws skill against current ICCI standards — is it missing anything?
```

**What happens:**

1. Runs `validate-skill.sh` against `~/.claude/skills/icci-aws/`
2. Reads the skill's SKILL.md and checks against the full ICCI standards checklist
3. Identifies gaps: missing USAGE.md, weak description, no cross-skill delegation section, etc.
4. Provides a prioritized fix list

**Result:** A clear report of what's missing and what to fix, with specific guidance for each gap.

---

### Example 4: Improve a Skill's Trigger Description

**User prompt:**

```
The di-shepherd skill isn't triggering when I mention endpoint compliance. Optimize its description.
```

**What happens:**

1. Reads the current description
2. Generates 20 trigger/no-trigger eval queries (edge cases, near-misses)
3. Reviews them with you for accuracy
4. Runs Anthropic's description optimization loop (`run_loop.py`) with up to 5 iterations
5. Returns the best description with before/after comparison and trigger accuracy scores

**Result:** Updated SKILL.md frontmatter with a description optimized for accurate triggering.

---

### Example 5: Add Eval Tests to an Existing Skill

**User prompt:**

```
Add evals to the icci-happyfox skill so we can benchmark future improvements
```

**What happens:**

1. Reads the skill's SKILL.md and USAGE.md to understand its capabilities
2. Drafts 3-5 realistic test prompts (the kind of thing a real user would say)
3. Reviews them with you
4. Creates `evals/evals.json` with prompts and expected outputs
5. Optionally runs parallel subagent tests (with-skill vs baseline)
6. Grades results and generates a benchmark report

**Result:** `evals/evals.json` with realistic test cases, plus optionally a benchmark showing the skill's value-add vs baseline.

## Advanced Usage

### Multi-Skill Architecture Planning

When building a skill that needs to work closely with existing skills:

```
I'm building a skill for ICCI's new monitoring stack. It needs to pull data from
AWS CloudWatch (currently in icci-aws), correlate with DI events (di-shepherd),
and create tickets (icci-happyfox). Help me design the delegation architecture.
```

Claude will map the ecosystem, identify delegation points, and ensure the new skill integrates cleanly without duplicating logic.

### Batch Skill Audit

```
Audit all 9 ICCI skills against current standards and give me a summary of what needs fixing.
```

Claude runs `validate-skill.sh` against every skill in `~/.claude/skills/` and produces a consolidated report.

### Porting Anthropic Skill-Creator Updates

```
Check if Anthropic has updated their skill-creator plugin and tell me what's new.
```

Claude reads the latest `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/skill-creator/skills/skill-creator/SKILL.md`, compares against the patterns in `references/anthropic-patterns.md`, and flags anything new worth integrating.

## Tips & Tricks

- Start with the intent, not the structure — Claude scaffolds the structure for you
- The origin prompt in README.md is training material — write it as if you're teaching someone to ask Claude for skills
- Use the validator early and often, not just at the end
- When in doubt about delegation boundaries, check `references/cross-skill-delegation.md`
- The scaffold script creates empty directories with `.gitkeep` — delete the ones you don't need
- Skills trigger better with longer, more specific descriptions — don't be afraid of 100+ words

## What This Skill Does NOT Do

- **Run skills** — It creates and improves them; running is done by invoking the skill directly
- **Manage MCP servers** — It documents MCP integration patterns, but MCP configuration is a Claude Code settings concern
- **Replace the Anthropic skill-creator** — It integrates Anthropic's patterns but adds ICCI-specific standards (branding, security, cross-skill delegation, credential handling)
