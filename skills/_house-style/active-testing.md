# Active testing safety contract

Read this before running setup commands, tests, adversarial requests, migrations, package installers, or any command that can change files, data, services, or external state.

## Authority and environment

1. Resolve the exact target and environment before execution.
2. Default to a local, disposable, or explicitly authorized test environment.
3. Treat production, shared infrastructure, external APIs, and real customer data as out of scope unless the user explicitly authorizes the exact active test.
4. Inspect scripts before running them. Do not assume `setup`, `test`, or `dev` commands are read-only.
5. Never request, print, or persist real credentials. Use documented test credentials or fixtures.

## Containment

- Bound request volume and concurrency.
- Do not send injection payloads, invalid authentication, traversal input, destructive requests, or duplicate writes to a live/external target without explicit authorization.
- Verify database host, database name, account/project, and environment before any write, truncate, migration, or cleanup.
- Do not install global packages or provision services as part of an audit.
- Preserve unrelated dirty worktree changes. Never delete untracked or user-owned data.
- Clean up only artifacts created by the current run, and record what was removed.

## Fallback

When active testing is unsafe or unavailable, perform static or contract review, mark runtime behavior `Not verified`, and state the smallest safe proof step.
