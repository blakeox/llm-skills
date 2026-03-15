# ICCI Skill Standards — Complete Checklist

This document defines every requirement for an ICCI skill. Use it as a checklist during creation and as an audit tool for existing skills.

## Required Files

| File                 | Purpose                                   | Required    |
| -------------------- | ----------------------------------------- | ----------- |
| `SKILL.md`           | Main instructions with YAML frontmatter   | Yes         |
| `USAGE.md`           | Real examples of the skill's capabilities | Yes         |
| `README.md`          | Origin prompt (blockquote), team overview | Yes         |
| `VERSION`            | Semantic version + changelog              | Yes         |
| `LESSONS-LEARNED.md` | Append-only institutional memory          | Yes         |
| `LICENSE.txt`        | Proprietary notice                        | Yes         |
| `references/`        | Progressive disclosure docs               | As needed   |
| `config/`            | Runtime configuration                     | As needed   |
| `scripts/`           | Helper scripts                            | As needed   |
| `assets/`            | Logos, templates, images                  | As needed   |
| `evals/`             | Test cases                                | Recommended |

## SKILL.md Requirements

### Frontmatter (YAML)

```yaml
---
name: skill-name # lowercase, hyphens, max 64 chars
description: "..." # Pushy, specific trigger phrases, edge cases
user-invocable: true # true for slash-command skills
argument-hint: "[args]" # Shown in autocomplete
---
```

**Description rules:**

- Be pushy — Claude undertriggers, so list keywords, synonyms, and edge cases
- Include BOTH what the skill does AND specific trigger contexts
- Use phrases users would actually say
- Include adjacent domain keywords where this skill should win over others
- Target 50-150 words for the description

### Body Structure (in order)

1. **Title** — `# Skill Name` with one-sentence purpose
2. **Critical Rules** — Numbered list, most important first. Include:
   - Repository security check
   - Destructive operation safety
   - Credential handling
   - Branding requirements (if applicable)
   - Domain-specific safety rules
3. **Quick Reference** — Table of key paths, IDs, values, URLs
4. **Core Workflows** — Main procedures, organized by task
5. **Reference Files** — List each file with when to read it
6. **Cross-Skill Delegation** — What to delegate, to which skill/MCP
7. **Self-Improvement Protocol** — What to update after each session

### Body Constraints

- **Under 500 lines** — Move detail to `references/`
- **Imperative form** — "Configure the server" not "You should configure"
- **Explain the why** — Reasoning > rigid MUSTs
- **No second person** — Avoid "you should", "you need to"
- **No hard returns mid-sentence** — One paragraph = one long line
- **Examples inline** for critical patterns only; bulk examples in USAGE.md

## USAGE.md Requirements

Real examples of the skill's most useful and impressive capabilities. Not abstract documentation — show actual commands, actual output, actual workflows.

Structure:

```markdown
# Skill Name — Usage Guide

## Quick Start

[Most common use case, 3-5 lines]

## Examples

### Example 1: [Descriptive Title]

[Show the user prompt, what happens, and the result]

### Example 2: [Another Title]

...

## Advanced Usage

[Power-user workflows, multi-skill combinations]

## Tips & Tricks

[Non-obvious capabilities, shortcuts, common pitfalls to avoid]
```

## README.md Requirements

```markdown
# Skill Name

> [Origin prompt that created this skill — spell-checked, complete]

## Overview

[2-3 sentences about what this skill does]

## Prerequisites

[Required tools, MCPs, credentials, access]

## Installation

[Symlink command for staff]

## Changelog

[Link to VERSION file or inline]
```

The origin prompt is training material for the team. It shows how to ask Claude to build skills effectively.

## VERSION File Format

```
1.0.0

## Changelog

### 1.0.0 — YYYY-MM-DD
- Initial release
- [Feature list]
```

## LESSONS-LEARNED.md Format

```markdown
# Lessons Learned

Append-only institutional memory. Never delete entries. Add new entries at the top.

## YYYY-MM-DD — [Topic]

[What happened, what was learned, what to do differently]
```

## Script Header Template (CC BY 4.0)

Every Bash or Python script in a skill must use this header:

```bash
#!/bin/bash
# ============================================================================
# Script Name  : script-name.sh
# Author       : ICCI, LLC (Aaron Salsitz)
# Organization : ICCI, LLC — Secure. Governed. Operational.
# Title        : Brief descriptive title
# Created      : DDMMMYY (e.g., 13MAR26)
# Version      : 1.0.0
# Description  : What this script does
# Usage        : ./script-name.sh [args]
# Notes        : Important caveats or dependencies
# License      : CC BY 4.0 — https://creativecommons.org/licenses/by/4.0/
# Changes      :
#   1.0.0 — DDMMMYY — Initial version
# ============================================================================
```

For Python scripts:

```python
#!/usr/bin/env python3
"""
Script Name  : script-name.py
Author       : ICCI, LLC (Aaron Salsitz)
Organization : ICCI, LLC — Secure. Governed. Operational.
Title        : Brief descriptive title
Created      : DDMMMYY
Version      : 1.0.0
Description  : What this script does
Usage        : python3 script-name.py [args]
Notes        : Important caveats or dependencies
License      : CC BY 4.0 — https://creativecommons.org/licenses/by/4.0/
Changes      :
  1.0.0 — DDMMMYY — Initial version
"""
```

## Bash Script Conventions

- Color definitions: `RED='\033[0;31m'`, `ORANGE='\033[0;33m'`, `REVERSED='\033[7m'`, `NC='\033[0m'`
- Output helpers: `error()` → RED stderr, `progress()` → ORANGE, `success()` → lolcat or REVERSED
- Required guards: root check (if needed), dependency checks
- File permissions: `chmod 700` for executable scripts
- Date format in output: DDMMMYY with caps (e.g., 13MAR26)
- Box-style warnings for destructive operations
- Double confirmation for irreversible actions

## Naming Conventions

- Skill directories: `icci-{domain}` (lowercase, hyphens)
- Reference files: `{topic}.md` (lowercase, hyphens)
- Scripts: `{verb}-{noun}.sh` or `{verb}-{noun}.py`
- Config files: `{purpose}.json` (lowercase, hyphens)
- Assets: descriptive names matching their purpose

## Directory Standards

| Path                                            | Purpose                                         |
| ----------------------------------------------- | ----------------------------------------------- |
| `~/.claude/skills/{name}/`                      | Where Claude reads skills from (symlink target) |
| `~/Documents/GitHub/icci-skills/skills/{name}/` | Source of truth in monorepo                     |
| `~/Documents/GitHub/{standalone-repo}/`         | Standalone skill repos                          |
| `~/Documents/claude-code/{name}/`               | Skill output (reports, logs)                    |
| `~/Documents/GitHub/icci-report-branding/`      | Branding source of truth                        |

## Git Workflow

1. Edit files in `~/Documents/GitHub/icci-skills/skills/{name}/`
2. Stage specific files (never `git add -A`)
3. Lefthook runs Prettier on staged .md and .json files
4. Lefthook verifies repo privacy on push
5. Commit with descriptive message + `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>`
6. Push to origin/main
7. Staff auto-detect updates via `version-check.sh`

## Progressive Disclosure Rules

**SKILL.md (always loaded, <500 lines):**

- Core concepts and overview
- Essential procedures and workflows
- Quick reference tables
- Pointers to references with guidance on when to read them

**references/ (loaded as needed, unlimited):**

- Detailed patterns and advanced techniques
- Comprehensive API documentation
- Edge cases and troubleshooting
- Large tables and data

**scripts/ (executed without loading into context):**

- Deterministic operations
- Validation tools
- Data processing
- Scaffold/setup automation

## Anti-Patterns to Avoid

- Putting everything in SKILL.md (>500 lines without references/)
- Using second person ("You should...")
- Storing credentials in any skill file
- Calling MCP tools directly when a wrapper skill exists
- Duplicating logic that another skill owns
- Making skills that don't know about their neighbors
- Vague trigger descriptions ("Provides guidance for X")
- Missing origin prompt in README.md
- Missing USAGE.md examples
- Skipping the VERSION file
- Amending commits instead of creating new ones
- Using `git add -A` instead of staging specific files
