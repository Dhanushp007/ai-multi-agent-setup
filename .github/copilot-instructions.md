# Copilot Instructions — Setup Repository

This repository is the **single source of truth** for reusable Copilot configurations,
development tooling, and project scaffolding. New projects pull configs from here rather
than recreating them from scratch.

## Purpose

This repo defines and maintains:
- **Copilot agents** — custom agent definitions for VS Code and Copilot CLI
- **Agent skills** — task-specific skill bundles auto-loaded by Copilot when relevant
- **Prompt templates** — reusable prompt files (`.prompt.md`)
- **Path instructions** — per-file-type coding standards (`.github/instructions/`)
- **Copilot hooks** — agent lifecycle automation (`.github/hooks/*.json`)
- **MCP servers** — Model Context Protocol server configurations
- **VS Code settings** — workspace settings, recommended extensions, keybindings
- **Git hooks** — pre-commit, commit-msg, pre-push hooks (polyglot-compatible)
- **GitHub Actions workflows** — reusable CI/CD workflow templates
- **Scripts** — bootstrap scripts that apply configs to new or existing projects

## Repository Structure

```
AGENTS.md                         ← root agent instructions (read by Copilot CLI natively)
CLAUDE.md                         ← Claude-specific instructions
GEMINI.md                         ← Gemini-specific instructions
.github/
  copilot-instructions.md         ← this file (repo-wide Copilot instructions)
  agents/                         ← legacy source label; live profiles are in `.github/agents/`
  skills/                         ← (deployed) agent skill bundles
  prompts/                        ← (deployed) reusable prompt templates
  instructions/                   ← path-specific instruction files (*.instructions.md)
  hooks/                          ← Copilot agent lifecycle hooks (*.json)
  CODEOWNERS                      ← review routing by path
  PULL_REQUEST_TEMPLATE.md        ← default PR description template
  dependabot.yml                  ← automated dependency update config
  ISSUE_TEMPLATE/
    config.yml                    ← disables blank issues, links to docs
    bug.yml                       ← bug report form
    feature.yml                   ← feature request form
  workflows/
    validate.yml                  ← CI for this repo (validates YAML, JSON, hooks, manifest)
`.github/agents/`                ← Copilot agent profiles (.md), one per role
skills/                           ← Agent skill source bundles (subdirs with SKILL.md)
prompts/                          ← Prompt template source files (*.prompt.md)
hooks/
  universal/                      ← git hooks for all stacks
  node/                           ← Node.js / TypeScript git hooks
  python/                         ← Python git hooks
  dotnet/                         ← C# / .NET git hooks
mcp/                              ← MCP server config files (.json) per use case
scripts/
  apply.ps1                       ← Windows: apply configs to a target project
  apply.sh                        ← Unix: apply configs to a target project
  new-project.ps1                 ← Windows: create a new project + apply in one step
  new-project.sh                  ← Unix: create a new project + apply in one step
  validate.ps1                    ← Run the same checks as CI locally
  bootstrap.ps1                   ← First-time setup of this repo (hooks + tool check)
  manifest.json                   ← declares which files get copied/symlinked where
vscode/
  settings.json                   ← base VS Code workspace settings (JSONC, stack-tagged)
  extensions.json                 ← recommended extensions (core + per-stack)
  keybindings.json                ← shared keybindings
  mcp.json                        ← VS Code MCP server config template
  tasks.json                      ← common build/test/lint tasks per stack
  lsp.json                        ← LSP server config template
workflows/
  templates/
    ci-node.yml                   ← Node.js: install, lint, test, build
    ci-python.yml                 ← Python: pip install, ruff, black, pytest
    ci-dotnet.yml                 ← .NET: restore, format check, build, test
    ci-docker.yml                 ← Build & push Docker image to any registry
    pr-checks.yml                 ← Conventional Commits title + PR size warning
    security-scan.yml             ← CodeQL static analysis → GitHub Security tab
    dependency-review.yml         ← Block PRs that add vulnerable dependencies
    release.yml                   ← Create GitHub Release from a semver tag
    cd-container.yml              ← Deploy container to a GitHub Environment
    stale.yml                     ← Auto-label and close stale issues/PRs
```

## Key Conventions

### Copilot Agents (`.github/agents/`)
- One file per agent role, named descriptively: `architect.md`, `python-specialist.md`
- Use `.md` format with YAML frontmatter: `name`, `description`, `tools`, `model`
- When applying to a target project, agents are copied from `.github/agents/` via `scripts/manifest.json`
- **`master-orchestrator.md`** is the top-level agent — invoke it for any multi-step or multi-domain task
- All other agents are specialists — the orchestrator routes to them; do not invoke specialists directly for complex tasks

### Agent Skills (`skills/`)
- Each skill is a **subdirectory** containing a `SKILL.md` file (and optional scripts/resources)
- `SKILL.md` frontmatter: `name` (matches directory name), `description` (triggers auto-selection), `license`
- Copilot auto-selects skills based on prompt context and the skill's `description` field
- Invoke explicitly with `/skill-name` in prompts (e.g. `/github-actions-debugging`)
- Project skills deploy to `.github/skills/`; personal skills go to `~/.copilot/skills/`

### Prompt Templates (`prompts/`)
- File name convention: `<purpose>.prompt.md` (e.g. `refactor.prompt.md`)
- Reusable, standalone prompt templates — reference directly in chat
- Deploy to `.github/prompts/` via `scripts/manifest.json`

### Path-Specific Instructions (`.github/instructions/`)
- Files: `<stack>.instructions.md` with `applyTo:` glob frontmatter
- Automatically injected by Copilot when working on files matching the glob
- Examples: `python.instructions.md` (`applyTo: "**/*.py"`), `typescript.instructions.md` (`applyTo: "**/*.ts,**/*.tsx"`)
- These live in `.github/instructions/` directly (not in a source folder) and are copied by the apply script

### Copilot Agent Hooks (`.github/hooks/`)
- JSON files with `version: 1` and a `hooks` object
- Hook types: `sessionStart`, `sessionEnd`, `preToolUse`, `postToolUse`, `agentStop`, `subagentStop`, `errorOccurred`
- `preToolUse` hooks can **approve or deny** tool executions — most powerful type
- Keep hooks under 5 seconds; use async logging (append to file) not synchronous I/O
- These are **Copilot agent hooks**, NOT git hooks (which live in `hooks/`)

### MCP Server Configs (`mcp/`)
- One `.json` file per server, named by purpose: `playwright.json`, `github.json`, `postgres.json`
- Each file is a self-contained MCP server entry, droppable into `.vscode/mcp.json` or `~/.config/github-copilot/mcp.json`
- Include a `// description:` comment header explaining what capabilities the server enables

### Git Hooks (`hooks/`)
- Place in `hooks/<stack>/` or `hooks/universal/` for cross-stack hooks
- Scripts must be POSIX-compatible (`#!/bin/sh`) unless stack-specific
- Keep hooks fast — offload slow checks to CI workflows instead
- Each hook file name must match the git hook name exactly: `pre-commit`, `commit-msg`, `pre-push`

### Reusable Workflows (`workflows/templates/`)
- Use `on: workflow_call` trigger to make them callable from other repos
- Document required `inputs:` and `secrets:` at the top of each workflow file
- Name files by what they do: `ci-node.yml`, `lint-python.yml`, `release-dotnet.yml`

### VS Code Settings (`vscode/`)
- `settings.json` holds base settings merged into a target project's `.vscode/settings.json`
- Stack-specific settings must be commented with `// [stack: node]`, `// [stack: python]`, etc.
  so `apply.ps1` / `apply.sh` can filter them when targeting a specific stack
- `extensions.json` follows the standard VS Code format: `{ "recommendations": [...] }`
- `lsp.json` is a template for `.github/lsp.json` — repo-level LSP server config

### Applying Configs to a New Project
```powershell
# Windows — create a brand-new project
.\scripts\new-project.ps1 -Name "my-api" -Stack node
.\scripts\new-project.ps1 -Name "ml-pipeline" -Stack python -GitHubRepo

# Windows — apply to an existing project
.\scripts\apply.ps1 -TargetPath "C:\Projects\MyApp" -Stack node
.\scripts\apply.ps1 -TargetPath "C:\Projects\MyApp" -Stack node -DryRun   # preview only
.\scripts\apply.ps1 -TargetPath "C:\Projects\MyApp" -Stack node -Backup   # backup before overwrite

# Unix
./scripts/new-project.sh --name my-api --stack node
./scripts/apply.sh --target /path/to/project --stack python --dry-run
```
- The script reads `scripts/manifest.json` to determine what gets copied/symlinked
- To add a new config to the manifest, edit `scripts/manifest.json` — do not hardcode paths in the scripts

### First-time Setup of This Repo
```powershell
.\scripts\bootstrap.ps1   # installs hooks, checks tools, runs validate
```

### Validating Configs Locally
```powershell
.\scripts\validate.ps1    # same checks as .github/workflows/validate.yml
```

### Adding New Configs to This Repo
1. Create the file in the appropriate folder (`.github/agents/`, `skills/`, `prompts/`, `hooks/`, etc.)
2. Add an entry to `scripts/manifest.json` specifying `source`, `destination`, and `stacks` (or `"*"` for all)
3. Update `.github/copilot-instructions.md` if the new config introduces a new convention
4. Keep `.github/workflows/` strictly for this repo's own CI only

## Surface Compatibility

When a config only applies to one surface, note it at the top of the file:
- `# surface: vscode` — only picked up by the VS Code Copilot extension
- `# surface: cli` — only used via `gh copilot` CLI
- `# surface: both` — works on both surfaces (default assumption)

## Repository Structure

```
.github/
  copilot-instructions.md       ← this file (picked up automatically by GitHub Copilot)
  CODEOWNERS                    ← review routing by path
  PULL_REQUEST_TEMPLATE.md      ← default PR description template
  dependabot.yml                ← automated dependency update config
  ISSUE_TEMPLATE/
    config.yml                  ← disables blank issues, links to docs
    bug.yml                     ← bug report form
    feature.yml                 ← feature request form
  workflows/
    validate.yml                ← CI for this repo (validates YAML, JSON, hooks, manifest)
`.github/agents/`              ← Copilot agent definitions (.md), one file per role
commands/                       ← Copilot CLI slash commands (.md or .yml), one file per command
hooks/
  universal/                    ← hooks that work across all stacks
  node/                         ← Node.js / TypeScript specific hooks
  python/                       ← Python specific hooks
  dotnet/                       ← C# / .NET specific hooks
mcp/                            ← MCP server config files (.json) per use case
scripts/
  apply.ps1                     ← Windows: apply configs to a target project
  apply.sh                      ← Unix: apply configs to a target project
  new-project.ps1               ← Windows: create a new project + apply in one step
  new-project.sh                ← Unix: create a new project + apply in one step
  validate.ps1                  ← Run the same checks as CI locally
  bootstrap.ps1                 ← First-time setup of this repo (hooks + tool check)
  manifest.json                 ← declares which files get copied/symlinked where
vscode/
  settings.json               ← base VS Code workspace settings (JSONC, stack-tagged)
  extensions.json             ← recommended extensions (core + per-stack)
  keybindings.json            ← shared keybindings
  mcp.json                    ← VS Code MCP server config template
  tasks.json                  ← common build/test/lint tasks per stack
workflows/
  templates/
    ci-node.yml                 ← Node.js: install, lint, test, build
    ci-python.yml               ← Python: pip install, ruff, black, pytest
    ci-dotnet.yml               ← .NET: restore, format check, build, test
    ci-docker.yml               ← Build & push Docker image to any registry
    pr-checks.yml               ← Conventional Commits title + PR size warning
    security-scan.yml           ← CodeQL static analysis → GitHub Security tab
    dependency-review.yml       ← Block PRs that add vulnerable dependencies
    release.yml                 ← Create GitHub Release from a semver tag
    cd-container.yml            ← Deploy container to a GitHub Environment
    stale.yml                   ← Auto-label and close stale issues/PRs
```

## Key Conventions

### Copilot Agents (`.github/agents/`)
- One file per agent role, named descriptively: `code-reviewer.md`, `test-writer.md`
- Use `.md` format — Copilot CLI and VS Code natively read `.md` instruction files
- Each agent file must include `name:`, `description:`, `tools:`, and `model:` fields
- When applying to a target project, agents are copied to `.github/agents/` via `scripts/manifest.json`
- **`master-orchestrator.md`** is the top-level agent — invoke it for any multi-step or multi-domain task
- All other agents are specialists — the orchestrator routes to them; do not invoke specialists directly for complex tasks

### Copilot CLI Commands (`commands/`)
- File name becomes the slash command: `refactor.md` → `/refactor`
- Use `.md` for prompt-based commands, `.yml` for structured commands with parameters
- Start each file with a `# surface:` and `# /command-name` comment header

### MCP Server Configs (`mcp/`)
- One `.json` file per server, named by purpose: `playwright.json`, `github.json`, `postgres.json`
- Each file is a self-contained MCP server entry, droppable into `.vscode/mcp.json` or `~/.config/github-copilot/mcp.json`
- Include a `// description:` comment header explaining what capabilities the server enables

### Git Hooks (`hooks/`)
- Place in `hooks/<stack>/` or `hooks/universal/` for cross-stack hooks
- Scripts must be POSIX-compatible (`#!/bin/sh`) unless stack-specific (e.g., `.ps1` for dotnet/Windows)
- Keep hooks fast — offload slow checks (full test suites, security scans) to CI workflows instead
- Each hook file name must match the git hook name exactly: `pre-commit`, `commit-msg`, `pre-push`

### Reusable Workflows (`workflows/templates/`)
- Use `on: workflow_call` trigger to make them callable from other repos
- Document required `inputs:` and `secrets:` at the top of each workflow file
- Name files by what they do: `ci-node.yml`, `lint-python.yml`, `release-dotnet.yml`

### VS Code Settings (`vscode/`)
- `settings.json` holds base settings merged into a target project's `.vscode/settings.json`
- Stack-specific settings must be commented with `// [stack: node]`, `// [stack: python]`, etc.
  so `apply.ps1` / `apply.sh` can filter them when targeting a specific stack
- `extensions.json` follows the standard VS Code format: `{ "recommendations": [...] }`

### Applying Configs to a New Project
```powershell
# Windows — create a brand-new project
.\scripts\new-project.ps1 -Name "my-api" -Stack node
.\scripts\new-project.ps1 -Name "ml-pipeline" -Stack python -GitHubRepo

# Windows — apply to an existing project
.\scripts\apply.ps1 -TargetPath "C:\Projects\MyApp" -Stack node
.\scripts\apply.ps1 -TargetPath "C:\Projects\MyApp" -Stack node -DryRun   # preview only
.\scripts\apply.ps1 -TargetPath "C:\Projects\MyApp" -Stack node -Backup   # backup before overwrite

# Unix
./scripts/new-project.sh --name my-api --stack node
./scripts/apply.sh --target /path/to/project --stack python --dry-run
```
- The script reads `scripts/manifest.json` to determine what gets copied/symlinked
- To add a new config to the manifest, edit `scripts/manifest.json` — do not hardcode paths in the scripts

### First-time Setup of This Repo
```powershell
.\scripts\bootstrap.ps1   # installs hooks, checks tools, runs validate
```

### Validating Configs Locally
```powershell
.\scripts\validate.ps1    # same checks as .github/workflows/validate.yml
```

### Adding New Configs to This Repo
1. Create the file in the appropriate folder (`.github/agents/`, `commands/`, `hooks/`, etc.)
2. Add an entry to `scripts/manifest.json` specifying `source`, `destination`, and `stacks` (or `"*"` for all)
3. Update `.github/copilot-instructions.md` if the new config introduces a new convention
4. Keep `.github/` strictly for CI/CD — GitHub Actions workflows for this repo itself only

## Surface Compatibility

When a config only applies to one surface, note it at the top of the file:
- `# surface: vscode` — only picked up by the VS Code Copilot extension
- `# surface: cli` — only used via `gh copilot` CLI
- `# surface: both` — works on both surfaces (default assumption)
