---
name: icci-skill-creator
description: "Create new ICCI skills, improve existing skills, and validate skill quality. Use this skill whenever the user wants to create a new skill, build a skill from scratch, turn a workflow into a skill, improve or refactor an existing skill, audit a skill against ICCI standards, scaffold a skill directory, validate skill structure, optimize a skill's triggering description, or discuss skill architecture and best practices. Also trigger when the user mentions skill creation, skill development, new skill, skill template, or skill standards."
user-invocable: true
argument-hint: "[skill name or task description]"
---

# ICCI Skill Creator

Build ICCI skills that are secure, branded, version-controlled, self-improving, and aware of the ecosystem around them. This skill codifies every pattern learned from building 10 production ICCI skills and integrates the best practices from Anthropic's official skill-creator.

## Critical Rules

1. **REPOSITORY SECURITY** — Before ANY GitHub push, verify the target repo is private: `gh repo view icci/{repo} --json isPrivate -q '.isPrivate'`. If it returns anything other than `true`, STOP and warn loudly. Skills may contain server details, API patterns, and client information.

2. **NO CREDENTIALS IN SKILLS** — Never store API keys, tokens, passwords, or secrets in skill files, scripts, or config. Instead, build a session-start credential prompt into the skill's workflow. Credentials may be held in memory during a session but must never be written to disk in the skill directory. Use environment variables or 1Password references for CI/CD contexts.

3. **ICCI BRANDING REQUIRED** — Every skill that produces formatted output (PDF, HTML, email, ticket) must use `~/Documents/GitHub/icci-report-branding/`. Read `brand/identity.md` before generating any client-facing or internal output. Never use AI-attribution signatures. Closing line when needed: `ICCI, LLC — Secure. Governed. Operational.`

4. **NO HARD RETURNS MID-SENTENCE** — Each paragraph is one long line. Let the renderer handle wrapping. This is non-negotiable across all ICCI output.

5. **CROSS-SKILL AWARENESS** — Every skill must know what other skills and MCPs exist. Build delegation patterns so skills call each other for domain expertise rather than duplicating logic. Read `references/cross-skill-delegation.md` for the discovery protocol.

6. **VERSION EVERYTHING** — Every skill gets a `VERSION` file, a `CHANGELOG.md` or version history section, and follows semantic versioning. Run `version-check.sh` on first trigger. Always create NEW commits, never amend.

7. **LEFTHOOK + PRETTIER** — Every skill repo uses the standard `lefthook.yml` (Prettier pre-commit, repo privacy pre-push). Copy from `templates/lefthook.yml.template` if building a standalone repo.

8. **COMMENTS AND DOCUMENTATION** — Every script gets the ICCI header template (see `references/icci-skill-standards.md`). Every skill gets a `USAGE.md` with real examples. Every skill gets a `README.md` with the origin prompt that created it.

9. **LESSONS LEARNED** — Every skill gets an append-only `LESSONS-LEARNED.md`. Update it after every session where something unexpected happened or a new pattern was discovered. Never delete entries.

10. **DESTRUCTIVE OPERATIONS** — Count affected items, display in **BOLD**, wait for explicit "yes". Default to CANCEL.

## Skill Creation Lifecycle

### Phase 1: Capture Intent

Understand what the user wants the skill to do. Extract from conversation history if the workflow is already demonstrated.

Questions to resolve before writing anything:

- What does this skill enable Claude to do?
- What user phrases/contexts should trigger it?
- What APIs, MCPs, or external tools does it need?
- Does it produce formatted output (→ branding required)?
- Does it need credentials at runtime (→ session prompt pattern)?
- Which existing skills or MCPs overlap with its domain?

### Phase 2: Research the Domain

Before writing a single line:

1. **Check Anthropic's skill-creator for updates** — Read `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/skill-creator/skills/skill-creator/SKILL.md` and compare patterns against current ICCI standards. Integrate any new best practices.

2. **Search for API documentation** — If the skill talks to an API, find official docs, community notes, known quirks, rate limits, pagination patterns, and error codes. Document everything in a new `api-reference.md` in the target skill's references/ directory. See this skill's `references/api-documentation-guide.md` for the standard format.

3. **Scan existing skills and MCPs** — Read the SKILL.md descriptions of all skills in `~/.claude/skills/` and all MCPs in Claude's tool list. Map overlaps and delegation points. Document in the new skill's cross-skill section.

4. **Search for community wisdom** — Look for blog posts, GitHub discussions, and forum threads about the domain. Document gotchas and undocumented behavior.

### Phase 3: Scaffold the Skill

Run the scaffold script or create manually:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/scaffold-skill.sh <skill-name>
```

This creates the full ICCI-standard directory structure with all required files pre-populated from templates.

**Standard structure:**

```
skill-name/
├── SKILL.md                 # Main instructions (required, <500 lines)
├── USAGE.md                 # Examples and recipes (required)
├── README.md                # Origin prompt + team overview (required)
├── VERSION                  # Semantic version (required)
├── LESSONS-LEARNED.md       # Append-only institutional memory (required)
├── LICENSE.txt              # Proprietary notice (required)
├── references/              # Progressive disclosure docs (as needed)
│   ├── api-reference.md     # API docs, quirks, pagination
│   ├── branding-config.md   # Branding paths and rules
│   └── recipes.md           # Common workflow recipes
├── config/                  # Runtime config (as needed, .gitignore secrets)
├── scripts/                 # Helper scripts (as needed)
├── assets/                  # Logos, templates (as needed)
└── evals/                   # Test cases (recommended)
    └── evals.json
```

### Phase 4: Write the SKILL.md

Read `references/icci-skill-standards.md` for the complete checklist. Key points:

**Frontmatter:**

- `name`: lowercase, hyphens, max 64 chars
- `description`: Be pushy — include what the skill does AND aggressive trigger contexts with specific phrases users would say. Claude undertriggers; compensate by listing keywords, synonyms, and edge-case scenarios.
- `user-invocable: true` for slash-command skills
- `argument-hint`: Show what args look like

**Body structure:**

1. One-paragraph purpose statement
2. Critical Rules (numbered, most important first)
3. Quick Reference table (key paths, IDs, config values)
4. Core Workflows (the main procedures)
5. Reference Files section (when to read each one)
6. Cross-Skill Delegation section (what to delegate, to whom)
7. Self-Improvement Protocol

**Writing style:**

- Explain the WHY behind rules — Claude responds better to reasoning than rigid MUSTs
- Use imperative form ("Configure the server" not "You should configure")
- Keep under 500 lines; move detail to `references/`
- Include examples inline for critical patterns

**Progressive disclosure (three levels):**

1. **Metadata** (~100 words) — always in context (name + description)
2. **SKILL.md body** — loaded when skill triggers (<500 lines)
3. **references/** — loaded on demand (unlimited; scripts execute without loading)

### Phase 5: Build the Ecosystem Awareness

Every ICCI skill must include a section that maps its relationship to other skills and MCPs. This is what enables intelligent delegation instead of duplication.

**Discovery protocol (build into every skill):**

1. On first trigger, read `~/.claude/skills/*/SKILL.md` frontmatter (name + description only)
2. Read available MCP tool names from the conversation context
3. When the user asks for something outside this skill's domain, delegate to the appropriate skill or MCP
4. Never re-engineer functionality that another skill already provides

**Example delegation pattern:**

```
User asks for a DI-Shepherd report to attach to a HappyFox ticket.
→ This skill delegates to di-shepherd for the report
→ Then delegates to icci-happyfox to create/update the ticket
→ Never calls happyfox MCP tools directly (skill wraps MCP with safety protocol)
```

### Phase 6: Credential Security

Read `references/security-checklist.md` for the complete protocol. Key pattern:

```markdown
## Credential Handling

On first use each session:

1. Check if API key is available in environment variable `{SKILL}_API_KEY`
2. If not, ask the user: "This skill needs a {service} API key. Provide it now (it will be held in memory for this session only, never written to disk)."
3. Validate the key with a lightweight API call before proceeding
4. If validation fails, report the error and ask for a corrected key
```

Never write credentials to: SKILL.md, config files, scripts, VERSION, LESSONS-LEARNED, or any file that could be committed to git.

### Phase 7: Write Supporting Files

1. **USAGE.md** — Real examples of the skill's most useful capabilities. Not abstract — show actual commands, actual output, actual workflows. See `templates/USAGE.md.template`.

2. **README.md** — Include the origin prompt (spell-checked, as a blockquote) that created the skill. This is training material for the team. See `templates/README.md.template`.

3. **LESSONS-LEARNED.md** — Start with an initial entry documenting the creation context. See `templates/LESSONS-LEARNED.md.template`.

4. **VERSION** — Start at `1.0.0`. Format: version number on line 1, changelog entries below.

5. **LICENSE.txt** — Proprietary ICCI notice.

6. **references/** — One file per topic. Include `branding-config.md` if skill produces formatted output.

### Phase 8: Validate

Run the validation script:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/validate-skill.sh <path-to-skill>
```

This checks: structure, frontmatter, file references, line counts, credential leaks, branding integration, cross-skill section, VERSION file, and ICCI conventions.

Manual validation checklist:

- [ ] SKILL.md has valid YAML frontmatter with name + description
- [ ] Description is pushy with specific trigger phrases
- [ ] Body uses imperative form, not second person
- [ ] Under 500 lines (detail moved to references/)
- [ ] No credentials anywhere in the skill directory
- [ ] Cross-skill delegation section present
- [ ] USAGE.md exists with real examples
- [ ] README.md exists with origin prompt
- [ ] VERSION file exists
- [ ] LESSONS-LEARNED.md exists
- [ ] All referenced files actually exist
- [ ] Branding integration if skill produces formatted output
- [ ] Destructive operation safety pattern where applicable
- [ ] No hard returns mid-sentence in any .md file

### Phase 9: Test (Eval Loop)

Follow the Anthropic skill-creator's eval methodology:

1. Create 2-3 realistic test prompts in `evals/evals.json`
2. Spawn parallel subagent runs (with-skill + baseline) if available
3. Draft quantitative assertions while runs execute
4. Grade results, aggregate into benchmark
5. Launch eval viewer for human review
6. Read feedback, improve, repeat

See `references/anthropic-patterns.md` for the full eval/benchmark workflow adapted from Anthropic's skill-creator.

### Phase 10: Finalize and Ship

1. Run `validate-skill.sh` one final time
2. Copy skill to `~/Documents/GitHub/icci-skills/skills/{skill-name}/`
3. Verify repo privacy: `gh repo view icci/icci-skills --json isPrivate -q '.isPrivate'`
4. Create symlink: `ln -s ~/Documents/GitHub/icci-skills/skills/{skill-name} ~/.claude/skills/{skill-name}`
5. Commit with descriptive message
6. Push to origin/main
7. Update `~/Documents/GitHub/icci-skills/README.md` to add the new skill to the table
8. Update `~/Documents/GitHub/icci-skills/INSTALL.md` with any skill-specific setup notes

## Reference Files

Read these as needed during skill creation:

- **`references/icci-skill-standards.md`** — Complete ICCI skill requirements checklist, script header template, naming conventions, directory standards
- **`references/anthropic-patterns.md`** — Best practices from Anthropic's skill-creator: eval methodology, description optimization, progressive disclosure, writing patterns
- **`references/security-checklist.md`** — Credential handling, repo privacy, secret scanning, runtime security
- **`references/cross-skill-delegation.md`** — How skills discover each other, delegation protocol, MCP routing rules, anti-patterns
- **`references/branding-integration.md`** — How to wire up ICCI report branding, required files, color/font/logo references
- **`references/api-documentation-guide.md`** — Standard format for documenting APIs: endpoints, auth, pagination, rate limits, quirks, error codes

## Templates

Pre-populated templates for new skills in `templates/`:

- `SKILL.md.template` — ICCI-standard SKILL.md with all required sections
- `USAGE.md.template` — Usage guide structure with example patterns
- `README.md.template` — README with origin prompt section
- `LESSONS-LEARNED.md.template` — Initial entry template
- `lefthook.yml.template` — Standard git hooks config
- `prettierrc.template` — Standard Prettier config

## Self-Improvement Protocol

After every skill creation or improvement session:

1. Update `LESSONS-LEARNED.md` with new patterns discovered
2. Update reference files if standards evolved
3. Update templates if new patterns should be default
4. Check Anthropic's skill-creator for new features
5. Sync changes to GitHub (verify privacy first)
