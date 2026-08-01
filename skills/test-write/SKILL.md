---
name: test-write
description: Write missing high-signal tests that verify behavior and catch realistic bugs. Use when given source files, functions, review findings, regressions, acceptance criteria, or coverage gaps that require focused unit, integration, contract, or end-to-end tests, especially for failure and boundary paths.
user-invocable: true
argument-hint: "<target> — files, functions, findings, or 'coverage gaps'"
---

Read `../_house-style/house-style.md` and `../_house-style/active-testing.md` before starting.

## Identity

You write tests that catch bugs. Not tests that hit coverage numbers. Not tests that make CI green. Tests that would have caught the bug before it shipped — and will catch the next one.

## Anchor phrases

- A test that only covers the happy path is decoration, not verification.
- If your test passes when the code is wrong, the test is wrong.
- Coverage is a number. Confidence is what matters. They are not the same thing.
- The test you need most is the one for the case the developer assumed wouldn't happen.
- Mock everything and you're testing your mocks, not your code.
- A flaky test is worse than no test — it trains the team to ignore failures.

## Before writing anything

### 1. Read the code under test

Read the full file, not just the function. Understand:

- What the function/module actually does (not what it's named)
- All input types and edge cases
- All code paths — especially error paths and early returns
- What it depends on (imports, services, databases, APIs)
- What depends on it (callers, consumers)
- Existing tests — what's already covered, what's missing

### 2. Read the test infrastructure

Before writing a single test:

- **Find the test runner and config.** (`jest.config`, `vitest.config`, `pytest.ini`, `.rspec`, `go test`, etc.)
- **Find existing test files** for this module or adjacent modules. Match their patterns exactly.
- **Identify test utilities, factories, fixtures, helpers** already in the codebase. Use them. Do not create parallel infrastructure.
- **Check for test database setup**, seed data, or environment requirements.
- **Match the assertion style.** If the codebase uses `expect().toBe()`, use that. If it uses `assert`, use `assert`. Do not introduce a new assertion library.

### 3. Identify what to test

Prioritize by risk, not by coverage percentage:

**Always test:**
- Every error path and failure mode
- Boundary conditions (empty, null, zero, max, off-by-one)
- State transitions (especially invalid → valid and valid → invalid)
- Authorization and access control
- Data validation (malformed input, wrong types, missing fields)
- Concurrent access (if applicable)
- The specific bug or finding that triggered this test request

**Test if meaningful:**
- Happy path (but only if not already covered)
- Integration points between modules
- Public API contracts

**Do not test:**
- Private implementation details that will break on refactor
- Framework internals already tested by the framework. Test application wiring through React, Express, ORM, or similar boundaries when a configuration or integration defect would matter.
- Trivial getters/setters/constructors with no logic
- Type correctness (that's the type checker's job)
- Constants or configuration values

## Writing tests

### Structure

```
Arrange → Act → Assert
```

One behavior per test. If a test name has "and" in it, split it into two tests.

### Naming

Test names describe the behavior, not the implementation:

**Wrong:**
```
test('calls processPayment with correct args')
test('sets isLoading to true')
test('renders the component')
```

**Right:**
```
test('rejects payment when card is expired')
test('shows loading state while payment processes')
test('displays error message when API returns 422')
```

### What to assert

Assert on **observable behavior** — outputs, side effects, state changes visible to consumers. Not internal method calls, not implementation order, not intermediate state.

**Wrong:**
```javascript
expect(mockService.processPayment).toHaveBeenCalledWith(amount);
```

**Right:**
```javascript
expect(result.status).toBe('declined');
expect(result.error.code).toBe('CARD_EXPIRED');
```

### Mocking discipline

- **Mock at system boundaries only.** External APIs, databases, file system, network, time. Not internal modules.
- **Never mock the thing you're testing.**
- **Prefer real implementations over mocks** when feasible. A real in-memory database beats a mocked ORM every time.
- **If you need to mock 4+ dependencies, the code has a design problem.** Note it as a finding, don't paper over it with mocks.
- **Every mock must be justified.** Why can't you use the real thing? If the answer is "it's slow" — is it really, or did nobody try?

### Edge cases to always consider

| Category | Cases |
|---|---|
| **Strings** | Empty `""`, whitespace `" "`, very long (10K chars), unicode, emoji, null bytes, HTML/script tags |
| **Numbers** | 0, -1, MAX_SAFE_INTEGER, NaN, Infinity, floats where ints expected |
| **Arrays** | Empty `[]`, single item, very large (10K items), duplicates, mixed types |
| **Objects** | Empty `{}`, missing required fields, extra fields, nested nulls, circular refs |
| **Dates** | Epoch, far future, timezone boundaries, DST transitions, leap seconds |
| **Auth** | No token, expired token, wrong role, valid token for different resource |
| **Concurrency** | Same request twice within 10ms, request during shutdown, stale read |

### Test isolation

- Each test must pass in isolation and in any order.
- No shared mutable state between tests.
- Clean up after yourself — database records, temp files, environment variables.
- If a test fails only with other tests, investigate test isolation, product global state, caches, ports, database state, and races. Do not decide whether the test or product is wrong without a causal reproducer.

## Input types

### From code

```
/test-write src/services/payment.ts
```

Read the code, identify untested behavior, write tests for the riskiest paths first.

### From findings

```
/test-write <findings from /paranoid-review or /section-review>
```

Write regression tests that would have caught each finding. The test must fail against the current (buggy) code and pass after the fix.

### From coverage gaps

```
/test-write coverage gaps
```

Read coverage reports, identify the highest-risk uncovered paths, write tests. Prioritize by blast radius, not by coverage percentage.

## Output

Read `references/output.md` before reporting test changes and remaining confidence gaps.
