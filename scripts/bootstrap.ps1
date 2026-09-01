<#
.SYNOPSIS
    First-time setup for this Setup repository itself.
    Installs git hooks, checks required tools, and validates all configs.

.EXAMPLE
    .\bootstrap.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot  = Split-Path $PSScriptRoot -Parent

function Pass ([string]$msg) { Write-Host "  ✔  $msg" -ForegroundColor Green  }
function Fail ([string]$msg) { Write-Host "  ✖  $msg" -ForegroundColor Red    }
function Warn ([string]$msg) { Write-Host "  ⚠  $msg" -ForegroundColor Yellow }
function Info ([string]$msg) { Write-Host "  ·  $msg" -ForegroundColor DarkGray }
function Header([string]$msg){ Write-Host "`n  ── $msg" -ForegroundColor Cyan  }

Write-Host ""
Write-Host "  ╔══════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║  Setup Repo — Bootstrap               ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════╝" -ForegroundColor Cyan

# ── 1. PowerShell version ─────────────────────────────────────────────────────

Header "Environment"
if ($PSVersionTable.PSVersion.Major -ge 7) {
    Pass "PowerShell $($PSVersionTable.PSVersion) ✓"
} else {
    Fail "PowerShell 7+ required (found $($PSVersionTable.PSVersion)). Install from https://aka.ms/powershell"
    exit 1
}

# ── 2. Required tools ─────────────────────────────────────────────────────────

Header "Required tools"
$tools = @{
    "git"    = "https://git-scm.com/"
    "python" = "https://python.org/"
    "jq"     = "https://stedolan.github.io/jq/"
}
$missing = @()
foreach ($tool in $tools.Keys) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) { Pass "$tool found" }
    else { Fail "$tool not found — install from $($tools[$tool])"; $missing += $tool }
}

# ── 3. Optional tools ─────────────────────────────────────────────────────────

Header "Optional tools"
$optional = @("gh", "node", "dotnet")
foreach ($tool in $optional) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) { Pass "$tool found" }
    else { Warn "$tool not found (optional)" }
}

if ($missing.Count -gt 0) {
    Write-Host "`n  Install missing required tools and re-run bootstrap.`n" -ForegroundColor Red
    exit 1
}

# ── 4. Install git hooks for THIS repo ───────────────────────────────────────

Header "Installing git hooks for this repo"
$gitDir   = Join-Path $repoRoot ".git"
$hooksDir = Join-Path $gitDir "hooks"

if (-not (Test-Path $gitDir)) {
    Warn "Not a git repository — skipping hook installation."
} else {
    $hookSources = @(
        Join-Path $repoRoot "hooks\universal"
    )
    foreach ($srcDir in $hookSources) {
        if (-not (Test-Path $srcDir)) { continue }
        Get-ChildItem $srcDir -File | ForEach-Object {
            $dst = Join-Path $hooksDir $_.Name
            if (Test-Path $dst) { Remove-Item $dst -Force }
            try {
                New-Item -ItemType SymbolicLink -Path $dst -Target $_.FullName -ErrorAction Stop | Out-Null
                Pass "Hook installed: $($_.Name)"
            } catch {
                Copy-Item -Path $_.FullName -Destination $dst -Force
                Warn "Symlink unavailable; copied hook: $($_.Name)"
            }
        }
    }
}

# ── 5. Python YAML dependency ─────────────────────────────────────────────────

Header "Python dependencies (used by validate.ps1)"
try {
    python -c "import yaml" 2>$null
    Pass "PyYAML available"
} catch {
    Info "Installing PyYAML..."
    python -m pip install pyyaml --quiet
    Pass "PyYAML installed"
}

# ── 6. Run validation ─────────────────────────────────────────────────────────

Header "Running config validation"
& "$PSScriptRoot\validate.ps1"

# ── Done ──────────────────────────────────────────────────────────────────────

Write-Host "  ✅ Bootstrap complete. This repo is ready to use." -ForegroundColor Green
Write-Host ""
Write-Host "  Quick reference:" -ForegroundColor DarkGray
Write-Host "    New project   : .\scripts\new-project.ps1 -Name myapp -Stack node" -ForegroundColor DarkGray
Write-Host "    Apply configs : .\scripts\apply.ps1 -TargetPath C:\Projects\myapp -Stack node" -ForegroundColor DarkGray
Write-Host "    Validate repo : .\scripts\validate.ps1" -ForegroundColor DarkGray
Write-Host ""
