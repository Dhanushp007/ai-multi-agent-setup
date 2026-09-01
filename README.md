# AI Multi-Agent Setup

Reusable configuration, automation, and project scaffolding for AI-assisted software development.
The repository is designed around shared Markdown, JSON, shell, and PowerShell conventions so teams
can use the same engineering workflow with GitHub Copilot, Claude, Gemini, and OpenAI Codex where
the relevant client supports that format.

The primary goal is turnkey multi-agent orchestration: set up a project once, invoke the Master
Orchestrator, and let it coordinate specialists, reviews, tests, quality gates, and delivery.

Read the [Multi-Agent Orchestration Guide](ORCHESTRATION_GUIDE.md) for the complete workflow.

## What is included

| Path | Purpose | Native or portable surface |
|---|---|---|
| `.github/agents/` | 54 specialist and orchestration profiles | GitHub Copilot / compatible agent clients |
| `skills/` | Reusable task-specific skill bundles | Copilot-compatible clients; reusable Markdown elsewhere |
| `commands/` | Slash-command prompt definitions | Copilot CLI-style clients; copied when supported |
| `prompts/` | Reusable prompt templates | Portable Markdown prompts |
| `.github/instructions/` | Path-specific coding standards | GitHub Copilot and tools that read instruction files |
| `AGENTS.md` | Repository-wide agent instructions | OpenAI Codex and other clients that read `AGENTS.md` |
| `CLAUDE.md` | Claude-oriented project guidance | Claude-compatible clients |
| `GEMINI.md` | Gemini-oriented project guidance | Gemini-compatible clients |
| `mcp/` | Individual MCP server definitions | MCP-capable clients |
| `vscode/` | VS Code settings, keybindings, tasks, extensions, LSP, and MCP template | VS Code |
| `hooks/` | Universal and stack-specific Git hooks | Git on Windows, macOS, and Linux |
| `workflows/templates/` | Reusable GitHub Actions workflows | GitHub Actions |
| `scripts/` | Apply, scaffold, bootstrap, and validation scripts | PowerShell 7+ and POSIX shell |

## Quick start

Apply the setup to an existing project:

```powershell
.\scripts\apply.ps1 -TargetPath "C:\Projects\MyApp" -Stack node
```

Preview the changes first:

```powershell
.\scripts\apply.ps1 -TargetPath "C:\Projects\MyApp" -Stack python -DryRun
```

Create a new project and apply the setup:

```powershell
.\scripts\new-project.ps1 -Name "my-api" -Stack node
```

Then invoke `master-orchestrator` and describe the task, stack, risk, constraints, and definition of
done. The installed orchestration profiles determine the specialist sequence and quality gates.

On macOS or Linux:

```sh
./scripts/apply.sh --target /path/to/project --stack python
./scripts/new-project.sh --name my-api --stack node
```

Supported stack values are `node`, `python`, `dotnet`, and `*`. The wildcard applies shared files;
choose a specific stack to install its stack-specific Git `pre-commit` hook.

## Vendor compatibility

This is a shared setup repository, not a single universal agent runtime. Compatibility depends on
the client:

- **GitHub Copilot** can use `.github/agents/`, `.github/instructions/`, Copilot hooks, prompts,
  skills, MCP configuration, and the VS Code templates.
- **OpenAI Codex** can use `AGENTS.md`, the shared prompts, scripts, hooks, and MCP configuration
  when MCP is enabled. Copilot-specific agent and hook metadata is not automatically interpreted by
  Codex.
- **Claude** can use `CLAUDE.md`, shared prompts, scripts, hooks, and MCP configuration when the
  client supports MCP. `.github/agents/` is not a native Claude agent registry.
- **Gemini** can use `GEMINI.md`, shared prompts, scripts, hooks, and MCP configuration when the
  client supports MCP. `.github/agents/` is not a native Gemini agent registry.

The Markdown instructions are intentionally vendor-neutral where possible, but native agent
registration, slash commands, hooks, and skill discovery are client-specific. Do not assume that a
configuration being present in the repository means every vendor will execute it automatically.

## MCP setup

Copy or merge `vscode/mcp.json` into `.vscode/mcp.json` and enable only the servers needed by the
project. Keep credentials outside the repository:

- Set `GITHUB_TOKEN` as an environment variable for the GitHub server.
- Set `ALLOWED_PATHS` to the minimum filesystem paths required by the filesystem server.
- Set `DATABASE_URL` only when enabling the PostgreSQL server.
- Never commit tokens, passwords, or connection strings.

The individual definitions in `mcp/` are source references; `vscode/mcp.json` is the combined VS
Code template.

## Validation

Run the local checks before pushing changes:

```powershell
.\scripts\validate.ps1
```

The validator checks YAML and JSON/JSONC syntax, agent metadata, manifest source paths, and hook
shebangs. The same checks run in `.github/workflows/validate.yml` on pushes and pull requests.

## Repository layout

The manifest in `scripts/manifest.json` is the source of truth for files applied to target projects.
It includes the shared vendor instruction files, agent profiles, skills, prompts, commands, Git hooks,
MCP definitions, and VS Code templates. Workflow templates remain available under
`workflows/templates/` for explicit GitHub Actions adoption. The repository's `.github/agents/`
directory is both the live GitHub Copilot location and the source used by the apply scripts, which
keeps the checked-in agent profiles in one place.

## Security

Review generated and copied files before committing. Store secrets in environment variables or a
secrets manager, use least-privilege tokens, and keep MCP filesystem access restricted to required
paths.