# surface: both
# /audit — Runs a security and dependency audit on the current project.

Perform a security and dependency audit:

1. **Dependency vulnerabilities** — check package manifest and lock files for known CVEs.
   Suggest: `npm audit`, `pip-audit`, or `dotnet list package --vulnerable` as appropriate.

2. **Code security scan** — review recently changed files for:
   - Hardcoded secrets or credentials
   - Injection vulnerabilities (SQL, command, path traversal)
   - Insecure defaults (no auth, open CORS, debug mode on)

3. **Summary** — end with a risk rating: 🔴 Critical | 🟠 High | 🟡 Medium | 🟢 Clean
   List items that must be fixed before merging/deploying.
