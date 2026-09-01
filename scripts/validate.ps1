<#
.SYNOPSIS
    Validates all config files in this Setup repo.
    Runs the same checks as .github/workflows/validate.yml but locally.

.PARAMETER Fix
    Attempt to auto-fix issues where possible (e.g. add missing newlines).

.EXAMPLE
    .\validate.ps1
    .\validate.ps1 -Verbose
#>
param([switch]$Fix)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
$failed   = @()
$passed   = 0

function Pass  ([string]$msg) { Write-Host "  ✔  $msg" -ForegroundColor Green;  $script:passed++ }
function Fail  ([string]$msg) { Write-Host "  ✖  $msg" -ForegroundColor Red;    $script:failed += $msg }
function Warn  ([string]$msg) { Write-Host "  ⚠  $msg" -ForegroundColor Yellow }
function Header([string]$msg) { Write-Host "`n  ── $msg" -ForegroundColor Cyan }

# ── JSONC parser (strips // comments) ────────────────────────────────────────

function Read-Jsonc ([string]$Path) {
    $raw      = Get-Content $Path -Raw
    # Strip full-line comments, then inline comments not preceded by : (avoids https://)
    $stripped = $raw -replace '(?m)^\s*//[^\r\n]*\r?\n?', ''
    $stripped = $stripped -replace '(?m)(?<!:)\s+//[^\r\n]*', ''
    return $stripped | ConvertFrom-Json
}

# ── 1. YAML syntax ────────────────────────────────────────────────────────────

Header "YAML syntax"
$yamlFiles = Get-ChildItem $repoRoot -Recurse -Include "*.yml","*.yaml" |
    Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' }

# Detect best available YAML validator
$yamlTool = $null
if (Get-Command yq -ErrorAction SilentlyContinue) { $yamlTool = 'yq' }
elseif ((python --version 2>&1) -match 'Python' -and (python -c "import yaml" 2>&1) -eq '') { $yamlTool = 'python' }

foreach ($f in $yamlFiles) {
    $rel = $f.FullName.Replace($repoRoot, '').TrimStart('\','/')
    if ($yamlTool -eq 'yq') {
        $result = yq e '.' $f.FullName 2>&1
        if ($LASTEXITCODE -ne 0) { Fail "Invalid YAML: $rel — $result" }
        else { Pass "YAML OK: $rel" }
    } elseif ($yamlTool -eq 'python') {
        $result = python -c "import yaml,sys; yaml.safe_load(open(r'$($f.FullName)'))" 2>&1
        if ($LASTEXITCODE -ne 0) { Fail "Invalid YAML: $rel — $result" }
        else { Pass "YAML OK: $rel" }
    } else {
        # Fallback: basic structural check (no external tools required)
        try {
            $content = Get-Content $f.FullName -Raw
            # Detect common YAML errors: tabs (not allowed), unmatched quotes
            if ($content -match '(?m)^\t') { Fail "Invalid YAML (tab indentation): $rel" }
            elseif ($content.Length -eq 0)  { Warn "Empty YAML file: $rel" }
            else { Pass "YAML OK (basic check): $rel" }
        } catch { Fail "Cannot read YAML: $rel — $_" }
    }
}

# ── 2. JSON / JSONC syntax ────────────────────────────────────────────────────

Header "JSON / JSONC syntax"
$jsonFiles = Get-ChildItem $repoRoot -Recurse -Include "*.json" |
    Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' }

foreach ($f in $jsonFiles) {
    try {
        $rel = $f.FullName.Replace($repoRoot, '').TrimStart('\','/')
        Read-Jsonc $f.FullName | Out-Null
        Pass "JSON OK: $rel"
    } catch {
        Fail "Invalid JSON: $rel — $_"
    }
}

# ── 3. Agent files have required fields ──────────────────────────────────────

Header "Agent file schema"
# Rich .md format uses Markdown body as instructions — check for structural markers
$requiredMarkers = @('name:', 'description:', 'model:', '## Your Role', '## Red Flags', '- [ ]')
$agentDir = Join-Path $repoRoot ".github\agents"

Get-ChildItem $agentDir -Filter "*.md" | ForEach-Object {
    try {
        $content = Get-Content $_.FullName -Raw
        $missing = $requiredMarkers | Where-Object { $content -notmatch [regex]::Escape($_) }
        if ($missing) { Fail "Agent missing fields [$($missing -join ', ')]: $($_.Name)" }
        else { Pass "Agent OK: $($_.Name)" }
    } catch {
        Fail "Agent read error: $($_.Name) — $_"
    }
}

# ── 4. Manifest sources exist ─────────────────────────────────────────────────

Header "manifest.json source paths"
try {
    $manifest = Read-Jsonc (Join-Path $PSScriptRoot "manifest.json")
    foreach ($entry in $manifest.entries) {
        $src = Join-Path $repoRoot $entry.source
        if (Test-Path $src) { Pass "Exists: $($entry.source)" }
        else                 { Fail "Missing source: $($entry.source)" }
    }
} catch {
    Fail "Cannot parse manifest.json — $_"
}

# ── 5. Hook scripts have shebangs ─────────────────────────────────────────────

Header "Hook script shebangs"
$hookFiles = Get-ChildItem (Join-Path $repoRoot "hooks") -Recurse -File |
    Where-Object { $_.Extension -ne ".ps1" }

foreach ($f in $hookFiles) {
    $firstLine = Get-Content $f.FullName -TotalCount 1
    $rel = $f.FullName.Replace($repoRoot, '').TrimStart('\','/')
    if ($firstLine -match '^#!') { Pass "Shebang OK: $rel" }
    else                          { Fail "Missing shebang: $rel" }
}

# ── Summary ───────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "  Passed : $passed" -ForegroundColor Green

if ($failed.Count -gt 0) {
    Write-Host "  Failed : $($failed.Count)" -ForegroundColor Red
    Write-Host ""
    $failed | ForEach-Object { Write-Host "    ✖  $_" -ForegroundColor Red }
    Write-Host ""
    exit 1
} else {
    Write-Host "  Failed : 0" -ForegroundColor Green
    Write-Host ""
    Write-Host "  ✅ All checks passed." -ForegroundColor Green
    Write-Host ""
}

