[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [ValidateSet('Codex', 'Claude', 'Both')]
    [string]$Runtime = 'Both',

    [ValidateSet('Ask', 'Skip', 'BackupReplace')]
    [string]$OnConflict = 'Ask'
)

$ErrorActionPreference = 'Stop'
$packageRoot = $PSScriptRoot
$templateRoot = Join-Path $packageRoot 'before-coding/assets/templates'
$versionPath = Join-Path $packageRoot 'VERSION'

if (-not (Test-Path -LiteralPath $ProjectPath -PathType Container)) {
    $answer = (Read-Host "Project directory does not exist: $ProjectPath. Create it? [Y/N]").Trim().ToLowerInvariant()
    if ($answer -notin @('y', 'yes')) {
        throw 'Initialization stopped because the project directory was not created.'
    }
    if ($PSCmdlet.ShouldProcess($ProjectPath, 'Create missing project directory')) {
        New-Item -ItemType Directory -Path $ProjectPath -Force | Out-Null
    } else {
        throw "Project directory does not exist: $ProjectPath"
    }
}

if (-not (Test-Path -LiteralPath $versionPath -PathType Leaf)) {
    throw "Version file is missing: $versionPath"
}
if (-not (Test-Path -LiteralPath (Join-Path $templateRoot 'AGENTS.md') -PathType Leaf)) {
    throw "Template directory is missing or incomplete: $templateRoot"
}

$projectRoot = (Resolve-Path -LiteralPath $ProjectPath).Path
$version = (Get-Content -Raw -LiteralPath $versionPath).Trim()

function Get-RuntimeNames {
    switch ($Runtime) {
        'Codex' { return @('Codex') }
        'Claude' { return @('Claude') }
        'Both' { return @('Codex', 'Claude') }
    }
}

function Get-ConflictAction([string]$Destination) {
    if ($OnConflict -ne 'Ask') {
        return $OnConflict
    }

    while ($true) {
        Write-Host "A project file already exists: $Destination"
        $answer = (Read-Host 'Choose [S]kip, [B]ackup and replace, or [Q]uit').Trim().ToLowerInvariant()
        switch ($answer) {
            's' { return 'Skip' }
            'skip' { return 'Skip' }
            'b' { return 'BackupReplace' }
            'backup' { return 'BackupReplace' }
            'q' { throw 'Initialization stopped by user.' }
            'quit' { throw 'Initialization stopped by user.' }
            default { Write-Host 'Enter S, B, or Q.' }
        }
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

function Backup-ExistingPath([string]$Path) {
    $backup = Get-BackupPath $Path
    if ($PSCmdlet.ShouldProcess($Path, "Move existing path to $backup")) {
        Move-Item -LiteralPath $Path -Destination $backup
        Write-Output "Backed up existing file to: $backup"
    }
    return $backup
}

function Copy-Template([string]$RelativePath, [string]$TemplatePath, [System.Collections.IDictionary]$Statuses) {
    $destination = Join-Path $projectRoot $RelativePath
    if (Test-Path -LiteralPath $destination) {
        $action = Get-ConflictAction $destination
        if ($action -eq 'Skip') {
            $Statuses[$RelativePath] = 'skipped'
            Write-Output "Skipped existing file: $destination"
            return
        }
        $null = Backup-ExistingPath $destination
        $Statuses[$RelativePath] = 'backup-replaced'
    } else {
        $Statuses[$RelativePath] = 'created'
    }

    $parent = Split-Path -Parent $destination
    if ($PSCmdlet.ShouldProcess($destination, "Create $RelativePath from template")) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
        Copy-Item -LiteralPath $TemplatePath -Destination $destination
        Write-Output "Created project file: $destination"
    }
}

$statuses = [ordered]@{}
$templateFiles = [ordered]@{
    'AGENTS.md' = Join-Path $templateRoot 'AGENTS.md'
    'docs/product-contract.md' = Join-Path $templateRoot 'product-contract.md'
    'docs/architecture.md' = Join-Path $templateRoot 'architecture.md'
    'docs/verification.md' = Join-Path $templateRoot 'verification.md'
    'docs/changes/README.md' = Join-Path $templateRoot 'changes-README.md'
}

foreach ($relativePath in $templateFiles.Keys) {
    Copy-Template $relativePath $templateFiles[$relativePath] $statuses
}

if ($Runtime -in @('Claude', 'Both')) {
    $claudePath = Join-Path $projectRoot 'CLAUDE.md'
    if (Test-Path -LiteralPath $claudePath) {
        $action = Get-ConflictAction $claudePath
        if ($action -eq 'Skip') {
            $statuses['CLAUDE.md'] = 'skipped'
            Write-Output "Skipped existing file: $claudePath"
        } else {
            $null = Backup-ExistingPath $claudePath
            $statuses['CLAUDE.md'] = 'backup-replaced'
            if ($PSCmdlet.ShouldProcess($claudePath, 'Create Claude runtime entry point')) {
                Set-Content -LiteralPath $claudePath -Value '@AGENTS.md' -Encoding UTF8
                Write-Output "Created project file: $claudePath"
            }
        }
    } else {
        $statuses['CLAUDE.md'] = 'created'
        if ($PSCmdlet.ShouldProcess($claudePath, 'Create Claude runtime entry point')) {
            Set-Content -LiteralPath $claudePath -Value '@AGENTS.md' -Encoding UTF8
            Write-Output "Created project file: $claudePath"
        }
    }
}

$manifestRelativePath = '.before-coding.json'
$manifestPath = Join-Path $projectRoot $manifestRelativePath
$manifestAction = $null
if (Test-Path -LiteralPath $manifestPath) {
    $manifestAction = Get-ConflictAction $manifestPath
    if ($manifestAction -eq 'Skip') {
        $statuses[$manifestRelativePath] = 'skipped'
        Write-Output "Skipped existing file: $manifestPath"
    } else {
        $null = Backup-ExistingPath $manifestPath
        $statuses[$manifestRelativePath] = 'backup-replaced'
    }
} else {
    $statuses[$manifestRelativePath] = 'created'
}

if ($manifestAction -ne 'Skip') {
    $manifest = [ordered]@{
        schemaVersion = 1
        skill = 'before-coding'
        skillVersion = $version
        initializedAt = (Get-Date).ToString('o')
        updatedAt = $null
        runtimes = @(Get-RuntimeNames)
        documents = $statuses
    }
    if ($PSCmdlet.ShouldProcess($manifestPath, 'Write before-coding initialization manifest')) {
        Set-Content -LiteralPath $manifestPath -Value ($manifest | ConvertTo-Json -Depth 5) -Encoding UTF8
        Write-Output "Created project file: $manifestPath"
    }
}

Write-Output "Initialized before-coding $version for runtime(s): $((Get-RuntimeNames) -join ', ')"
