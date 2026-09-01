---
applyTo: "**/*.cs,**/*.csproj"
---

# C# / .NET Coding Standards

## Nullability
- Enable nullable reference types (`<Nullable>enable</Nullable>`) project-wide.
- Annotate nullable return types and parameters with `?`; do not suppress warnings with `!`.
- Prefer `??` and `?.` to explicit null checks; use guard clauses for required parameters.

## Immutability and Records
- Use `record` or `record struct` for immutable value/DTO types.
- Use `required` properties on records and classes instead of constructor injection where
  object-initializer syntax is cleaner.
- Use `init`-only setters to allow object initializers while preserving post-construction immutability.

## Modern C# Features
- Use file-scoped namespaces (`namespace Foo.Bar;`) — no block-scoped namespace braces.
- Use pattern matching (`switch` expressions, `is` patterns, property patterns) instead of
  long `if/else if` chains.
- Use primary constructors (C# 12) for simple classes; keep them for DI only.
- Use collection expressions `[1, 2, 3]` and spread `[..a, ..b]` (C# 12) for collections.

## Async / Await
- All I/O operations must be `async`/`await`; never block with `.Result` or `.Wait()`.
- Always accept and forward `CancellationToken` through the async call chain.
- Avoid `async void` — use `async Task`; `async void` is only acceptable for event handlers.

## Logging and Diagnostics
- Use `ILogger<T>` (Microsoft.Extensions.Logging) exclusively; never `Console.WriteLine`.
- Use structured log message templates: `_logger.LogInformation("Order {OrderId} placed", id)`.
- Never log sensitive data (PII, tokens, passwords).

## Dependency Injection
- Register services in `Program.cs` / `Startup.cs`; no service locator or static state.
- Prefer constructor injection; use `[FromServices]` in minimal-API handlers when needed.
- Scope services correctly: Singleton → Scoped → Transient (never inject Scoped into Singleton).

## Collections and LINQ
- Prefer LINQ over manual loops for filtering, projecting, and aggregating collections.
- Materialize LINQ queries (`ToList()`, `ToArray()`) before returning to avoid deferred-execution surprises.
- Use `IReadOnlyList<T>` / `IReadOnlyCollection<T>` for return types; expose mutability only when needed.

## Error Handling
- Choose one error-handling strategy per layer and apply it consistently:
  - Throw on unrecoverable errors; use result types (`Result<T, TError>`) for expected failures.
- Always catch specific exceptions; never catch `Exception` without logging and re-throwing.
- Use guard clauses at method entry points to validate arguments early.
