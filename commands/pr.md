# surface: both
# /pr — Generates a pull request title and description from branch changes.

Analyze the commits and diffs on this branch compared to the base branch and generate a PR:

**Title**: Conventional commit style, under 72 characters.

**Description** (use this structure):
## What
One paragraph describing what changed and why.

## How
Bullet list of key implementation decisions or approach. Skip if straightforward.

## Testing
How to verify this works: steps to test, or note if covered by automated tests.

## Checklist
- [ ] Tests added/updated
- [ ] Docs updated (if user-facing change)
- [ ] No secrets or credentials committed

Keep it factual. Do not pad with filler. Omit sections that aren't relevant.
