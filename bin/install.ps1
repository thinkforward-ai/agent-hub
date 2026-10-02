#!/usr/bin/env pwsh
[CmdletBinding()]
param([switch]$BackupExisting, [switch]$Help)

$ErrorActionPreference = "Stop"
if ($Help) {
    Write-Host "Usage: install.ps1 [-BackupExisting] [-Help]"
    Write-Host "Set up Agent Hub once, or migrate an old skills layout. -BackupExisting is accepted for compatibility."
    exit 0
}

$archiveUrl = "https://github.com/thinkforward-ai/agent-hub/archive/refs/heads/main.tar.gz"
$hub = if ($env:AGENT_HUB_HOME) { $env:AGENT_HUB_HOME } else { Join-Path $env:USERPROFILE ".agent-hub" }
$factory = if ($env:FACTORY_HOME) { $env:FACTORY_HOME } else { Join-Path $env:USERPROFILE ".factory" }
$devin = if ($env:DEVIN_CONFIG_HOME) { $env:DEVIN_CONFIG_HOME } else { Join-Path $env:USERPROFILE ".config\devin" }
$claude = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $env:USERPROFILE ".claude" }
foreach ($path in @($hub, $factory, $devin, $claude)) {
    if (-not [System.IO.Path]::IsPathRooted($path)) { throw "Configuration paths must be absolute: $path" }
}
$hub = [System.IO.Path]::GetFullPath($hub)
$skillPaths = @((Join-Path $factory "skills"), (Join-Path $devin "skills"), (Join-Path $claude "skills"))
$instructionPaths = @((Join-Path $factory "AGENTS.md"), (Join-Path $devin "AGENTS.md"), (Join-Path $claude "CLAUDE.md"))
$current = Join-Path $hub "current"
$marker = Join-Path $hub ".layout-v2"

function Get-Entry([string]$Path) {
    return Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
}
function Get-Target([string]$Path) {
    $item = Get-Entry $Path
    if ($item -and $item.LinkType) { return [string](@($item.Target)[0]) }
    return $null
}
function Same-Path([string]$Left, [string]$Right) {
    if (-not $Left -or -not $Right) { return $false }
    return [System.IO.Path]::GetFullPath($Left).TrimEnd("\") -eq [System.IO.Path]::GetFullPath($Right).TrimEnd("\")
}
function Invoke-Native([string]$Command, [string[]]$Arguments) {
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Command failed with exit code $LASTEXITCODE" }
}
function Remove-Entry([string]$Path) {
    $item = Get-Entry $Path
    if (-not $item) { return }
    if ($item.LinkType -and $item.PSIsContainer) {
        [System.IO.Directory]::Delete($Path)
    } elseif ($item.LinkType) {
        [System.IO.File]::Delete($Path)
    } else {
        Remove-Item -LiteralPath $Path -Recurse -Force
    }
}
function New-DirectoryLink([string]$Path, [string]$Target) {
    New-Item -ItemType Junction -Path $Path -Target $Target | Out-Null
}

if (Get-Entry $marker) {
    if (-not (Test-Path (Join-Path $hub "skills") -PathType Container) -or -not (Get-Target $current)) {
        throw "Managed layout is incomplete; no changes made"
    }
    Write-Host "Agent Hub is already set up at $hub; use manage-skills for changes."
    exit 0
}
if ((Get-Entry $hub) -and -not (Test-Path $hub -PathType Container)) { throw "$hub is not a directory" }
if ((Test-Path $hub -PathType Container) -and -not (Test-Path (Join-Path $hub ".managed-by-agent-hub"))) {
    $unmanaged = @(Get-ChildItem -LiteralPath $hub -Force | Where-Object { $_.Name -ne ".env" })
    if ($unmanaged.Count) { throw "$hub contains unmanaged content: $($unmanaged[0].FullName)" }
}

$oldRelease = $null
$oldTarget = Get-Target $current
if ($oldTarget) {
    $releases = Join-Path $hub "releases"
    $oldId = Split-Path $oldTarget -Leaf
    $oldRelease = Join-Path $releases $oldId
    if ($oldId -notmatch '^[0-9a-f]{16}$' -or -not (Same-Path $oldTarget $oldRelease) -or
        -not (Test-Path $oldRelease -PathType Container)) {
        throw "current points to an unknown release; no changes made"
    }
} elseif (Get-Entry $current) { throw "current is not a managed link; no changes made" }

foreach ($path in $instructionPaths) {
    $item = Get-Entry $path
    if ($item -and -not (Same-Path (Get-Target $path) (Join-Path $current "AGENTS.md"))) {
        throw "Unmanaged instructions at $path; no changes made"
    }
}
foreach ($command in @("curl.exe", "tar.exe")) {
    if (-not (Get-Command $command -CommandType Application -ErrorAction SilentlyContinue)) {
        throw "Required command not found: $command"
    }
}

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) "agent-hub-install-$([Guid]::NewGuid())"
New-Item -ItemType Directory -Path $tmp | Out-Null
$held = @()
$created = @()
$releaseCreated = $false
$sharedCreated = $false
$committed = $false
$release = $null
$backup = $null

function Hold-Entry([string]$Path) {
    if (-not (Get-Entry $Path)) { return }
    $destination = Join-Path $tmp "held\$($script:held.Count)"
    Move-Item -LiteralPath $Path -Destination $destination
    $script:held += [pscustomobject]@{ Original = $Path; Held = $destination }
}
try {
    $archive = Join-Path $tmp "agent-hub.tar.gz"
    $snapshot = Join-Path $tmp "snapshot"
    New-Item -ItemType Directory -Path $snapshot | Out-Null
    Invoke-Native "curl.exe" @("--fail", "--location", "--silent", "--show-error", $archiveUrl, "--output", $archive)
    $members = & tar.exe -tzf $archive
    if ($LASTEXITCODE -ne 0) { throw "Cannot read downloaded archive" }
    foreach ($member in $members) {
        if ($member -match '(^/|(^|/)\.\.(/|$))') { throw "Unsafe archive path" }
    }
    $listing = & tar.exe -tvzf $archive
    if ($LASTEXITCODE -ne 0 -or @($listing | Where-Object { $_ -match '^[lh]' }).Count) {
        throw "Snapshot contains links or cannot be inspected"
    }
    Invoke-Native "tar.exe" @("-xzf", $archive, "--strip-components=1", "--directory", $snapshot)
    $core = Join-Path $snapshot "skills"
    if (-not (Test-Path (Join-Path $snapshot "AGENTS.md") -PathType Leaf) -or
        -not (Test-Path (Join-Path $snapshot "sources.json") -PathType Leaf) -or
        -not (Test-Path (Join-Path $core "manage-skills\SKILL.md") -PathType Leaf)) {
        throw "Snapshot lacks Agent Hub instructions, sources, or manager skill"
    }
    $folders = @(Get-ChildItem -LiteralPath $core -Directory)
    foreach ($folder in $folders) {
        if (-not (Test-Path (Join-Path $folder.FullName "SKILL.md") -PathType Leaf)) {
            throw "Invalid core skill: $($folder.Name)"
        }
    }
    $hash = (Get-FileHash $archive -Algorithm SHA256).Hash.Substring(0, 16).ToLowerInvariant()
    $release = Join-Path $hub "releases\v2-$hash"
    if (Get-Entry $release) { throw "Release exists without a completed installation" }
    New-Item -ItemType Directory -Path $hub -Force | Out-Null
    $managedFile = Join-Path $hub ".managed-by-agent-hub"
    if (-not (Get-Entry $managedFile)) {
        "managed by https://github.com/thinkforward-ai/agent-hub" | Set-Content -LiteralPath $managedFile
    }

    $needsBackup = [bool]$oldRelease
    foreach ($path in @($skillPaths) + @((Join-Path $hub "skills"))) {
        if (Get-Entry $path) { $needsBackup = $true }
    }
    if ($needsBackup) {
        $backupFolder = Join-Path $tmp "backup"
        New-Item -ItemType Directory -Path (Join-Path $backupFolder "paths") -Force | Out-Null
        if ($oldRelease) {
            Copy-Item -LiteralPath $oldRelease -Destination (Join-Path $backupFolder "legacy-release") -Recurse
            $oldTarget | Set-Content -LiteralPath (Join-Path $backupFolder "current.target")
        }
        for ($i = 0; $i -lt $skillPaths.Count; $i++) {
            $path = $skillPaths[$i]
            $entry = Get-Entry $path
            if (-not $entry) { continue }
            if ($entry.LinkType) {
                (Get-Target $path) | Set-Content -LiteralPath (Join-Path $backupFolder "paths\$i.target")
            } else {
                Copy-Item -LiteralPath $path -Destination (Join-Path $backupFolder "paths\$i") -Recurse
            }
            $path | Set-Content -LiteralPath (Join-Path $backupFolder "paths\$i.path")
        }
        $shared = Join-Path $hub "skills"
        $sharedEntry = Get-Entry $shared
        if ($sharedEntry) {
            if ($sharedEntry.LinkType) {
                (Get-Target $shared) | Set-Content -LiteralPath (Join-Path $backupFolder "shared.target")
            } else {
                Copy-Item -LiteralPath $shared -Destination (Join-Path $backupFolder "shared-skills") -Recurse
            }
        }
        $backupDir = Join-Path $hub "backups"
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        $backup = Join-Path $backupDir "version-$((Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss'))-$([Guid]::NewGuid()).tar.gz"
        Invoke-Native "tar.exe" @("-czf", $backup, "-C", $backupFolder, ".")
        Invoke-Native "tar.exe" @("-tzf", $backup)
        Write-Host "Verified old skills backup: $backup"
    }

    $releasesDir = Join-Path $hub "releases"
    New-Item -ItemType Directory -Path $releasesDir -Force | Out-Null
    $coreStage = Join-Path $tmp "core-skills"
    Move-Item -LiteralPath $core -Destination $coreStage
    Hold-Entry (Join-Path $hub "skills")
    Move-Item -LiteralPath $coreStage -Destination (Join-Path $hub "skills")
    $sharedCreated = $true
    New-DirectoryLink $core (Join-Path $hub "skills")
    Move-Item -LiteralPath $snapshot -Destination $release
    $releaseCreated = $true

    foreach ($path in $skillPaths) {
        New-Item -ItemType Directory -Path (Split-Path $path -Parent) -Force | Out-Null
        Hold-Entry $path
        New-DirectoryLink $path (Join-Path $hub "skills")
        $created += $path
    }
    Hold-Entry $current
    New-DirectoryLink $current $release
    $created += $current
    foreach ($path in $instructionPaths) {
        if (-not (Get-Entry $path)) {
            New-Item -ItemType Directory -Path (Split-Path $path -Parent) -Force | Out-Null
            try {
                New-Item -ItemType SymbolicLink -Path $path -Target (Join-Path $current "AGENTS.md") | Out-Null
            } catch {
                throw "Cannot link instructions at ${path}; enable Developer Mode or use an elevated shell"
            }
            $created += $path
        }
    }
    $sources = Join-Path $hub "sources.json"
    if (-not (Get-Entry $sources)) {
        Copy-Item -LiteralPath (Join-Path $release "sources.json") -Destination $sources
        $created += $sources
    }
    foreach ($path in $skillPaths) {
        if (-not (Test-Path (Join-Path $path "manage-skills\SKILL.md") -PathType Leaf)) {
            throw "Manager skill not visible at $path"
        }
    }
    if (-not (Test-Path (Join-Path $current "AGENTS.md") -PathType Leaf)) {
        throw "Instructions not visible"
    }
    "managed shared skills layout" | Set-Content -LiteralPath $marker
    $committed = $true

    if ($backup) {
        $list = Join-Path $hub "backups\managed.list"
        (Split-Path $backup -Leaf) | Add-Content -LiteralPath $list
        $names = @(Get-Content -LiteralPath $list)
        while ($names.Count -gt 2) {
            $oldest = $names[0]
            if ($oldest -match '^version-.*\.tar\.gz$') {
                Remove-Item -LiteralPath (Join-Path (Split-Path $list -Parent) $oldest) -Force
            }
            $names = @($names | Select-Object -Skip 1)
        }
        $names | Set-Content -LiteralPath $list
    }
    if ($oldRelease) { Remove-Item -LiteralPath $oldRelease -Recurse -Force }
    Write-Host "Agent Hub skills installed at $(Join-Path $hub 'skills')"
    Write-Host "Sources available at $sources"
    if ($oldRelease) { Write-Host "Legacy skills are no longer active; recover them from the backup if needed." }
} finally {
    if (-not $committed) {
        if (Get-Entry $marker) { Remove-Entry $marker }
        $stagedLink = Join-Path $snapshot "skills"
        if ((Get-Entry $stagedLink).LinkType) { Remove-Entry $stagedLink }
        if ($releaseCreated) {
            $skillLink = Join-Path $release "skills"
            if ((Get-Entry $skillLink).LinkType) { Remove-Entry $skillLink }
        }
        foreach ($path in $created) { Remove-Entry $path }
        if ($sharedCreated) { Remove-Entry (Join-Path $hub "skills") }
        for ($i = $held.Count - 1; $i -ge 0; $i--) {
            Move-Item -LiteralPath $held[$i].Held -Destination $held[$i].Original
        }
        if ($releaseCreated) { Remove-Entry $release }
    }
    Remove-Item -LiteralPath $tmp -Recurse -Force
}
