# surface: both
# /commit — Generates a conventional commit message from staged changes.

Analyze the staged changes (from `git diff --cached`) and generate a commit message that:
- Follows Conventional Commits format: `<type>(<scope>): <subject>`
- Uses one of: feat | fix | docs | style | refactor | test | chore | ci | perf | revert
- Keeps the subject under 72 characters, imperative mood ("add" not "added")
- Adds a body (separated by blank line) only if the change is non-obvious
- Adds `BREAKING CHANGE:` footer if the change breaks backward compatibility

Output the message in a code block, ready to copy-paste.
If the diff spans multiple unrelated concerns, suggest splitting into separate commits.
