# Project Name

## Build & test
```bash
# npm install
# npm test
# npm run lint
```

## Conventions
- [Add project-specific conventions here]

## Architecture
- [Add high-level architecture notes here]

## Specialist routing
See `~/.claude/rules/routing.md` for the full specialist bench. Common patterns for this project:
- Pre-merge: spawn `enforcer` + `builder`
- Bug fix: spawn `debugger` then `tester`
- New feature: spawn `product-mind` then `architect`
