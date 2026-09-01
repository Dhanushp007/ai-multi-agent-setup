---
name: github-actions-debugging
description: Use this skill when a GitHub Actions workflow is failing, stuck, or producing unexpected results — automatically selected when asked to debug CI, fix a pipeline, or investigate a workflow run.
license: MIT
---

# GitHub Actions Debugging

## When to Use This Skill

- A workflow run is red (failed) or stuck (queued/in_progress too long)
- CI is passing locally but failing in GitHub
- A job is timing out or skipping unexpectedly
- Secrets or environment variables are missing at runtime
- A reusable workflow or composite action is misbehaving

---

## Process

### 1. Identify the Failing Run

Use the GitHub MCP server to locate the most recent failure:

```
list_workflow_runs(owner, repo, status: "failure")
```

Note the `run_id`, `workflow_name`, `branch`, and `head_commit.message`.

### 2. Drill Into Failed Jobs

```
list_workflow_jobs(owner, repo, run_id)
```

Identify which jobs have `conclusion: failure` or `conclusion: timed_out`.
Pay attention to job dependencies — a skipped job may be a symptom, not the cause.

### 3. Retrieve Job Logs

```
get_job_logs(owner, repo, job_id, return_content: true, tail_lines: 200)
```

For all failed jobs at once:
```
get_job_logs(owner, repo, run_id: run_id, failed_only: true, return_content: true)
```

### 4. Identify the Root-Cause Step

Scan the log for these sentinel strings (in priority order):

| Signal | Meaning |
|--------|---------|
| `##[error]` | Explicit runner error |
| `Process completed with exit code N` (N ≠ 0) | Command failed |
| `Error: ENOENT` | Missing file or directory |
| `Error: Input required and not supplied` | Missing action input |
| `Error: Resource not accessible by integration` | Insufficient token permissions |
| `npm ERR!` / `pip ERROR` / `MSBuild error` | Build/install failure |
| `OOMKilled` / `139` exit code | Out-of-memory or segfault |

### 5. Cross-Reference the Workflow YAML

Read the workflow file from the repo:
```
get_file_contents(owner, repo, path: ".github/workflows/<name>.yml")
```

Check:
- The failing step's `run:` command or `uses:` action version
- `env:` and `with:` inputs — are referenced secrets/vars defined?
- `if:` conditions — could the step be incorrectly skipped or triggered?
- `needs:` ordering — is an upstream job failing silently?

### 6. Common Failure Patterns & Fixes

#### Missing secret / environment variable
```yaml
# Symptom: empty string or "Input required and not supplied"
# Fix: ensure secret is set in repo/org settings and referenced correctly
env:
  MY_TOKEN: ${{ secrets.MY_TOKEN }}   # not ${{ env.MY_TOKEN }}
```

#### Permissions error (GITHUB_TOKEN)
```yaml
# Fix: add explicit permissions block at job or workflow level
permissions:
  contents: read
  pull-requests: write
  id-token: write   # required for OIDC
```

#### Stale action version pinned to a broken tag
```yaml
# Fix: pin to a specific commit SHA for stability
uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
```

#### Node/Python version mismatch
```yaml
# Fix: pin runtime version explicitly
- uses: actions/setup-node@v4
  with:
    node-version: '20'
```

#### Cache invalidation loop
```yaml
# Fix: use a stable, deterministic cache key
key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
restore-keys: |
  ${{ runner.os }}-npm-
```

#### Timeout
```yaml
# Fix: add timeout-minutes at job or step level
jobs:
  build:
    timeout-minutes: 15
```

### 7. Reproduce Locally with `act`

```bash
# Install act: https://github.com/nektos/act
act push --job build --secret-file .secrets
act pull_request -W .github/workflows/ci.yml
```

### 8. Annotate and Fix

- Open the relevant workflow YAML and apply the targeted fix
- Add a comment explaining the fix if non-obvious
- Commit with message: `fix(ci): <description of fix>`

### 9. Verify

After pushing the fix:
```
list_workflow_runs(owner, repo, branch: "<fix-branch>", per_page: 1)
```
Confirm `conclusion: success` on the new run.

---

## Tools & Resources

- **GitHub MCP**: `list_workflow_runs`, `list_workflow_jobs`, `get_job_logs`, `get_workflow`, `get_file_contents`
- **act** — run Actions locally: https://github.com/nektos/act
- **GitHub Actions expression syntax**: https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/expressions
- **Workflow syntax reference**: https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions
- **GitHub-hosted runner specs**: https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners

---

## Templates / Examples

### Minimal Debug Workflow (add temporarily to reproduce)
```yaml
name: Debug
on: workflow_dispatch
jobs:
  debug:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Dump context
        env:
          GITHUB_CONTEXT: ${{ toJson(github) }}
          JOB_CONTEXT: ${{ toJson(job) }}
        run: |
          echo "GITHUB_CONTEXT=$GITHUB_CONTEXT"
          echo "JOB_CONTEXT=$JOB_CONTEXT"
      - name: List env
        run: env | sort
      - name: Check secrets (masked)
        run: |
          echo "MY_SECRET length: ${#MY_SECRET}"
        env:
          MY_SECRET: ${{ secrets.MY_SECRET }}
```

---

## Checklist

- [ ] Located the failing run using `list_workflow_runs`
- [ ] Identified the specific failed job(s) via `list_workflow_jobs`
- [ ] Retrieved full logs with `get_job_logs`
- [ ] Found the root-cause step and exit code
- [ ] Cross-referenced the workflow YAML for misconfigurations
- [ ] Checked secrets/variables are defined in repo/org settings
- [ ] Verified permissions block is adequate
- [ ] Applied targeted fix (not a blanket `|| true` suppression)
- [ ] Confirmed the fixed run passes via `list_workflow_runs`
