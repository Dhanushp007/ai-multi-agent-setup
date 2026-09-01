# Gemini Instructions — Setup Repository

This is the **Setup repository**: the single source of truth for reusable GitHub Copilot
configurations, development tooling, and project scaffolding. Other projects pull configs
from here instead of recreating them from scratch.

## Context

- **Language**: English only in all generated files
- **Target users**: Software engineering teams across Node.js, Python, and .NET stacks
- **Goal**: Every file created here must be production-ready — no `TODO`, no `# add more here`
- **Vendor scope**: Shared Markdown, scripts, hooks, and MCP assets are portable; native agent registries and lifecycle hooks remain client-specific.

## Repository Layout

| Folder | Purpose | Deploys to |
|--------|---------|-----------|
| `.github/agents/*.agent.md` | 54 specialist and orchestration agent profiles | `.github/agents/` |
| `skills/` | Agent skill bundles | `.github/skills/` |
| `prompts/` | Reusable prompt templates | `.github/prompts/` |
| `hooks/` | Git lifecycle hooks | `.git/hooks/` (via symlink) |
| `mcp/` | MCP server configs | `.vscode/mcp/` |
| `scripts/` | Bootstrap & apply scripts | n/a |
| `vscode/` | VS Code settings templates | `.vscode/` |
| `workflows/templates/` | Reusable GitHub Actions | Referenced via `workflow_call` |
| `.github/instructions/` | Path-specific instructions | `.github/instructions/` |
| `.github/hooks/` | Copilot agent lifecycle hooks | `.github/hooks/` |

## How Deployment Works

`scripts/apply.ps1 -TargetPath <path> -Stack <node|python|dotnet>` reads `scripts/manifest.json`
and copies/symlinks/merges the appropriate files into the target project. Always edit
`manifest.json` to add new config entries — never hardcode paths in the scripts.

## Coding Standards for This Repo

- All PowerShell scripts: require PS 7+ (`#Requires -Version 7`)
- All shell scripts: POSIX-compatible, `#!/bin/sh` unless bash features needed
- JSON files: JSONC format (C-style `//` comments allowed; strip before parsing)
- Markdown files: YAML frontmatter where required by the file type (agents, skills, instructions)
- No placeholder content: all generated files must be complete and usable

## Priority Agents

For complex tasks, use `@master-orchestrator`. It coordinates all 54 specialist and orchestration agents.
Direct specialist invocation is appropriate for simple, single-domain tasks only.
