---
applyTo: "**/*.ts,**/*.tsx"
---

# TypeScript Coding Standards

## Compiler Settings
- Strict mode is always on (`"strict": true` in `tsconfig.json`); never disable it.
- Enable `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, and `noImplicitOverride`.

## Type Safety
- Never use `any`; use `unknown` for values of unknown shape and narrow with type guards.
- Use `satisfies` to validate literal values against a type without widening.
- Use `as const` assertions on literal objects and arrays to preserve narrow types.
- Prefer `readonly` arrays (`readonly T[]` or `ReadonlyArray<T>`) and `Readonly<T>` objects.
- Use discriminated unions (a shared `kind`/`type` literal field) instead of optional fields
  to model mutually exclusive states.

## Interfaces vs Types
- Prefer `interface` for object shapes that may be extended or implemented.
- Use `type` for unions, intersections, mapped types, and conditional types.

## Nullability and Optionals
- Prefer nullish coalescing `??` over `||` when the default should only apply for `null`/`undefined`.
- Prefer optional chaining `?.` over explicit null checks for deep property access.
- Do not use non-null assertion `!` — narrow the type instead.

## Exports
- Prefer named exports over default exports; default exports are harder to refactor.
- Re-export from an `index.ts` barrel only when the module has a stable public API.

## Runtime Validation
- Use Zod for parsing and validating external data (API responses, env vars, form input).
- Define Zod schemas alongside their inferred TypeScript types:
  `type Foo = z.infer<typeof FooSchema>`.

## Promises and Async
- Always handle Promise rejections — either `await` in a `try/catch` or `.catch()`.
- Never use `Promise<any>`; type the resolved value explicitly.
- Prefer `async`/`await` over raw `.then()` chains for readability.

## Patterns to Avoid
- No `enum` — use `as const` object maps or discriminated unions instead.
- No namespace merging or ambient declarations in application code.
- No implicit return type `{}` — annotate return types on public functions.
