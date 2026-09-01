---
applyTo: "**/*.tsx,**/*.jsx"
---

# React Coding Standards

## Component Style
- Use functional components exclusively; class components are forbidden in new code.
- Keep components under 150 lines — extract sub-components or custom hooks when approaching the limit.
- Name components with PascalCase; name files to match the component name.
- One component per file (small co-located helpers are acceptable in the same file).

## Hooks and Logic
- Extract non-trivial logic into custom hooks (`use<Name>.ts`) — components should be mostly JSX.
- Follow the Rules of Hooks: only call hooks at the top level, never inside conditions or loops.
- Use `useMemo` and `useCallback` only when there is a measurable performance benefit; premature
  memoization adds noise without gain.
- Apply `React.memo()` selectively on pure leaf components that receive stable props.

## State Management
- Colocate state as close as possible to where it is consumed.
- Use URL/query-string state for any value that should survive a page refresh or be shareable.
- Lift state only when siblings genuinely need to share it; otherwise keep it local.
- Prefer Zustand, Jotai, or server state (React Query / SWR) over `useReducer` + Context
  for global state.

## Data Fetching
- Do not use `useEffect` for data fetching in new code; use SWR, React Query, or server
  components instead.
- Co-locate query/mutation definitions with the component that owns them.

## Props and Composition
- Prefer composition (`children`, render props, slots) over deep prop drilling.
- When a prop list exceeds ~5 items, group related props into an object.
- Mark props `readonly` in the interface and use destructuring in the signature.

## Error and Loading States
- Wrap route-level and async feature boundaries with `<ErrorBoundary>`.
- Use `<Suspense fallback={…}>` for lazy-loaded components and async data.
- Always render meaningful loading and error UI — never silently swallow errors.

## Controlled vs Uncontrolled
- Prefer controlled components for form inputs that need validation or cross-field interaction.
- Use uncontrolled inputs (with `ref`) only for simple, isolated cases like file pickers.

## Accessibility
- Every interactive element must be keyboard-navigable and have an accessible label.
- Use semantic HTML (`<button>`, `<nav>`, `<main>`) before reaching for `<div onClick>`.
