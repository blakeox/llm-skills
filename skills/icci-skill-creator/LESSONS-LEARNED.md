# Lessons Learned

Append-only institutional memory. Never delete entries — add new entries at the top.

## 2026-03-13 — Skill Creation

- Created by Aaron Salsitz with Claude Opus 4.6
- Origin prompt captured in README.md
- Built by reading all 9 existing ICCI skills, the icci-report-branding repo, Anthropic's skill-creator plugin, and Anthropic's skill-development reference
- Key design decisions:
  - 10-phase lifecycle (capture → research → scaffold → write → ecosystem → security → support → validate → test → ship)
  - Cross-skill delegation is a first-class requirement, not an afterthought — every skill must include an ecosystem awareness section
  - Credential security built into the creation process itself, not bolted on after
  - Templates pre-populate all ICCI conventions so new skills start compliant
  - Validator script catches gaps before human review
  - Anthropic's eval methodology integrated but adapted — ICCI skills need branding, security, and delegation checks that Anthropic's generic tool doesn't cover
