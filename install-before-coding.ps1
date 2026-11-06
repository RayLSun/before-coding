[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [ValidateSet('Codex', 'Claude', 'Both')]
    [string]$Runtime = 'Both',

    [ValidateSet('Ask', 'Skip', 'BackupReplace')]
    [string]$OnConflict = 'Ask'
)

$ErrorActionPreference = 'Stop'
$skillSource = Join-Path $PSScriptRoot 'before-coding'

if (-not (Test-Path -LiteralPath $ProjectPath -PathType Container)) {
    $answer = (Read-Host "Project directory does not exist: $ProjectPath. Create it? [Y/N]").Trim().ToLowerInvariant()
    if ($answer -notin @('y', 'yes')) {
        throw 'Installation stopped because the project directory was not created.'
    }
    if ($PSCmdlet.ShouldProcess($ProjectPath, 'Create missing project directory')) {
        New-Item -ItemType Directory -Path $ProjectPath -Force | Out-Null
    } else {
        throw "Project directory does not exist: $ProjectPath"
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $skillSource 'SKILL.md') -PathType Leaf)) {
    throw "Skill source is missing or incomplete: $skillSource"
}

$projectRoot = (Resolve-Path -LiteralPath $ProjectPath).Path
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

function Get-ConflictAction([string]$Destination) {
    if ($OnConflict -ne 'Ask') {
        return $OnConflict
    }

    while ($true) {
        Write-Output "A skill folder already exists: $Destination"
        $answer = (Read-Host 'Choose [S]kip, [B]ackup and replace, or [Q]uit').Trim().ToLowerInvariant()
        switch ($answer) {
            's' { return 'Skip' }
            'skip' { return 'Skip' }
            'b' { return 'BackupReplace' }
            'backup' { return 'BackupReplace' }
            'q' { throw 'Installation stopped by user.' }
            'quit' { throw 'Installation stopped by user.' }
            default { Write-Output 'Enter S, B, or Q.' }
        }
    }
}

foreach ($target in $runtimes) {
    $destination = Join-Path $projectRoot $target.RelativePath
    $parent = Split-Path -Parent $destination

    if (Test-Path -LiteralPath $destination) {
        $action = Get-ConflictAction $destination
        if ($action -eq 'Skip') {
            Write-Output "Skipped $($target.Name): $destination"
            continue
        }

        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmssfff'
        $backup = "$destination.backup-$timestamp"
        $suffix = 1
        while (Test-Path -LiteralPath $backup) {
            $backup = "$destination.backup-$timestamp-$suffix"
            $suffix++
        }

        if ($PSCmdlet.ShouldProcess($destination, "Move existing skill to $backup")) {
            Move-Item -LiteralPath $destination -Destination $backup
            Write-Output "Backed up existing $($target.Name) skill to: $backup"
        } else {
            continue
        }
    }

    if ($PSCmdlet.ShouldProcess($destination, "Install before-coding for $($target.Name)")) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
        Copy-Item -LiteralPath $skillSource -Destination $destination -Recurse
        Write-Output "Installed $($target.Name) skill to: $destination"
    }
}
