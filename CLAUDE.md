# Claude Instructions — Setup Repository

This is the **Setup repository**: the single source of truth for reusable GitHub Copilot
configurations, development tooling, and project scaffolding.

## Personality & Style

- Be direct and concise — this is a developer tooling repo, not a product
- Prefer actionable output over lengthy explanations
- When creating files, produce complete, production-ready content — no placeholders
- Always validate changes against `scripts/manifest.json` for consistency

## Repository Structure

```
.github/agents/   ← 54 specialist agent profiles (.agent.md with YAML frontmatter)
skills/           ← Agent skills (subdirs, each with SKILL.md)
prompts/          ← Reusable prompt templates (*.prompt.md)
hooks/            ← Git hooks (universal/, node/, python/, dotnet/)
mcp/              ← MCP server config files (.json)
scripts/          ← Bootstrap & apply scripts + manifest.json
vscode/           ← VS Code workspace settings templates
workflows/        ← Reusable GitHub Actions workflow templates
.github/
  agents/         ← (deployed) agent profiles
  skills/         ← (deployed) skill bundles
  prompts/        ← (deployed) prompt templates
  instructions/   ← Path-specific instruction files (*.instructions.md)
  hooks/          ← Copilot agent lifecycle hooks (*.json)
  workflows/      ← This repo's own CI
```

## File Conventions

### Agent files (`.github/agents/*.agent.md`)
```yaml
---
name: agent-name
description: What this agent does. Use PROACTIVELY when...
tools: ["Read", "Grep", "Glob", "Edit", "Shell"]
model: opus|sonnet|haiku
---
```
Followed by: `## Your Role`, process phases, principles, patterns, checklists, `## Red Flags`.

### Skill files (`skills/<name>/SKILL.md`)
```yaml
---
name: skill-name
description: What this skill does and when Copilot should use it.
license: MIT
---
```
Followed by step-by-step instructions Copilot should follow.

### Prompt files (`prompts/*.prompt.md`)
Plain Markdown prompt with optional YAML frontmatter for `mode` and `description`.

### Path instructions (`.github/instructions/*.instructions.md`)
```yaml
---
applyTo: "**/*.py"
---
```
Followed by coding standards for the matched file type.

### Copilot hooks (`.github/hooks/*.json`)
```json
{ "version": 1, "hooks": { "preToolUse": [...], "sessionStart": [...] } }
```

## Key Files

- `scripts/manifest.json` — source of truth for what gets copied where
- `.github/agents/master-orchestrator.agent.md` — top-level orchestration agent
- `.github/copilot-instructions.md` — repo-wide Copilot instructions
- `scripts/apply.ps1` / `apply.sh` — apply configs to target projects

## When Editing This Repo

1. Check `scripts/manifest.json` when adding any new folder or file type
2. Run `.\scripts\validate.ps1` before committing
3. Update `.github/copilot-instructions.md` if you introduce a new convention
4. Keep `.github/workflows/` strictly for this repo's own CI — not templates
5. Workflow templates live in `workflows/templates/`
