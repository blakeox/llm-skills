# LLM Skills

Public home for Blake Oxford's open-source workflow and review skills.

## Included skills

- `api-review`
- `dep-audit`
- `onboarding-audit`
- `paranoid-review`
- `plan-eng-review`
- `plan-product-review`
- `postmortem`
- `retro`
- `section-review`
- `ship`
- `tech-debt`

These are the ICCI-originated skills currently approved for publication in this repository.

## Install for GitHub Copilot CLI

```bash
git clone https://github.com/blakeox/llm-skills.git ~/Documents/GitHub/llm-skills
mkdir -p ~/.copilot/skills
for skill in api-review dep-audit onboarding-audit paranoid-review plan-eng-review plan-product-review postmortem retro section-review ship tech-debt; do
  rsync -a ~/Documents/GitHub/llm-skills/skills/$skill/ ~/.copilot/skills/$skill/
done
```

Start a new Copilot session after installing or updating the skills so they get picked up.

## Repository layout

```text
llm-skills/
└── skills/
    ├── api-review/
    ├── dep-audit/
    ├── onboarding-audit/
    ├── paranoid-review/
    ├── plan-eng-review/
    ├── plan-product-review/
    ├── postmortem/
    ├── retro/
    ├── section-review/
    ├── ship/
    └── tech-debt/
```
