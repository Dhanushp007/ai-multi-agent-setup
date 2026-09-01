# Agent Instructions — Setup Repository

This is the **Setup repository**: the single source of truth for reusable GitHub Copilot
configurations, development tooling, and project scaffolding. All agent work in this repo
should follow the conventions below.

## Repository Purpose

This repo defines and deploys:
- **Custom agents** (`.github/agents/*.agent.md`) — 54 specialist and orchestration agents
- **Skills** (`skills/`) — task-specific skill bundles deployed to `.github/skills/`
- **Prompts** (`prompts/`) — reusable prompt templates deployed to `.github/prompts/`
- **Path instructions** (`.github/instructions/`) — auto-applied per file type
- **Copilot hooks** (`.github/hooks/`) — agent lifecycle automation
- **MCP configs** (`mcp/`) — Model Context Protocol server configs
- **Git hooks** (`hooks/`) — pre-commit, commit-msg, pre-push
- **VS Code settings** (`vscode/`) — workspace settings, extensions, keybindings
- **Workflow templates** (`workflows/templates/`) — reusable GitHub Actions
- **Bootstrap scripts** (`scripts/`) — apply configs to target projects

## How to Work in This Repo

### Adding a new agent
1. Create `.github/agents/<name>.agent.md` with YAML frontmatter (`name`, `description`, `tools`, `model`) and rich Markdown body
2. Add an entry to `scripts/manifest.json` if it needs special handling
3. The `master-orchestrator` agent routes all complex tasks — update its routing table if the new agent covers a new domain

### Adding a new skill
1. Create `skills/<skill-name>/SKILL.md` with YAML frontmatter (`name`, `description`) and step-by-step instructions
2. Add optional scripts or resource files to the same directory
3. Update `scripts/manifest.json` to copy `skills/` → `.github/skills/`

### Adding a new prompt
1. Create `prompts/<name>.prompt.md`
2. File name becomes the prompt reference (e.g. `refactor.prompt.md` → `/refactor`)

### Modifying scripts
- `scripts/apply.ps1` and `scripts/apply.sh` read from `scripts/manifest.json` — do NOT hardcode paths
- Both scripts support `-DryRun` / `--dry-run` and `-Backup` / `--backup` flags
- JSONC comments (`//`) in `.json` files must be stripped before parsing

### Validation
Run `.\scripts\validate.ps1` locally before pushing. This runs the same checks as `.github/workflows/validate.yml`.

## Code Style

- PowerShell scripts: PS 7+ (`pwsh`), no aliases, prefer `Write-Host` for user output
- Shell scripts: POSIX-compatible `#!/bin/sh`, no bashisms unless explicitly `#!/bin/bash`
- JSON config files: JSONC format allowed (strip `//` comments before parsing)
- Agent/skill/prompt Markdown files: YAML frontmatter between `---` delimiters

## Orchestration

Use `@master-orchestrator` for any multi-step or multi-agent task. It routes to the
appropriate specialist agents automatically. Do not invoke specialist agents directly
for complex cross-cutting tasks.
