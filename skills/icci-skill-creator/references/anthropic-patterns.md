# Anthropic Skill-Creator Patterns

Best practices extracted from Anthropic's official `skill-creator` plugin and `skill-development` reference. These represent the cutting edge of skill authoring as of the latest plugin marketplace release.

**Source:** `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/skill-creator/skills/skill-creator/SKILL.md`

Check for updates periodically — Anthropic actively evolves this plugin.

## Description Optimization

The `description` field is the primary triggering mechanism. Claude decides whether to consult a skill based solely on name + description.

### Key Insight: Claude Undertriggers

Claude has a tendency to NOT use skills when they'd be useful. Compensate by making descriptions "pushy":

**Bad:** `"How to build a dashboard to display data."`

**Good:** `"How to build a simple fast dashboard to display internal data. Make sure to use this skill whenever the user mentions dashboards, data visualization, internal metrics, or wants to display any kind of company data, even if they don't explicitly ask for a 'dashboard.'"`

### Automated Description Optimization

Anthropic provides `scripts/run_loop.py` which:

1. Takes 20 trigger/no-trigger eval queries (60% train, 40% test)
2. Evaluates current description with 3x retry for reliability
3. Uses extended thinking to propose improvements
4. Re-evaluates each iteration on both train and test sets
5. Returns `best_description` selected by test score (avoids overfitting)

**Run from skill-creator directory:**

```bash
python -m scripts.run_loop \
  --eval-set trigger-eval.json \
  --skill-path /path/to/skill \
  --model claude-opus-4-6 \
  --max-iterations 5 \
  --verbose
```

### Trigger Query Design

**Should-trigger queries (8-10):**

- Different phrasings of the same intent (formal + casual)
- Cases where user doesn't name the skill but clearly needs it
- Uncommon use cases
- Cases where this skill competes with another but should win

**Should-not-trigger queries (8-10):**

- Near-misses: shared keywords but different intent
- Adjacent domains
- Ambiguous phrasing where keyword match would trigger but shouldn't

**Quality bar:** Queries must be realistic — include file paths, personal context, company names, URLs, typos, casual speech, varying lengths. Focus on edge cases, not clear-cut scenarios.

## Eval Methodology

### The Loop

1. Capture intent (what, when, output format)
2. Interview and research edge cases
3. Write SKILL.md draft
4. Create 2-3 realistic test prompts → `evals/evals.json`
5. Spawn parallel subagent runs (with-skill + baseline)
6. Draft quantitative assertions while runs execute
7. Grade with `agents/grader.md`, aggregate with `aggregate_benchmark.py`
8. Launch eval viewer with `eval-viewer/generate_review.py`
9. Read user feedback, improve skill, repeat
10. After skill is solid, run description optimization

### Eval JSON Schema

```json
{
  "skill_name": "skill-name",
  "evals": [
    {
      "id": 1,
      "prompt": "Realistic user prompt with context",
      "expected_output": "Description of expected result",
      "files": [],
      "expectations": ["Verifiable assertion 1", "Verifiable assertion 2"]
    }
  ]
}
```

### Grading

Use programmatic verification where possible (scripts > eyeballing). Grading JSON must use fields `text`, `passed`, `evidence` — the viewer depends on these exact field names.

### Benchmarking

```bash
python -m scripts.aggregate_benchmark workspace/iteration-N --skill-name skill-name
```

Produces `benchmark.json` and `benchmark.md` with pass_rate, time, and tokens per configuration, with mean +/- stddev and delta.

### Blind Comparison (Advanced)

For rigorous A/B testing: give two outputs to an independent agent without revealing which is which. Uses `agents/comparator.md` and `agents/analyzer.md`. Optional — human review loop is usually sufficient.

## Writing Patterns

### Explain the Why

Today's LLMs are smart. They have good theory of mind and when given a good harness can go beyond rote instructions. If you find yourself writing ALWAYS or NEVER in all caps, reframe and explain the reasoning so the model understands WHY the thing is important. That's a more humane, powerful, and effective approach.

### Generalize from Feedback

Skills will be used many times across many different prompts. Rather than put in fiddly overfitty changes or oppressively constrictive MUSTs, if there's a stubborn issue, try branching out with different metaphors or recommending different patterns. It's relatively cheap to try.

### Keep Prompts Lean

Remove things that aren't pulling their weight. Read the transcripts, not just the final outputs — if the skill makes the model waste time doing unproductive things, remove those parts.

### Look for Repeated Work

If all test case transcripts show the subagent independently writing similar helper scripts, that's a signal the skill should bundle that script in `scripts/`. Write it once, save every future invocation from reinventing the wheel.

## Progressive Disclosure (Three Levels)

1. **Metadata** (~100 words) — Always in context. Name + description.
2. **SKILL.md body** (<500 lines, ~1,500-2,000 words ideal) — Loaded when skill triggers.
3. **Bundled resources** (unlimited) — Loaded as needed. Scripts can execute without loading into context.

**Key patterns:**

- Reference files clearly from SKILL.md with guidance on when to read them
- For large reference files (>300 lines), include a table of contents
- Domain organization: when supporting multiple variants, organize by variant in `references/`

## Output Format Patterns

Define exact templates in the skill:

```markdown
## Report Structure

ALWAYS use this exact template:

# [Title]

## Executive Summary

## Key Findings

## Recommendations
```

Include examples:

```markdown
## Commit Message Format

**Example 1:**
Input: Added user authentication with JWT tokens
Output: feat(auth): implement JWT-based authentication
```

## Skill Locations (Priority Order)

| Location   | Path                               | Scope                |
| ---------- | ---------------------------------- | -------------------- |
| Enterprise | Managed settings                   | All org users        |
| Personal   | `~/.claude/skills/<name>/SKILL.md` | All projects         |
| Project    | `.claude/skills/<name>/SKILL.md`   | This project only    |
| Plugin     | `<plugin>/skills/<name>/SKILL.md`  | Where plugin enabled |

## Frontmatter Fields Reference

| Field                      | Purpose                    | Notes                                     |
| -------------------------- | -------------------------- | ----------------------------------------- |
| `name`                     | Slash command name         | lowercase, hyphens, max 64 chars          |
| `description`              | When to trigger            | Primary triggering mechanism              |
| `disable-model-invocation` | Only user can invoke       | For side-effect workflows                 |
| `user-invocable`           | Show in `/` menu           | `false` = hidden background knowledge     |
| `allowed-tools`            | Restrict tool access       | Rarely needed                             |
| `model`                    | Override model             | Rarely needed                             |
| `context`                  | `fork` = isolated subagent | For independent execution                 |
| `agent`                    | Subagent type              | Explore, Plan, general-purpose, or custom |
| `argument-hint`            | Autocomplete hint          | e.g., `[issue-number]`                    |
| `hooks`                    | Lifecycle hooks            | Scoped to this skill                      |

## String Substitutions

Available in SKILL.md:

- `$ARGUMENTS` — All args passed to the skill
- `$ARGUMENTS[N]` or `$N` — Positional args (0-based)
- `${CLAUDE_SESSION_ID}` — Current session ID
- `${CLAUDE_SKILL_DIR}` — The skill's directory path
- `` !`command` `` — Shell command output injected as preprocessing

## Validation Checklist (from Anthropic)

- [ ] SKILL.md exists with valid YAML frontmatter
- [ ] Frontmatter has `name` and `description`
- [ ] Description uses specific trigger phrases
- [ ] Description is "pushy" (overinclusive vs underinclusive)
- [ ] Body uses imperative form, not second person
- [ ] Body under 500 lines (detail in references/)
- [ ] All referenced files exist
- [ ] Scripts are executable and documented
- [ ] Examples are complete and working
- [ ] Progressive disclosure properly layered
