---
applyTo: "**/*.py"
---

# Python Coding Standards

## Type Hints
- Always annotate function signatures with type hints — parameters and return types.
- Use `from __future__ import annotations` for forward references.
- Use `Optional[X]` or `X | None` (Python 3.10+) instead of bare `X` for nullable values.
- Use `TypeAlias` for complex repeated type expressions.

## Data Structures
- Prefer `dataclasses` (or `attrs`) over plain dicts for structured data.
- Use `@dataclass(frozen=True)` for immutable value objects.
- Use Pydantic `BaseModel` for any data crossing a trust boundary (API payloads, config files).
- Never use mutable default arguments (`def f(x=[])` is forbidden — use `None` and assign inside).

## Strings and Paths
- Use f-strings for string interpolation; never `%` formatting or `.format()`.
- Use `pathlib.Path` for all filesystem operations; never `os.path`.

## Control Flow and Style
- Prefer list, dict, and set comprehensions over `map()`/`filter()` with lambdas.
- Use early returns and guard clauses to reduce nesting.
- Prefer `match`/`case` (Python 3.10+) over long `if/elif` chains on a single value.

## Resource Management
- Always use context managers (`with`) for files, network connections, locks, and DB sessions.
- Never leave resources open outside a `with` block.

## Async
- Prefer `async`/`await` for any I/O-bound work (HTTP, DB, filesystem).
- Do not mix sync blocking calls inside `async` functions — use `asyncio.to_thread()` if needed.
- Use `asyncio.gather()` to run independent coroutines concurrently.

## Error Handling
- Catch specific exceptions, never bare `except:` or `except Exception:` without re-raising.
- Add context when re-raising: `raise ValueError("bad input") from original_exc`.
- Log exceptions with `logger.exception()` (includes traceback automatically).

## Testing
- Use `pytest` with fixtures for all tests; avoid `unittest.TestCase`.
- Place fixtures in `conftest.py` scoped appropriately (`function`, `module`, `session`).
- Name tests `test_should_<do_x>_when_<condition>`.
- Use `pytest-mock` for patching; patch at the point of use, not the definition.

## Linting and Formatting
- `ruff` is the linter — run `ruff check .` before committing.
- `black` is the formatter — run `black .` before committing.
- Line length is 88 (black default); do not override without a project-wide decision.
- `isort` profile should be set to `black` to avoid conflicts.
