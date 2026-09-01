---
name: release-notes
description: Use this skill when asked to generate release notes, write a changelog entry, draft a GitHub Release, or summarize changes between two versions — automatically selected for "write release notes", "what changed in this release", or "update the changelog".
license: MIT
---

# Release Notes

## When to Use This Skill

- Drafting a GitHub Release for a new tag/version
- Updating `CHANGELOG.md` before or after a release
- Summarizing merged PRs and commits for stakeholders
- Deciding the next semantic version bump
- Communicating breaking changes to downstream consumers

---

## Process

### 1. Determine the Release Range

Establish the boundary between the last release and HEAD:

```bash
# Find the last release tag
git describe --tags --abbrev=0

# List commits since the last tag
git log v1.2.3..HEAD --oneline --no-merges

# List merge commits (PRs) since the last tag
git log v1.2.3..HEAD --merges --oneline
```

Or via GitHub MCP:
```
list_releases(owner, repo, per_page: 5)           # find last release tag
list_pull_requests(owner, repo, state: "closed", base: "main")  # merged PRs
list_commits(owner, repo, sha: "main")             # recent commits
```

### 2. Determine the Version Bump (Semver)

Evaluate commits using **Conventional Commits** or PR labels:

| Signal | Bump | Example |
|--------|------|---------|
| `BREAKING CHANGE:` in footer, or `!` after type | **MAJOR** `X.0.0` | `feat!: remove v1 API` |
| `feat:` commits present | **MINOR** `x.Y.0` | `feat: add dark mode` |
| `fix:`, `perf:`, `refactor:` only | **PATCH** `x.y.Z` | `fix: correct date parsing` |
| `chore:`, `docs:`, `style:` only | No release needed | — |

> **Rule**: if any BREAKING CHANGE exists and the major version is `0`, bump MINOR instead (semver spec §4).

### 3. Categorize All Changes

Map each commit/PR to a category:

| Category | Conventional Commit Types | Display in Notes |
|----------|--------------------------|-----------------|
| ✨ Features | `feat` | Yes |
| 🐛 Bug Fixes | `fix` | Yes |
| ⚠️ Breaking Changes | `feat!`, `fix!`, `BREAKING CHANGE:` footer | Yes — prominently |
| ⚡ Performance | `perf` | Yes |
| 🔒 Security | `fix(security)`, CVE patches | Yes |
| 📦 Dependencies | `chore(deps)` | Yes (grouped) |
| 🏗️ Internal / Refactor | `refactor`, `chore`, `build` | Optional (collapsible) |
| 📝 Documentation | `docs` | Optional |
| 🧪 Tests | `test` | No (omit from user-facing notes) |

### 4. Draft the Release Notes

Use this structure:

```markdown
## [X.Y.Z] — YYYY-MM-DD

### ⚠️ Breaking Changes
- **`removeUser()` removed** — Use `deleteUser({ id })` instead. (#123)
- **Minimum Node.js version is now 20** — Node 18 is no longer supported. (#124)

### ✨ Features
- Add dark mode support with `prefers-color-scheme` detection (#98, @contributor)
- Introduce rate-limit headers on all API responses (#105)

### 🐛 Bug Fixes
- Fix incorrect timezone handling in `formatDate()` when UTC offset is negative (#110)
- Resolve race condition in job queue that caused duplicate processing (#115)

### ⚡ Performance
- Reduce cold-start time by 40% by lazy-loading heavy dependencies (#101)

### 🔒 Security
- Patch XSS vulnerability in markdown renderer (CVE-2024-12345) (#119)

### 📦 Dependencies
- Bump `express` from 4.18.2 to 4.19.2
- Bump `axios` from 1.6.0 to 1.7.2

### 📝 Documentation
- Add migration guide for v1 → v2 upgrade (#120)

**Full changelog**: https://github.com/owner/repo/compare/v1.2.3...v2.0.0
```

### 5. Populate CHANGELOG.md

`CHANGELOG.md` follows the [Keep a Changelog](https://keepachangelog.com) format:

```markdown
# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [X.Y.Z] — YYYY-MM-DD
### Added
- ...
### Changed
- ...
### Deprecated
- ...
### Removed
- ...
### Fixed
- ...
### Security
- ...

[Unreleased]: https://github.com/owner/repo/compare/vX.Y.Z...HEAD
[X.Y.Z]: https://github.com/owner/repo/compare/vX.Y.(Z-1)...vX.Y.Z
```

**Rules:**
- Newest version at the top; `[Unreleased]` always at the very top
- Each version is a level-2 heading `## [X.Y.Z] — YYYY-MM-DD`
- Update the diff links at the bottom of the file with every release
- Entries are written for humans, not machines — rephrase commit messages if needed

### 6. Create the GitHub Release

```
create_release(owner, repo,
  tag_name: "vX.Y.Z",
  name: "vX.Y.Z — <one-line summary>",
  body: <formatted release notes>,
  draft: true,           # review before publishing
  prerelease: false
)
```

Set `draft: true` first; share with the team for review, then publish.

### 7. Communicate Breaking Changes

For MAJOR version bumps, additionally:
- Write a migration guide (e.g., `docs/migration/v1-to-v2.md`)
- Pin it to the GitHub Release
- Announce in the repo's Discussions or Releases feed
- Consider a deprecation notice in the previous minor release

---

## Tools & Resources

- **GitHub MCP**: `list_releases`, `list_commits`, `list_pull_requests`, `create_release`, `get_commit`
- **Conventional Commits spec**: https://www.conventionalcommits.org/
- **Keep a Changelog**: https://keepachangelog.com/
- **Semantic Versioning**: https://semver.org/
- **git-cliff** (automated changelog from Conventional Commits): https://git-cliff.org/

---

## Templates / Examples

### One-liner Commit → Release Note conversions
| Raw commit | Release note entry |
|-----------|-------------------|
| `feat(auth): add OAuth2 PKCE support` | Add OAuth2 PKCE support for authorization code flow |
| `fix: prevent duplicate invoice emails` | Fix duplicate invoice emails being sent on retry |
| `perf(db): add index on users.email` | Reduce user lookup query time by ~90% via email index |
| `feat!: drop Node 18 support` | **[BREAKING]** Drop Node.js 18 — Node 20+ required |

---

## Checklist

- [ ] Identified the release range (previous tag → HEAD)
- [ ] Determined the correct semver bump (major/minor/patch)
- [ ] Fetched all merged PRs and commits in range
- [ ] Categorized every change (features, fixes, breaking, deps, security)
- [ ] Omitted test-only and internal chore commits from user-facing notes
- [ ] Breaking changes placed prominently with migration guidance
- [ ] `CHANGELOG.md` updated with new version section
- [ ] Diff links at bottom of CHANGELOG.md updated
- [ ] GitHub Release draft created and reviewed
- [ ] Migration guide written (for MAJOR bumps)
