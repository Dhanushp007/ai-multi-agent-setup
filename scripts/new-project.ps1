<#
.SYNOPSIS
    Creates a new project directory, initialises git, and applies all Setup configs.

.PARAMETER Name
    Name of the new project (becomes the folder name).

.PARAMETER Stack
    Primary language stack: node | python | dotnet | *

.PARAMETER BasePath
    Parent directory where the project folder will be created. Defaults to current location.

.PARAMETER GitHubRepo
    After setup, create a GitHub repo and push the initial commit (requires gh CLI).

.PARAMETER Visibility
    GitHub repo visibility when -GitHubRepo is set: private (default) | public | internal

.EXAMPLE
    .\new-project.ps1 -Name "my-api" -Stack node
    .\new-project.ps1 -Name "ml-pipeline" -Stack python -BasePath "C:\Projects" -GitHubRepo
#>
param(
    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory)]
    [ValidateSet("node", "python", "dotnet", "*")]
    [string]$Stack,

    [string]$BasePath = (Get-Location).Path,

    [switch]$GitHubRepo,

    [ValidateSet("private", "public", "internal")]
    [string]$Visibility = "private"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectPath = Join-Path $BasePath $Name

# ── Pre-flight ────────────────────────────────────────────────────────────────

if (Test-Path $projectPath) {
    Write-Error "Directory already exists: $projectPath"; exit 1
}

Write-Host ""
Write-Host "  Creating project : " -NoNewline; Write-Host $Name    -ForegroundColor Cyan
Write-Host "  Stack            : " -NoNewline; Write-Host $Stack   -ForegroundColor Cyan
Write-Host "  Location         : " -NoNewline; Write-Host $projectPath -ForegroundColor DarkGray
Write-Host ""

# ── 1. Create directory & git init ───────────────────────────────────────────

New-Item -ItemType Directory -Path $projectPath | Out-Null
git -C $projectPath init -q
git -C $projectPath checkout -q -b main
Write-Host "  ✔ git init (branch: main)" -ForegroundColor Green

# ── 2. Apply Setup configs ────────────────────────────────────────────────────

Write-Host ""
& "$PSScriptRoot\apply.ps1" -TargetPath $projectPath -Stack $Stack

# ── 3. Create .gitignore ──────────────────────────────────────────────────────

$gitignore = @"
# OS
.DS_Store
Thumbs.db

# Editor
.vscode/*.log
*.suo
*.user

# Secrets
.env
.env.*
!.env.example

"@

$gitignore += switch ($Stack) {
    "node" {
@"
# Node
node_modules/
dist/
build/
.next/
.nuxt/
coverage/
*.log
"@
    }
    "python" {
@"
# Python
__pycache__/
*.py[cod]
*.pyo
.venv/
dist/
build/
*.egg-info/
.pytest_cache/
.ruff_cache/
.mypy_cache/
htmlcov/
"@
    }
    "dotnet" {
@"
# .NET
bin/
obj/
.vs/
*.suo
*.user
*.userosscache
TestResults/
"@
    }
    default { "" }
}

Set-Content "$projectPath\.gitignore" $gitignore
Write-Host "  ✔ .gitignore created" -ForegroundColor Green

# ── 4. Create README ──────────────────────────────────────────────────────────

$readme = @"
# $Name

Project scaffolded with the AI Multi-Agent Setup repository.

## Development

This project includes reusable agent instructions, prompts, skills, hooks, MCP templates, and VS
Code settings. Add the application-specific setup and run commands here as the project grows.
"@

Set-Content "$projectPath\README.md" $readme
Write-Host "  ✔ README.md created" -ForegroundColor Green

# ── 5. Initial commit ─────────────────────────────────────────────────────────

git -C $projectPath add . | Out-Null
git -C $projectPath commit -q -m "chore: initial project setup from Setup repo"
Write-Host "  ✔ Initial commit created" -ForegroundColor Green

# ── 6. Optionally create GitHub repo ─────────────────────────────────────────

if ($GitHubRepo) {
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        Write-Host ""
        Write-Host "  Creating GitHub repository ($Visibility)..." -ForegroundColor Cyan
        gh repo create $Name --$Visibility --source=$projectPath --remote=origin --push
        Write-Host "  ✔ GitHub repo created and pushed" -ForegroundColor Green
    } else {
        Write-Warning "gh CLI not found — skipping GitHub repo creation."
        Write-Warning "Install from: https://cli.github.com/"
    }
}

# ── Done ──────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  ✅ Project ready: $projectPath" -ForegroundColor Green
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor DarkGray
Write-Host "    cd $projectPath" -ForegroundColor DarkGray
switch ($Stack) {
    "node"   { Write-Host "    npm install" -ForegroundColor DarkGray }
    "python" { Write-Host "    python -m venv .venv && .venv\Scripts\pip install -r requirements.txt" -ForegroundColor DarkGray }
    "dotnet" { Write-Host "    dotnet restore" -ForegroundColor DarkGray }
}
Write-Host ""
