# LLM Skills

Public home for Blake Oxford's open-source workflow and review skills.

## Included skills

- `_house-style`
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
cd ~/Documents/GitHub/llm-skills
./scripts/install-copilot-skills.sh
./scripts/verify-copilot-skills.sh
```

The canonical published set lives in `skills/manifest.txt`. The install script syncs each listed directory with `rsync -a --delete` so stale local files do not linger.

Start a new Copilot session after installing or updating the skills so they get picked up.

## Update later

```bash
cd ~/Documents/GitHub/llm-skills
git pull
./scripts/install-copilot-skills.sh
./scripts/verify-copilot-skills.sh
```

## Repository layout

```text
llm-skills/
├── scripts/
│   ├── install-copilot-skills.sh
│   └── verify-copilot-skills.sh
└── skills/
    ├── manifest.txt
    ├── _house-style/
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
