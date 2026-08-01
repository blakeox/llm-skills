---
name: dep-audit
description: Zero-assumption dependency audit. Use when reviewing a manifest, lockfile, proposed package, or dependency portfolio for vulnerabilities, maintenance status, license risk, bus factor, bundle or runtime cost, upgrade exposure, and whether each dependency should exist at all.
user-invocable: true
argument-hint: "[package.json, requirements.txt, or specific dependency]"
---

Read `../_house-style/house-style.md` before starting.

Verify vulnerability, release, maintenance, license, and size claims against current primary advisories, package registries, project repositories, and license texts. Record the source and check date. Do not reuse version facts or migration estimates from examples.

## Anchor phrases

- Every dependency is code you didn't write, maintained by someone you don't control, with bugs you haven't found yet.
- "Everyone uses it" was also true of left-pad.
- If you can replace it in 50 lines, the supply chain risk isn't worth it.
- A dependency maintained by one person is one burnout away from abandoned.

## Domain-specific examples

**Dependency verdict — wrong way:**

"Moment.js is a widely-used date library that's been around for years. It's not actively maintained anymore but it should be fine for most use cases. You might want to consider migrating at some point."

**Dependency verdict — right way:**

"**Remove.** The inspected version is used only for display formatting, and current source-backed bundle and maintenance evidence does not justify it. Replace with `Intl.DateTimeFormat` when it satisfies the observed call sites. Migration complexity: Low, subject to parsing and locale tests."

**False necessity — wrong way:**

"Lodash is a useful utility library that provides a lot of helpful functions."

**False necessity — right way:**

"`lodash` (587KB full) — you import 4 functions: `get`, `debounce`, `cloneDeep`, `groupBy`. `get` → optional chaining (`?.`), native since ES2020. `debounce` → 15-line implementation or `use-debounce` (2KB). `cloneDeep` → `structuredClone()`, native since 2022. `groupBy` → `Object.groupBy()`, native since 2024. All 4 uses have native replacements. Delete the dependency entirely. If you must keep one, import individually (`lodash.debounce`, 1KB) not the full package."

## Per-dependency audit

For each: Security (CVEs, supply chain), Maintenance (last release, bus factor), Necessity (what you use, could you inline it), Cost (bundle, license).

## Output format

### Summary
Total deps, issues found, recommended removals.

### Dependency table

| Dep | Version | Used for | Last release | Maintainers | CVEs | Size | Verdict |
|---|---|---|---|---|---|---|---|

Verdict: **Keep** / **Replace** (with what) / **Remove** (why) / **Urgent** (CVE/abandoned)

### Critical findings
CVEs, abandoned deps in critical paths, license risks.

### Disaster waiting to happen
Deps that work today but are structurally guaranteed to become problems.

### Unnecessary dependencies
What to delete or inline. Lines of code to replace, specific alternative.

### Devil's advocate
For deps you flagged for removal: is there a non-obvious reason to keep them?

### What I didn't check / Action items
