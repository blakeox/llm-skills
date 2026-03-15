# ICCI Skill Creator

> Good morning Claude. Please look through all of the skills in the ICCI GitHub organization. Read through all of these skills for ICCI we have created. I want to create a new ICCI skill with you. The skill is an icci-skill-creator skill. This skill needs to have the best practices we developed over all the skills we created, most of which I asked you to base on the Anthropic skill creator skill. I definitely want this new ICCI skill to check to see if Anthropic updated their skill creator skill and integrate and refactor in the best parts. The ICCI skill creator skill should include the requirements of using the icci-report-branding library which has a .md file with your instructions to yourself so client-facing output and internal reports are branded the same when branding is necessary. I love that you create memory and lessons. You are always learning. Using lefthook and Prettier are awesome before commits. Comments are a must and versioning is always the way. A simple guardrail would be not to store credentials in a skill and build into the skill creator asking the user for the credential (API key etc.) during each Claude session. Obviously, it's okay to store the key in memory or other temporary way. Look for the most cutting-edge skill writing advice available from Anthropic and from the community. Implement best practice for security. Always when building a skill, look for company and community API notes, usage, quirks and document it. Always create a usage .md file with examples of the coolest and most useful things the skill can do. Skills should be aware of the MCPs and other skills around them by reading their information to see if what the user is asking is best handled by a skill or MCP. Example: when I created the HappyFox skill, it is tied to the HappyFox MCP, but when I pull a DI-Shepherd report for an issue, I want the skill to know how to use the helpdesk skill before re-engineering the skill and talking to the MCP. The only way this can work is if all the skills and MCPs know about each other.

## Overview

The ICCI Skill Creator is a meta-skill that guides Claude through building new ICCI skills that are secure, branded, version-controlled, self-improving, and ecosystem-aware. It codifies every pattern learned from building 9 production ICCI skills and integrates the best practices from Anthropic's official skill-creator plugin.

## Prerequisites

- **Claude Code** installed
- **GitHub access** to the `icci` organization
- **Anthropic skill-creator plugin** installed (for eval/benchmark tooling)
- **lefthook** and **Prettier** installed for git hooks

## Installation

```bash
# From icci-skills monorepo (recommended):
ln -s ~/Documents/GitHub/icci-skills/skills/icci-skill-creator ~/.claude/skills/icci-skill-creator
```

## Usage

See **[USAGE.md](USAGE.md)** for detailed examples and recipes.

**Quick start:** `/icci-skill-creator build a skill for [your domain]`

## Changelog

See **[VERSION](VERSION)** for version history.
