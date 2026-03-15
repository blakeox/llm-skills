# LLM Skills Installation

## GitHub Copilot CLI

```bash
git clone https://github.com/blakeox/llm-skills.git ~/Documents/GitHub/llm-skills
mkdir -p ~/.copilot/skills
for skill in api-review dep-audit onboarding-audit paranoid-review plan-eng-review plan-product-review postmortem retro section-review ship tech-debt; do
  rsync -a ~/Documents/GitHub/llm-skills/skills/$skill/ ~/.copilot/skills/$skill/
done
```

After copying the skills, restart Copilot CLI or start a new session.

## Verify

```bash
ls -la ~/.copilot/skills
```

You should see the published skill directories listed above.

## Update later

```bash
cd ~/Documents/GitHub/llm-skills
git pull
for skill in api-review dep-audit onboarding-audit paranoid-review plan-eng-review plan-product-review postmortem retro section-review ship tech-debt; do
  rsync -a ~/Documents/GitHub/llm-skills/skills/$skill/ ~/.copilot/skills/$skill/
done
```
