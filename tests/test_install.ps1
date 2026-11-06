$ErrorActionPreference = 'Stop'

$packageRoot = Split-Path -Parent $PSScriptRoot
$installer = Join-Path $packageRoot 'install-before-coding.ps1'
$initializer = Join-Path $packageRoot 'init-before-coding.ps1'
$updater = Join-Path $packageRoot 'update-before-coding.ps1'
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("before-coding-test-" + [guid]::NewGuid().ToString('N'))

function Assert-Equal($actual, $expected, $message) {
    if ($actual -ne $expected) {
        throw "$message Expected '$expected', got '$actual'."
    }
}

function Assert-True($condition, $message) {
    if (-not $condition) {
        throw $message
    }
}

try {
    New-Item -ItemType Directory -Path $testRoot | Out-Null

    $freshProject = Join-Path $testRoot 'fresh-project'
    New-Item -ItemType Directory -Path $freshProject | Out-Null
    & $installer -ProjectPath $freshProject -Runtime Both -OnConflict Skip
    foreach ($runtimePath in @('.agents/skills/before-coding', '.claude/skills/before-coding')) {
        $installedSkill = Join-Path $freshProject $runtimePath
        Assert-True (Test-Path -LiteralPath (Join-Path $installedSkill 'SKILL.md')) "Expected skill installation at '$installedSkill'."
        Assert-True (Test-Path -LiteralPath (Join-Path $installedSkill 'assets/templates/product-contract.md')) "Expected document templates to be installed at '$installedSkill'."
    }

    $skipProject = Join-Path $testRoot 'skip-project'
    New-Item -ItemType Directory -Path $skipProject | Out-Null
    $existingSkill = Join-Path $skipProject '.agents/skills/before-coding'
    New-Item -ItemType Directory -Path $existingSkill -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $existingSkill 'SKILL.md') -Value 'user-owned skill' -Encoding UTF8
    & $installer -ProjectPath $skipProject -Runtime Codex -OnConflict Skip
    Assert-Equal (Get-Content -Raw -LiteralPath (Join-Path $existingSkill 'SKILL.md')) "user-owned skill`r`n" 'Skip must preserve the existing skill.'

    $backupProject = Join-Path $testRoot 'backup-project'
    New-Item -ItemType Directory -Path $backupProject | Out-Null
    $existingSkill = Join-Path $backupProject '.claude/skills/before-coding'
    New-Item -ItemType Directory -Path $existingSkill -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $existingSkill 'SKILL.md') -Value 'old skill' -Encoding UTF8
    & $installer -ProjectPath $backupProject -Runtime Claude -OnConflict BackupReplace
    $backup = Get-ChildItem -LiteralPath (Split-Path -Parent $existingSkill) -Directory -Filter 'before-coding.backup-*' | Select-Object -First 1
    Assert-True ($null -ne $backup) 'Expected the pre-existing skill to be preserved in a backup directory.'
    Assert-Equal (Get-Content -Raw -LiteralPath (Join-Path $backup.FullName 'SKILL.md')) "old skill`r`n" 'Backup must preserve the previous skill.'
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $existingSkill 'SKILL.md')) -match 'name: before-coding') 'Expected the new skill to replace the destination after backup.'

    $initProject = Join-Path $testRoot 'init-project'
    New-Item -ItemType Directory -Path $initProject | Out-Null
    & $initializer -ProjectPath $initProject -Runtime Both -OnConflict Skip
    foreach ($documentPath in @(
        'AGENTS.md',
        'CLAUDE.md',
        'docs/product-contract.md',
        'docs/architecture.md',
        'docs/verification.md',
        'docs/changes/README.md',
        '.before-coding.json'
    )) {
        Assert-True (Test-Path -LiteralPath (Join-Path $initProject $documentPath)) "Expected initialized document '$documentPath'."
    }
    Assert-Equal (Get-Content -Raw -LiteralPath (Join-Path $initProject 'CLAUDE.md')) "@AGENTS.md`r`n" 'CLAUDE.md must import AGENTS.md.'
    $manifest = Get-Content -Raw -LiteralPath (Join-Path $initProject '.before-coding.json') | ConvertFrom-Json
    Assert-Equal $manifest.skill 'before-coding' 'Initialization manifest must identify the skill.'
    Assert-Equal $manifest.documents.'AGENTS.md' 'created' 'Initialization manifest must record created files.'

    $skipInitProject = Join-Path $testRoot 'skip-init-project'
    New-Item -ItemType Directory -Path $skipInitProject | Out-Null
    Set-Content -LiteralPath (Join-Path $skipInitProject 'AGENTS.md') -Value 'user guidance' -Encoding UTF8
    & $initializer -ProjectPath $skipInitProject -Runtime Codex -OnConflict Skip
    Assert-Equal (Get-Content -Raw -LiteralPath (Join-Path $skipInitProject 'AGENTS.md')) "user guidance`r`n" 'Initialization skip must preserve existing documents.'

    $backupInitProject = Join-Path $testRoot 'backup-init-project'
    New-Item -ItemType Directory -Path $backupInitProject | Out-Null
    Set-Content -LiteralPath (Join-Path $backupInitProject 'docs-marker.txt') -Value 'keep this file' -Encoding UTF8
    New-Item -ItemType Directory -Path (Join-Path $backupInitProject 'docs') | Out-Null
    Set-Content -LiteralPath (Join-Path $backupInitProject 'docs/product-contract.md') -Value 'old contract' -Encoding UTF8
    & $initializer -ProjectPath $backupInitProject -Runtime Codex -OnConflict BackupReplace
    $contractBackup = Get-ChildItem -LiteralPath (Join-Path $backupInitProject 'docs') -Filter 'product-contract.md.backup-*' -File | Select-Object -First 1
    Assert-True ($null -ne $contractBackup) 'Expected initialization to back up an existing document.'
    Assert-Equal (Get-Content -Raw -LiteralPath $contractBackup.FullName) "old contract`r`n" 'Initialization backup must preserve the previous document.'
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $backupInitProject 'docs/product-contract.md')) -match 'Product Contract') 'Expected the template to replace the document after backup.'
    Assert-Equal (Get-Content -Raw -LiteralPath (Join-Path $backupInitProject 'docs-marker.txt')) "keep this file`r`n" 'Initialization must preserve unrelated files.'

    $updateProject = Join-Path $testRoot 'update-project'
    New-Item -ItemType Directory -Path $updateProject | Out-Null
    & $installer -ProjectPath $updateProject -Runtime Codex -OnConflict Skip
    & $initializer -ProjectPath $updateProject -Runtime Codex -OnConflict Skip
    $installedSkill = Join-Path $updateProject '.agents/skills/before-coding'
    Set-Content -LiteralPath (Join-Path $installedSkill 'SKILL.md') -Value 'old installed skill' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $updateProject 'docs/product-contract.md') -Value 'product baseline' -Encoding UTF8
    & $updater -ProjectPath $updateProject -Runtime Codex
    $skillBackup = Get-ChildItem -LiteralPath (Join-Path $updateProject '.agents/skills') -Directory -Filter 'before-coding.backup-*' | Select-Object -First 1
    Assert-True ($null -ne $skillBackup) 'Expected update to back up the installed skill.'
    Assert-Equal (Get-Content -Raw -LiteralPath (Join-Path $skillBackup.FullName 'SKILL.md')) "old installed skill`r`n" 'Update backup must preserve the previous skill.'
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $installedSkill 'SKILL.md')) -match 'name: before-coding') 'Expected update to install the current skill.'
    Assert-Equal (Get-Content -Raw -LiteralPath (Join-Path $updateProject 'docs/product-contract.md')) "product baseline`r`n" 'Update must not modify product documents.'
    $updatedManifest = Get-Content -Raw -LiteralPath (Join-Path $updateProject '.before-coding.json') | ConvertFrom-Json
    $version = (Get-Content -Raw -LiteralPath (Join-Path $packageRoot 'VERSION')).Trim()
    Assert-Equal $updatedManifest.skillVersion $version 'Update must record the current skill version.'

    Write-Output 'PASS: before-coding install, initialization, conflict handling, and update behavior.'
}
finally {
    $resolvedTestRoot = [System.IO.Path]::GetFullPath($testRoot)
    $resolvedTempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    if ($resolvedTestRoot.StartsWith($resolvedTempRoot, [System.StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolvedTestRoot)) {
        Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force
    }
}
