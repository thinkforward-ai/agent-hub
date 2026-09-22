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
$env:DEVIN_CONFIG_HOME = if ($env:DEVIN_CONFIG_HOME) { $env:DEVIN_CONFIG_HOME } else { Join-Path $env:USERPROFILE ".config\devin" }
$env:CLAUDE_CONFIG_DIR = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $env:USERPROFILE ".claude" }

function Show-Usage {
    Write-Host @"
Usage: install.ps1 [-BackupExisting] [-Help]

Install Agent Hub from a clean public snapshot and link Factory, Devin, and Claude Code skills and global instructions to it.

Options:
  -BackupExisting  Move a conflicting skills or AGENTS.md path to a timestamped backup.
  -Help            Show this help.

Environment:
  AGENT_HUB_HOME         Central installation directory (default: ~\.agent-hub)
  FACTORY_HOME           Factory configuration directory (default: ~\.factory)
  DEVIN_CONFIG_HOME      Devin configuration directory (default: ~\.config\devin)
  CLAUDE_CONFIG_DIR      Claude Code configuration directory (default: ~\.claude)
  AGENT_HUB_ARCHIVE_URL  Snapshot URL (default: public main branch archive)
"@
}

function Write-ErrorAndExit {
    param([string]$Message)
    $host.UI.WriteErrorLine("Error: $Message")
    exit 1
}

# Returns the item at a path without following links, or $null. Unlike
# Test-Path, this also finds broken links.
function Get-PathEntry {
    param([string]$Path)
    Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
}

# Returns the target of a junction or symlink, or $null for anything else.
function Get-LinkTarget {
    param([string]$Path)
    $item = Get-PathEntry $Path
    if ($item -and $item.LinkType) {
        # Windows PowerShell returns Target as an array.
        return [string](@($item.Target)[0])
    }
    return $null
}

function Test-SamePath {
    param([string]$Left, [string]$Right)
    if (-not $Left -or -not $Right) {
        return $false
    }
    $Left = [System.IO.Path]::GetFullPath($Left).TrimEnd("\")
    $Right = [System.IO.Path]::GetFullPath($Right).TrimEnd("\")
    return $Left -eq $Right
}

# Removes a junction or symlink without touching the directory it points to.
function Remove-Link {
    param([string]$Path)
    $item = Get-PathEntry $Path
    if ($item -and $item.PSIsContainer) {
        [System.IO.Directory]::Delete($Path)
    } elseif ($item) {
        [System.IO.File]::Delete($Path)
    }
}

function Invoke-Native {
    param([string]$Command, [string[]]$Arguments)
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorAndExit "$Command failed with exit code $LASTEXITCODE"
    }
}

if ($Help) {
    Show-Usage
    exit 0
}

# Check required commands. Use curl.exe explicitly: in Windows PowerShell,
# curl is an alias for Invoke-WebRequest.
$requiredCommands = @("curl.exe", "tar.exe")
foreach ($cmd in $requiredCommands) {
    if (-not (Get-Command $cmd -CommandType Application -ErrorAction SilentlyContinue)) {
        Write-ErrorAndExit "required command not found: $cmd"
    }
}

# Validate paths are absolute
foreach ($var in @("AGENT_HUB_HOME", "FACTORY_HOME", "DEVIN_CONFIG_HOME", "CLAUDE_CONFIG_DIR")) {
    $value = [Environment]::GetEnvironmentVariable($var)
    if (-not [System.IO.Path]::IsPathRooted($value)) {
        Write-ErrorAndExit "$var must be an absolute path"
    }
    Set-Item -Path "env:$var" -Value ([System.IO.Path]::GetFullPath($value))
}
$env:FACTORY_SKILLS = Join-Path $env:FACTORY_HOME "skills"
$env:FACTORY_AGENTS = Join-Path $env:FACTORY_HOME "AGENTS.md"
$env:DEVIN_SKILLS_HOME = Join-Path $env:DEVIN_CONFIG_HOME "skills"
$env:DEVIN_AGENTS = Join-Path $env:DEVIN_CONFIG_HOME "AGENTS.md"
$env:CLAUDE_SKILLS = Join-Path $env:CLAUDE_CONFIG_DIR "skills"
$env:CLAUDE_INSTRUCTIONS = Join-Path $env:CLAUDE_CONFIG_DIR "CLAUDE.md"

$expectedSkillsTarget = Join-Path $env:AGENT_HUB_HOME "current\skills"
$expectedAgentsTarget = Join-Path $env:AGENT_HUB_HOME "current\AGENTS.md"

function Test-LinkConflict {
    param(
        [string]$TargetPath,
        [string]$ExpectedTarget,
        [string]$ResourceName
    )

    $currentTarget = Get-LinkTarget $TargetPath
    if ($currentTarget) {
        if (-not (Test-SamePath $currentTarget $ExpectedTarget) -and -not $BackupExisting) {
            Write-ErrorAndExit "$ResourceName points to $currentTarget; rerun with -BackupExisting to preserve and replace it"
        }
    } elseif (Get-PathEntry $TargetPath) {
        if (-not $BackupExisting) {
            Write-ErrorAndExit "$ResourceName already exists; rerun with -BackupExisting to preserve and replace it"
        }
    }
}

Test-LinkConflict $env:FACTORY_SKILLS $expectedSkillsTarget "Factory skills"
Test-LinkConflict $env:DEVIN_SKILLS_HOME $expectedSkillsTarget "Devin skills"
Test-LinkConflict $env:FACTORY_AGENTS $expectedAgentsTarget "Factory AGENTS.md"
Test-LinkConflict $env:DEVIN_AGENTS $expectedAgentsTarget "Devin AGENTS.md"
Test-LinkConflict $env:CLAUDE_SKILLS $expectedSkillsTarget "Claude Code skills"
Test-LinkConflict $env:CLAUDE_INSTRUCTIONS $expectedAgentsTarget "Claude Code CLAUDE.md"

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
    Invoke-Native "curl.exe" @("--fail", "--location", "--silent", "--show-error", $env:AGENT_HUB_ARCHIVE_URL, "--output", $archive)
    Invoke-Native "tar.exe" @("-xzf", $archive, "--strip-components=1", "--directory", $extracted)

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
    $oldRelease = Get-LinkTarget $currentLink
    if (-not $oldRelease -and (Get-PathEntry $currentLink)) {
        Write-ErrorAndExit "$env:AGENT_HUB_HOME\current exists and is not a managed symlink"
    }

    $releasesDir = Join-Path $env:AGENT_HUB_HOME "releases"
    New-Item -ItemType Directory -Path $releasesDir -Force | Out-Null
    "managed by https://github.com/thinkforward-ai/agent-hub" | Out-File -FilePath (Join-Path $env:AGENT_HUB_HOME ".managed-by-agent-hub") -Encoding utf8

    if (-not (Test-Path $releaseDir -PathType Container)) {
        Move-Item $extracted $releaseDir
    }

    # Replace the current junction. Remove-Link deletes only the link, never
    # the release it points to.
    Remove-Link $currentLink
    New-Item -ItemType Junction -Path $currentLink -Target $releaseDir | Out-Null

    function New-Symlink {
        param(
            [string]$TargetPath,
            [string]$ExpectedTarget,
            [string]$ParentDir,
            [string]$ResourceName
        )

        New-Item -ItemType Directory -Path $ParentDir -Force | Out-Null
        if (Get-PathEntry $TargetPath) {
            if (-not (Test-SamePath (Get-LinkTarget $TargetPath) $ExpectedTarget)) {
                $timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss")
                $backup = "$TargetPath.backup.$timestamp"
                while (Get-PathEntry $backup) {
                    $backup = "$backup.$(Get-Random)"
                }
                Move-Item -LiteralPath $TargetPath -Destination $backup
                Write-Host "Preserved existing $ResourceName at $backup"
            }
        }

        if (-not (Get-PathEntry $TargetPath)) {
            if (Test-Path -LiteralPath $ExpectedTarget -PathType Container) {
                # Junctions work for directories without extra privileges.
                New-Item -ItemType Junction -Path $TargetPath -Target $ExpectedTarget | Out-Null
            } else {
                # Files need a symbolic link, which requires Developer Mode or
                # an elevated shell on Windows.
                try {
                    New-Item -ItemType SymbolicLink -Path $TargetPath -Target $ExpectedTarget | Out-Null
                } catch {
                    Write-ErrorAndExit "cannot create symbolic link for $ResourceName at ${TargetPath}: enable Windows Developer Mode or run as administrator"
                }
            }
        }
    }

    New-Symlink $env:FACTORY_SKILLS $expectedSkillsTarget $env:FACTORY_HOME "Factory skills"
    New-Symlink $env:DEVIN_SKILLS_HOME $expectedSkillsTarget $env:DEVIN_CONFIG_HOME "Devin skills"
    New-Symlink $env:FACTORY_AGENTS $expectedAgentsTarget $env:FACTORY_HOME "Factory AGENTS.md"
    New-Symlink $env:DEVIN_AGENTS $expectedAgentsTarget $env:DEVIN_CONFIG_HOME "Devin AGENTS.md"
    New-Symlink $env:CLAUDE_SKILLS $expectedSkillsTarget $env:CLAUDE_CONFIG_DIR "Claude Code skills"
    New-Symlink $env:CLAUDE_INSTRUCTIONS $expectedAgentsTarget $env:CLAUDE_CONFIG_DIR "Claude Code CLAUDE.md"

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
    Write-Host "Claude Code skills linked at $env:CLAUDE_SKILLS"
    Write-Host "Claude Code CLAUDE.md linked at $env:CLAUDE_INSTRUCTIONS"

} finally {
    if (Test-Path $tmpDir) {
        Remove-Item $tmpDir -Recurse -Force
    }
}
