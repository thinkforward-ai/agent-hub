#!/usr/bin/env pwsh

[CmdletBinding()]
param(
    [switch]$BackupExisting,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

$env:AGENT_HUB_ARCHIVE_URL = if ($env:AGENT_HUB_ARCHIVE_URL) { $env:AGENT_HUB_ARCHIVE_URL } else { "https://github.com/thinkforward-ai/agent-hub/archive/refs/heads/main.tar.gz" }
$env:AGENT_HUB_HOME = if ($env:AGENT_HUB_HOME) { $env:AGENT_HUB_HOME } else { Join-Path $env:USERPROFILE ".agent-hub" }
$env:FACTORY_HOME = if ($env:FACTORY_HOME) { $env:FACTORY_HOME } else { Join-Path $env:USERPROFILE ".factory" }
$env:FACTORY_SKILLS = Join-Path $env:FACTORY_HOME "skills"
$env:FACTORY_AGENTS = Join-Path $env:FACTORY_HOME "AGENTS.md"
$env:DEVIN_CONFIG_HOME = if ($env:DEVIN_CONFIG_HOME) { $env:DEVIN_CONFIG_HOME } else { Join-Path $env:USERPROFILE ".config\devin" }
$env:DEVIN_SKILLS_HOME = Join-Path $env:DEVIN_CONFIG_HOME "skills"
$env:DEVIN_AGENTS = Join-Path $env:DEVIN_CONFIG_HOME "AGENTS.md"

function Show-Usage {
    Write-Host @"
Usage: install.ps1 [-BackupExisting] [-Help]

Install Agent Hub from a clean public snapshot and link Factory and Devin skills and global instructions to it.

Options:
  -BackupExisting  Move a conflicting skills or AGENTS.md path to a timestamped backup.
  -Help            Show this help.

Environment:
  AGENT_HUB_HOME         Central installation directory (default: ~\.agent-hub)
  FACTORY_HOME           Factory configuration directory (default: ~\.factory)
  DEVIN_CONFIG_HOME      Devin configuration directory (default: ~\.config\devin)
  AGENT_HUB_ARCHIVE_URL  Snapshot URL (default: public main branch archive)
"@
}

function Write-ErrorAndExit {
    param([string]$Message)
    Write-Error $Message
    exit 1
}

if ($Help) {
    Show-Usage
    exit 0
}

# Check required commands
$requiredCommands = @("curl", "tar")
foreach ($cmd in $requiredCommands) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-ErrorAndExit "required command not found: $cmd"
    }
}

# Validate paths are absolute
foreach ($var in @("AGENT_HUB_HOME", "FACTORY_HOME", "DEVIN_CONFIG_HOME")) {
    $path = [System.IO.Path]::GetFullPath((Get-Item -Path (Get-Variable -Name $var).Value).FullName)
    if (-not [System.IO.Path]::IsPathRooted($path)) {
        Write-ErrorAndExit "$var must be an absolute path"
    }
    Set-Variable -Name $var -Value $path
}

$expectedSkillsTarget = Join-Path $env:AGENT_HUB_HOME "current\skills"
$expectedAgentsTarget = Join-Path $env:AGENT_HUB_HOME "current\AGENTS.md"

function Test-LinkConflict {
    param(
        [string]$TargetPath,
        [string]$ExpectedTarget,
        [string]$ResourceName
    )

    if (Test-Path $TargetPath -PathType Junction) {
        $currentTarget = (Get-Item $TargetPath).Target
        if ($currentTarget -ne $ExpectedTarget -and -not $BackupExisting) {
            Write-ErrorAndExit "$ResourceName points to $currentTarget; rerun with -BackupExisting to preserve and replace it"
        }
    } elseif (Test-Path $TargetPath) {
        if (-not $BackupExisting) {
            Write-ErrorAndExit "$ResourceName already exists; rerun with -BackupExisting to preserve and replace it"
        }
    }
}

Test-LinkConflict $env:FACTORY_SKILLS $expectedSkillsTarget "Factory skills"
Test-LinkConflict $env:DEVIN_SKILLS_HOME $expectedSkillsTarget "Devin skills"
Test-LinkConflict $env:FACTORY_AGENTS $expectedAgentsTarget "Factory AGENTS.md"
Test-LinkConflict $env:DEVIN_AGENTS $expectedAgentsTarget "Devin AGENTS.md"

if (Test-Path $env:AGENT_HUB_HOME -PathType Leaf) {
    Write-ErrorAndExit "$env:AGENT_HUB_HOME exists and is not a directory"
}

if (Test-Path $env:AGENT_HUB_HOME -PathType Container) {
    $managedFile = Join-Path $env:AGENT_HUB_HOME ".managed-by-agent-hub"
    if (-not (Test-Path $managedFile)) {
        $unmanagedFiles = Get-ChildItem $env:AGENT_HUB_HOME -Force | Where-Object { 
            $_.Name -ne ".env" -and $_.Name -ne ".managed-by-agent-hub" 
        }
        if ($unmanagedFiles) {
            Write-ErrorAndExit "$env:AGENT_HUB_HOME contains unmanaged content: $($unmanagedFiles[0].FullName)"
        }
    }
}

$tmpDir = Join-Path $env:TEMP "agent-hub-install-$([Guid]::NewGuid())"
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

try {
    $archive = Join-Path $tmpDir "agent-hub.tar.gz"
    $extracted = Join-Path $tmpDir "snapshot"
    New-Item -ItemType Directory -Path $extracted -Force | Out-Null

    Write-Host "Downloading Agent Hub snapshot..."
    curl --fail --location --silent --show-error $env:AGENT_HUB_ARCHIVE_URL --output $archive
    tar -xzf $archive --strip-components=1 --directory $extracted

    $skillsDir = Join-Path $extracted "skills"
    if (-not (Test-Path $skillsDir -PathType Container)) {
        Write-ErrorAndExit "snapshot does not contain a skills directory"
    }

    $skillFiles = Get-ChildItem $skillsDir -Recurse -Filter "SKILL.md" -Depth 1
    if (-not $skillFiles) {
        Write-ErrorAndExit "snapshot does not contain any skills"
    }

    $agentsFile = Join-Path $extracted "AGENTS.md"
    if (-not (Test-Path $agentsFile -PathType Leaf)) {
        Write-ErrorAndExit "snapshot does not contain AGENTS.md"
    }

    $hash = (Get-FileHash $archive -Algorithm SHA256).Hash.Substring(0, 16)
    $releaseDir = Join-Path $env:AGENT_HUB_HOME "releases\$hash"
    $oldRelease = $null

    $currentLink = Join-Path $env:AGENT_HUB_HOME "current"
    if (Test-Path $currentLink -PathType Junction) {
        $oldRelease = (Get-Item $currentLink).Target
    } elseif (Test-Path $currentLink) {
        Write-ErrorAndExit "$env:AGENT_HUB_HOME\current exists and is not a managed symlink"
    }

    $releasesDir = Join-Path $env:AGENT_HUB_HOME "releases"
    New-Item -ItemType Directory -Path $releasesDir -Force | Out-Null
    "managed by https://github.com/thinkforward-ai/agent-hub" | Out-File -FilePath (Join-Path $env:AGENT_HUB_HOME ".managed-by-agent-hub") -Encoding utf8

    if (-not (Test-Path $releaseDir -PathType Container)) {
        Move-Item $extracted $releaseDir
    }

    # Remove old current link if exists
    if (Test-Path $currentLink) {
        Remove-Item $currentLink -Force
    }

    # Create new junction
    New-Item -ItemType Junction -Path $currentLink -Target $releaseDir | Out-Null

    function New-Symlink {
        param(
            [string]$TargetPath,
            [string]$ExpectedTarget,
            [string]$ParentDir,
            [string]$ResourceName
        )

        New-Item -ItemType Directory -Path $ParentDir -Force | Out-Null
        if (Test-Path $TargetPath) {
            $currentTarget = $null
            if (Test-Path $TargetPath -PathType Junction) {
                $currentTarget = (Get-Item $TargetPath).Target
            }

            if ($currentTarget -ne $ExpectedTarget) {
                $timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss")
                $backup = "$TargetPath.backup.$timestamp"
                while (Test-Path $backup) {
                    $backup = "$backup.$([Random]::Next())"
                }
                Move-Item $TargetPath $backup
                Write-Host "Preserved existing $ResourceName at $backup"
            }
        }

        if (-not (Test-Path $TargetPath -PathType Junction)) {
            if (Test-Path $TargetPath) {
                Remove-Item $TargetPath -Recurse -Force
            }
            New-Item -ItemType Junction -Path $TargetPath -Target $ExpectedTarget | Out-Null
        }
    }

    New-Symlink $env:FACTORY_SKILLS $expectedSkillsTarget $env:FACTORY_HOME "Factory skills"
    New-Symlink $env:DEVIN_SKILLS_HOME $expectedSkillsTarget $env:DEVIN_CONFIG_HOME "Devin skills"
    New-Symlink $env:FACTORY_AGENTS $expectedAgentsTarget $env:FACTORY_HOME "Factory AGENTS.md"
    New-Symlink $env:DEVIN_AGENTS $expectedAgentsTarget $env:DEVIN_CONFIG_HOME "Devin AGENTS.md"

    # Clean up old release
    if ($oldRelease) {
        $oldReleaseId = Split-Path $oldRelease -Leaf
        if ($oldReleaseId -match "^[0-9a-f]{16}$" -and $oldReleaseId -ne $hash) {
            $oldReleasePath = Join-Path $releasesDir $oldReleaseId
            if (Test-Path $oldReleasePath) {
                Remove-Item $oldReleasePath -Recurse -Force
            }
        }
    }

    Write-Host "Agent Hub installed at $env:AGENT_HUB_HOME\current"
    Write-Host "Factory skills linked at $env:FACTORY_SKILLS"
    Write-Host "Devin skills linked at $env:DEVIN_SKILLS_HOME"
    Write-Host "Factory AGENTS.md linked at $env:FACTORY_AGENTS"
    Write-Host "Devin AGENTS.md linked at $env:DEVIN_AGENTS"

} finally {
    if (Test-Path $tmpDir) {
        Remove-Item $tmpDir -Recurse -Force
    }
}
