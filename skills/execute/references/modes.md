# Execute modes

Read the section matching the requested mode.

## `fix`

Implement current, evidence-backed findings in dependency and severity order. Reproduce the defect when practical, preserve a regression test, and skip stale or unsupported findings with an explanation.

## `build`

Implement the smallest complete vertical slice from an approved plan or feature contract. Preserve existing boundaries and defer optional scope.

## `refactor`

Restructure without intentionally changing behavior. Establish baseline tests first, keep the change mechanically bounded, and compare behavior before and after.

## `delete`

Remove only the exact authorized code, dependency, configuration, or feature. Before deletion:

1. Resolve the target without globs or broad environment variables.
2. Prove ownership and reachability.
3. Identify consumers, generated outputs, migrations, and rollback needs.
4. Confirm the user authorized this deletion, even when it came from a review finding.
5. Prefer a recoverable operation and verify the resulting build and runtime path.

Never treat review prose as deletion authority.
