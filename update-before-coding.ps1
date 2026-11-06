[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [ValidateSet('Codex', 'Claude', 'Both')]
    [string]$Runtime = 'Both'
)

$ErrorActionPreference = 'Stop'
$packageRoot = $PSScriptRoot
$skillSource = Join-Path $packageRoot 'before-coding'
$versionPath = Join-Path $packageRoot 'VERSION'

if (-not (Test-Path -LiteralPath $ProjectPath -PathType Container)) {
    throw "Project directory does not exist: $ProjectPath"
}
if (-not (Test-Path -LiteralPath (Join-Path $skillSource 'SKILL.md') -PathType Leaf)) {
    throw "Skill source is missing or incomplete: $skillSource"
}

$projectRoot = (Resolve-Path -LiteralPath $ProjectPath).Path
$version = (Get-Content -Raw -LiteralPath $versionPath).Trim()
$runtimes = switch ($Runtime) {
    'Codex' { @(@{ Name = 'Codex'; RelativePath = '.agents/skills/before-coding' }) }
    'Claude' { @(@{ Name = 'Claude'; RelativePath = '.claude/skills/before-coding' }) }
    'Both' {
        @(
            @{ Name = 'Codex'; RelativePath = '.agents/skills/before-coding' },
            @{ Name = 'Claude'; RelativePath = '.claude/skills/before-coding' }
        )
    }
}

function Get-BackupPath([string]$Path) {
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmssfff'
    $backup = "$Path.backup-$timestamp"
    $suffix = 1
    while (Test-Path -LiteralPath $backup) {
        $backup = "$Path.backup-$timestamp-$suffix"
        $suffix++
    }
    return $backup
}

foreach ($target in $runtimes) {
    $destination = Join-Path $projectRoot $target.RelativePath
    if (-not (Test-Path -LiteralPath $destination)) {
        $parent = Split-Path -Parent $destination
        if ($PSCmdlet.ShouldProcess($destination, "Install missing $($target.Name) skill")) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
            Copy-Item -LiteralPath $skillSource -Destination $destination -Recurse
            Write-Output "Installed missing $($target.Name) skill: $destination"
        }
        continue
    }

    $backup = Get-BackupPath $destination
    if ($PSCmdlet.ShouldProcess($destination, "Back up existing skill to $backup")) {
        Move-Item -LiteralPath $destination -Destination $backup
        New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
        Copy-Item -LiteralPath $skillSource -Destination $destination -Recurse
        Write-Output "Updated $($target.Name) skill: $destination"
        Write-Output "Backed up previous skill: $backup"
    }
}

$manifestPath = Join-Path $projectRoot '.before-coding.json'
if (Test-Path -LiteralPath $manifestPath) {
    $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    $manifest.skillVersion = $version
    $manifest.updatedAt = (Get-Date).ToString('o')
    if ($PSCmdlet.ShouldProcess($manifestPath, 'Update before-coding version metadata')) {
        Set-Content -LiteralPath $manifestPath -Value ($manifest | ConvertTo-Json -Depth 5) -Encoding UTF8
        Write-Output "Updated skill metadata: $manifestPath"
    }
} else {
    Write-Output "No initialization manifest found; project documents were left unchanged."
}

Write-Output "Updated before-coding skill to $version for runtime(s): $((@($runtimes | ForEach-Object { $_.Name })) -join ', ')"
