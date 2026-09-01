---
name: code-review
description: Use this skill when asked to review a pull request, audit a code change, or provide structured feedback on code quality — automatically selected for "review this PR", "check this diff", or "what's wrong with this code".
license: MIT
---

# Code Review

## When to Use This Skill

- Reviewing an open pull request before merge
- Auditing a code change for correctness or security issues
- Providing structured feedback with actionable comments
- Assessing test coverage and documentation completeness
- Enforcing team coding standards on a diff

---

## Process

### 1. Gather PR Context

```
get_pull_request(owner, repo, pull_number)          # title, description, author, base/head
get_pull_request_files(owner, repo, pull_number)    # list of changed files + stats
get_pull_request_diff(owner, repo, pull_number)     # full unified diff
```

Also check:
```
get_pull_request_reviews(owner, repo, pull_number)  # existing reviews
get_pull_request_comments(owner, repo, pull_number) # existing comments
get_check_runs(owner, repo, pull_number)            # CI status
```

### 2. Understand the Intent

Read the PR description carefully:
- What problem does this change solve?
- Is there a linked issue? (`Fixes #N` / `Closes #N`)
- Are there testing instructions or screenshots?
- Does the PR scope match the description?

If the PR lacks a description, note it as a `[NITS]` comment.

### 3. Categorize Files

Group changed files by concern before diving in:

| Category | Files | Focus |
|----------|-------|-------|
| Core logic | `src/`, `lib/` | Correctness, edge cases |
| API surface | `routes/`, `controllers/`, `resolvers/` | Security, validation |
| Data layer | `models/`, `migrations/`, `queries/` | Data integrity, N+1 |
| Tests | `*.test.*`, `*.spec.*`, `__tests__/` | Coverage, assertions |
| Config | `*.yml`, `*.json`, `*.env*` | Secrets, correctness |
| Docs | `*.md`, `openapi.yml` | Accuracy |

### 4. Apply the Review Lenses (in order)

#### 4a. Correctness
- Does the logic match the stated intent?
- Are there off-by-one errors, incorrect conditions, or wrong operators?
- Is error handling present and correct (not swallowed)?
- Are async operations awaited properly?
- Are all code paths covered (including early returns)?

#### 4b. Security
- Is user input validated and sanitized before use?
- Are SQL queries parameterized (no string concatenation)?
- Are secrets/credentials hardcoded anywhere?
- Is authorization checked (not just authentication)?
- Are file paths validated to prevent traversal attacks?
- Are dependencies introduced by this PR known-safe?

#### 4c. Performance
- Are there N+1 query patterns in loops?
- Are expensive operations called in hot paths without caching?
- Are large payloads serialized/deserialized unnecessarily?
- Are indexes used for new query patterns?

#### 4d. Maintainability
- Is the code DRY (no unnecessary duplication)?
- Are functions and variables named clearly?
- Is complexity acceptable (cyclomatic complexity ≤ 10 per function)?
- Are magic numbers/strings extracted to named constants?
- Is there dead code or commented-out code that should be removed?

#### 4e. Tests
- Are new code paths covered by tests?
- Do tests assert behaviour, not implementation?
- Are edge cases and error paths tested?
- Is test data realistic but not using production data?

#### 4f. Documentation
- Are public APIs, exports, and complex logic documented?
- Are README/CHANGELOG updated if needed?
- Are breaking changes clearly called out?

### 5. Severity Levels

Apply one of these labels to each comment:

| Label | Meaning | Required to merge? |
|-------|---------|-------------------|
| `[BLOCKER]` | Bug, security hole, data loss risk | Yes — must fix |
| `[MAJOR]` | Significant quality or correctness issue | Yes — must fix or discuss |
| `[MINOR]` | Improvement that prevents future bugs | Strongly recommended |
| `[NITS]` | Style, naming, formatting | No — author's discretion |
| `[QUESTION]` | Seeking clarification | No — informational |
| `[PRAISE]` | Positive feedback | No — encourage good work |

### 6. Write Comments

Use this template for each issue:

```
[SEVERITY] <Short summary>

**What**: <Describe the problem concisely>
**Why**: <Explain the risk or impact>
**Suggestion**:
```suggestion
<corrected code snippet>
```
```

Keep comments specific to a line range when possible. Batch related `[NITS]` into a single summary comment rather than flooding the PR.

### 7. Summarise the Review

Write an overall review comment with:
- Total counts: `N blockers, M majors, K minors, J nits`
- One-paragraph summary of the change's approach and quality
- Explicit verdict: `APPROVE` / `REQUEST_CHANGES` / `COMMENT`

---

## Tools & Resources

- **GitHub MCP**: `get_pull_request`, `get_pull_request_files`, `get_pull_request_diff`, `get_pull_request_reviews`, `get_check_runs`
- **OWASP Code Review Guide**: https://owasp.org/www-project-code-review-guide/
- **Google Engineering Practices**: https://google.github.io/eng-practices/review/
- **Conventional Comments**: https://conventionalcomments.org/

---

## Templates / Examples

### PR Comment — Blocker (SQL injection)
```
[BLOCKER] SQL injection vulnerability in user search

**What**: `query = "SELECT * FROM users WHERE name = '" + name + "'"` concatenates
raw user input into a SQL string.
**Why**: An attacker can inject arbitrary SQL, enabling data exfiltration or deletion.
**Suggestion**:
```suggestion
query = "SELECT * FROM users WHERE name = $1"
params = [name]
```
```

### PR Comment — Minor (missing error handling)
```
[MINOR] Unhandled promise rejection in file upload

**What**: `await uploadToS3(file)` is not wrapped in try/catch.
**Why**: A network error will crash the request handler silently.
**Suggestion**: Wrap in try/catch and return a 502 with a descriptive error message.
```

### Review Summary
```
**Review Summary** — 1 blocker, 2 majors, 3 nits

The overall approach is solid and the new caching layer is well-structured.
However, the SQL injection on line 47 must be fixed before merge, and the
two missing error-handling paths could cause silent failures in production.

Verdict: **REQUEST_CHANGES**
```

---

## Checklist

- [ ] Read PR description and linked issues
- [ ] Checked CI/check run status
- [ ] Reviewed all changed files grouped by concern
- [ ] Applied correctness lens
- [ ] Applied security lens
- [ ] Applied performance lens
- [ ] Applied maintainability lens
- [ ] Assessed test coverage
- [ ] Checked documentation updates
- [ ] Assigned severity to every comment
- [ ] Written overall summary with verdict
- [ ] Praised good work where warranted
