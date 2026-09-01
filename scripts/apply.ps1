<#
.SYNOPSIS
    Applies configs from this Setup repo to a target project.

.PARAMETER TargetPath
    Path to the target project directory.

.PARAMETER Stack
    Stack filter: node | python | dotnet | * (default: *)

.PARAMETER DryRun
    Preview what would be applied without making any changes.

.PARAMETER Backup
    Create .bak copies of files before overwriting them.

.EXAMPLE
    .\apply.ps1 -TargetPath "C:\Projects\MyApp" -Stack node
    .\apply.ps1 -TargetPath "C:\Projects\MyApp" -Stack python -DryRun
    .\apply.ps1 -TargetPath "C:\Projects\MyApp" -Stack dotnet -Backup
#>
param(
    [Parameter(Mandatory)]
    [string]$TargetPath,

    [ValidateSet("node", "python", "dotnet", "*")]
    [string]$Stack = "*",

    [switch]$DryRun,
    [switch]$Backup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot  = Split-Path $PSScriptRoot -Parent
$stats     = @{ Applied = 0; Skipped = 0; Warnings = 0 }

# ── Helpers ───────────────────────────────────────────────────────────────────

function Write-Step {
    param([string]$Symbol, [string]$Msg, [string]$Color = "White")
    Write-Host "  $Symbol " -NoNewline; Write-Host $Msg -ForegroundColor $Color
}

# Parses JSON that may contain // single-line comments (JSONC).
function Read-Jsonc ([string]$Path) {
    $raw      = Get-Content $Path -Raw
    # Strip full-line comments, then inline comments not preceded by : (avoids https://)
    $stripped = $raw -replace '(?m)^\s*//[^\r\n]*\r?\n?', ''
    $stripped = $stripped -replace '(?m)(?<!:)\s+//[^\r\n]*', ''
    return $stripped | ConvertFrom-Json -AsHashtable -Depth 20
}

# Recursively merges $Override into $Base.
# Nested objects are merged; scalars in $Override win over $Base.
function Merge-Deep ([hashtable]$Base, [hashtable]$Override) {
    $result = @{}
    foreach ($k in $Base.Keys)     { $result[$k] = $Base[$k] }
    foreach ($k in $Override.Keys) {
        if ($result.ContainsKey($k) -and
            $result[$k]    -is [hashtable] -and
            $Override[$k]  -is [hashtable]) {
            $result[$k] = Merge-Deep $result[$k] $Override[$k]
        } else {
            $result[$k] = $Override[$k]
        }
    }
    return $result
}

# ── Pre-flight ────────────────────────────────────────────────────────────────

if (-not (Test-Path $TargetPath -PathType Container)) {
    Write-Error "Target path does not exist: $TargetPath"; exit 1
}

$manifest = Read-Jsonc "$PSScriptRoot\manifest.json"

Write-Host ""
if ($DryRun) { Write-Host "  [DRY RUN] No changes will be made.`n" -ForegroundColor Yellow }
Write-Host "  Target : " -NoNewline; Write-Host $TargetPath -ForegroundColor Cyan
Write-Host "  Stack  : $Stack`n"

# ── Apply entries ─────────────────────────────────────────────────────────────

foreach ($entry in $manifest.entries) {
    # Stack filter
    $es = $entry.stacks
    if ($es -ne "*" -and ($Stack -eq "*" -or $es -notcontains $Stack)) { continue }

    $src = Join-Path $repoRoot   $entry.source
    $dst = Join-Path $TargetPath $entry.destination

    if (-not (Test-Path $src)) {
        Write-Step "⚠" "Missing source, skipping : $($entry.source)" "Yellow"
        $stats.Warnings++; continue
    }

    if (-not $DryRun) {
        New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
    }

    switch ($entry.mode) {

        "copy" {
            if ($DryRun) {
                Write-Step "→" "copy    $($entry.source)  →  $($entry.destination)" "DarkCyan"
            } else {
                if ($Backup -and (Test-Path $dst)) { Copy-Item $dst "$dst.bak" -Force }
                Copy-Item -Path $src -Destination $dst -Recurse -Force
                Write-Step "✔" "Copied    $($entry.source)  →  $($entry.destination)" "Green"
            }
            $stats.Applied++
        }

        "symlink" {
            if (-not (Test-Path (Join-Path $TargetPath ".git"))) {
                Write-Step "⚠" "Not a git repo — skipping hook symlink: $($entry.destination)" "Yellow"
                $stats.Warnings++; continue
            }
            if ($DryRun) {
                Write-Step "→" "symlink $($entry.source)  →  $($entry.destination)" "DarkCyan"
            } else {
                if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
                try {
                    New-Item -ItemType SymbolicLink -Path $dst -Target $src -ErrorAction Stop | Out-Null
                    Write-Step "✔" "Symlinked $($entry.source)  →  $($entry.destination)" "Green"
                } catch {
                    Copy-Item -Path $src -Destination $dst -Force
                    Write-Step "⚠" "Symlink unavailable; copied $($entry.source)  →  $($entry.destination)" "Yellow"
                    $stats.Warnings++
                }
            }
            $stats.Applied++
        }

        "merge" {
            if ($DryRun) {
                Write-Step "→" "merge   $($entry.source)  →  $($entry.destination)" "DarkCyan"
                $stats.Applied++; continue
            }
            if (Test-Path $dst) {
                if ($Backup) { Copy-Item $dst "$dst.bak" -Force }
                try {
                    $existing = Read-Jsonc $dst
                    $incoming = Read-Jsonc $src
                    $merged   = Merge-Deep $existing $incoming
                    $merged | ConvertTo-Json -Depth 20 | Set-Content $dst -Encoding UTF8
                    Write-Step "✔" "Merged    $($entry.source)  →  $($entry.destination)" "Green"
                } catch {
                    Write-Step "⚠" "Merge failed ($($entry.destination)) — copying instead" "Yellow"
                    Copy-Item $src $dst -Force
                    $stats.Warnings++
                }
            } else {
                Copy-Item -Path $src -Destination $dst -Force
                Write-Step "✔" "Copied    $($entry.source)  →  $($entry.destination)" "Green"
            }
            $stats.Applied++
        }
    }
}

# ── Summary ───────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
$color = if ($stats.Warnings -gt 0) { "Yellow" } else { "Green" }
if ($DryRun) {
    Write-Host "  Dry run: $($stats.Applied) entries would be applied." -ForegroundColor Yellow
} else {
    Write-Host "  Applied: $($stats.Applied)   Warnings: $($stats.Warnings)" -ForegroundColor $color
}
Write-Host ""
