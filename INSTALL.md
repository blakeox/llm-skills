# LLM Skills Installation

## GitHub Copilot CLI

```bash
git clone https://github.com/blakeox/llm-skills.git ~/Documents/GitHub/llm-skills
cd ~/Documents/GitHub/llm-skills
./scripts/install-copilot-skills.sh
./scripts/verify-copilot-skills.sh
```

After installing, start a new Copilot CLI session so the updated skills are loaded.

## Verify manually

```bash
ls -la ~/.copilot/skills
```

You should see `_house-style` plus the directories listed in `skills/manifest.txt`.

## Update later

```bash
cd ~/Documents/GitHub/llm-skills
git pull
./scripts/install-copilot-skills.sh
./scripts/verify-copilot-skills.sh
```

## Notes

- The canonical published skill list lives in `skills/manifest.txt`.
- `scripts/install-copilot-skills.sh` uses `rsync -a --delete` so removed files are cleaned up locally.
- `scripts/verify-copilot-skills.sh` checks for `_house-style` reference files and `SKILL.md` in each published skill.
