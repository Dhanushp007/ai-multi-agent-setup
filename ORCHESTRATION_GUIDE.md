# Multi-Agent Orchestration Guide

This repository gives a project a ready-to-use orchestration workflow. After setup, describe a
complex task once and let the Master Orchestrator route it through planning, implementation,
review, testing, documentation, and delivery.

## One-minute setup

For a new project on Windows:

```powershell
.\scripts\new-project.ps1 -Name "my-service" -Stack node
Set-Location .\my-service
```

For an existing project:

```powershell
.\scripts\apply.ps1 -TargetPath "C:\Projects\MyApp" -Stack python
```

Use `node`, `python`, or `dotnet` to install the matching pre-commit hook. Use `*` when only the
shared setup is needed.

## First orchestration task

In a client that supports the installed agent format, invoke `master-orchestrator` and provide a
complete task brief:

```text
Build a password-reset flow for the existing web application.

Context: The app uses the existing user table and email provider.
Stack: node
Risk: production authentication flow
Constraints: preserve the current API contract and add regression tests.
Done when: implementation, tests, security review, documentation, and PR are complete.
```

The orchestrator should clarify only blocking ambiguity, then:

1. Analyze the domain, risk, constraints, and acceptance criteria.
2. Select the smallest useful set of specialist agents.
3. Sequence dependent work and parallelize independent work.
4. Require review and tests before advancing quality gates.
5. Escalate blocked decisions instead of silently guessing.
6. Summarize outputs, unresolved risks, and the delivery state.

## Standard pipelines

### New feature

`planner` -> `architect` -> implementation specialist(s) -> reviewer(s) -> tester(s) -> documentation -> PR

### Bug fix

`debugger` -> implementation specialist -> safety reviewer -> general reviewer -> regression tester

### Security change

`security-specialist` -> implementation specialist -> `security-reviewer` -> `security-tester` -> safety review

### Performance work

`performance-monitor` -> `performance-reviewer` -> implementation specialist -> regression testing

The profiles in `.github/agents/` contain the detailed routing table, quality gates, and escalation
rules. The `orchestrate` command and prompt are reusable entry points for clients that support
slash commands.

## Where setup files go

The apply scripts use `scripts/manifest.json` as the source of truth. A target project receives:

- `.github/agents/*.agent.md` for Copilot custom agents and compatible clients
- `AGENTS.md`, `CLAUDE.md`, and `GEMINI.md` for vendor-specific project guidance
- `.github/copilot-instructions.md` and `.github/instructions/` for Copilot instructions
- `.github/skills/`, `.github/prompts/`, and `.github/commands/` for reusable workflow assets
- `.vscode/` settings, tasks, keybindings, LSP, and MCP configuration
- `.vscode/mcp/` individual MCP server references
- `.git/hooks/` universal and selected stack-specific hooks

## Vendor usage

- **GitHub Copilot in VS Code**: select `master-orchestrator` from the agent picker. The `.agent.md`
  profiles, instructions, skills, hooks, prompts, and MCP template are the primary integration.
- **OpenAI Codex**: start with `AGENTS.md`, then provide the relevant prompt or agent profile as
  context. Use MCP only when configured in the Codex client.
- **Claude**: start with `CLAUDE.md`, then provide the relevant prompt or profile as context. Use MCP
  only when configured in the Claude client.
- **Gemini**: start with `GEMINI.md`, then provide the relevant prompt or profile as context. Use
  MCP only when configured in the Gemini client.

The orchestration method is shared, but agent discovery, slash commands, hooks, and skill loading are
client-specific. The setup scripts place the files correctly; they cannot make a vendor implement a
feature it does not support.

## Quality gates

Before declaring a task complete, verify:

- The acceptance criteria are met.
- Tests exist for changed behavior and pass.
- A general review and any relevant domain review are complete.
- Security and safety risks are addressed for the affected surface.
- No secrets were added.
- Documentation reflects the final behavior.
- A clear list of deferred work or human decisions remains.

## Useful commands

```powershell
# Preview without changing a project
.\scripts\apply.ps1 -TargetPath "C:\Projects\MyApp" -Stack node -DryRun

# Validate this setup repository
.\scripts\validate.ps1

# Install this repository's universal hooks and run validation
.\scripts\bootstrap.ps1
```
