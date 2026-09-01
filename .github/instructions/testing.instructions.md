---
applyTo: "**/*.test.*,**/*.spec.*,**/tests/**,**/__tests__/**"
---

# Test Coding Standards

## Structure
- Follow Arrange-Act-Assert (AAA) strictly; separate each section with a blank line.
- One logical assertion per test — if you need to assert multiple things, use a single compound
  assertion (e.g., `expect(result).toEqual(…)`) or split into multiple tests.
- Keep tests short; if a test exceeds ~40 lines, extract helpers or split it.

## Naming
- Name tests using the pattern `should_<expected behaviour>_when_<condition>`.
- Group related tests under `describe` blocks named after the unit under test.
- Test names must read as plain English sentences without needing to see the code.

## Test Data
- Use factory functions or builder objects to create test data; never hardcode raw IDs, UUIDs,
  or magic strings inline.
- Generate unique identifiers with a factory, not a fixed string like `"user-123"`.
- Keep fixture data minimal — only set fields that the test actually cares about.

## Isolation and Idempotency
- Tests must be fully independent — no shared mutable state between tests.
- Tests must be idempotent — running the same test twice in a row must produce the same result.
- Reset all mocks, spies, and stubs before or after each test (use `beforeEach`/`afterEach`).
- Never depend on test execution order.

## Mocking
- Mock at the boundary of the unit under test (HTTP client, DB adapter, external service interface).
- Do not mock internals or private methods; if you feel the need to, refactor instead.
- Prefer dependency injection over module-level mocking so mocks are explicit.
- Verify that mocks are called with the expected arguments, not just that they were called.

## Timing and Async
- Never use `Thread.Sleep`, `setTimeout`, or `asyncio.sleep` to wait for async work in tests.
- Use fake/virtual timers (e.g., `jest.useFakeTimers()`, `FakeTimeProvider` in .NET, `freezegun`
  in Python) to control time deterministically.
- Use `await`, `waitFor`, or appropriate async test utilities — never fire-and-forget.

## What to Test
- Test the public interface, not implementation details.
- Do not test private methods directly; if they need testing, extract them to a testable unit.
- Avoid snapshot tests except for stable, human-reviewed output (e.g., rendered HTML templates).
- Prefer integration tests over heavy mocking for database and HTTP interaction.

## Performance Targets
- Unit tests must complete in under 50 ms each.
- Integration tests should complete in under 2 s each.
- If a test regularly exceeds these thresholds, investigate and optimize before merging.
