# ICCI HD Assistant

**Master Bit Herder Helpdesk Assistant**

ICCI's helpdesk communication skill — turns raw technical information into polished, professional client responses and internal documentation. Built for daily use by the entire ICCI team.

> **Origin prompt:**
>
> "We should create a Claude skill with the same instructions as the ICCI HD Assistant GPT. This is a writing filter to provide a clean response to customers. It should be self-learning like my other skills, use icci-report-branding, and follow modern best practices for skills used by master skill creators. This skill will get used every day."

## Capabilities

- **Client responses** — Polish rough drafts into professional, ICCI-branded communication
- **Ticket documentation** — Turn technician notes into clean internal records
- **Log analysis** — Extract findings from raw logs and produce structured summaries
- **Dual output** — Separate internal technical notes from client-facing updates
- **Communication filter** — Enforce ICCI tone, voice, and writing standards automatically
- **Self-learning** — Accumulates client preferences, successful phrasings, and corrections over time

## Usage

Invoke with `/icci-HD-assistant` or trigger naturally by asking Claude to draft a client response, polish a ticket reply, or analyze logs for a client update.

**Examples:**

```
/icci-HD-assistant Here's what the client said: [paste]. Here's what we found: [paste]. Write a response.
```

```
/icci-HD-assistant Polish this draft: [paste rough text]
```

```
/icci-HD-assistant Analyze these logs and give me an internal note + client update: [paste logs]
```

## Setup

1. **Clone to skills directory:**

   ```bash
   ln -s ~/Documents/GitHub/icci-HD-assistant ~/.claude/skills/icci-HD-assistant
   ```

   Or via the skills collection:

   ```bash
   ln -s ~/Documents/GitHub/icci-skills/skills/icci-HD-assistant ~/.claude/skills/icci-HD-assistant
   ```

2. **Report branding:** Ensure the branding repo is cloned:

   ```bash
   gh repo clone icci/icci-report-branding ~/Documents/GitHub/icci-report-branding
   ```

3. **Create output directory:**
   ```bash
   mkdir -p ~/Documents/claude-code/helpdesk/
   ```

## Repository Rules

- This repository MUST remain **private** at all times
- Verify before every push: `gh repo view icci/icci-HD-assistant --json isPrivate -q '.isPrivate'`
- Never commit client-specific data or ticket contents

## File Structure

```
icci-HD-assistant/
├── SKILL.md                        # Main skill file (Claude reads this)
├── README.md                       # This file
├── LICENSE.txt                     # Proprietary — ICCI LLC Internal Use Only
├── LESSONS-LEARNED.md              # Append-only institutional memory
├── .gitignore                      # Secrets, cache, OS files excluded
└── references/
    ├── branding-config.md          # Report branding repo paths and fallback values
    ├── tone-patterns.md            # Successful phrasings and corrections
    ├── templates.md                # Response templates for common scenarios
    ├── known-clients.md            # Client communication preferences
    └── technical-analysis.md       # Log analysis and structured output guidelines
```

## Lessons Learned

See [LESSONS-LEARNED.md](LESSONS-LEARNED.md) for institutional memory accumulated during real usage.

---

_ICCI, LLC — Secure. Governed. Operational._
_Veteran-owned MSP | 30+ years | Ann Arbor & Brighton, Michigan_
