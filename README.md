# Agent Hub

Shared agent skills and global instructions installed from one central copy.

## Install on Linux/macOS

```bash
curl -fsSL https://raw.githubusercontent.com/thinkforward-ai/agent-hub/main/bin/install.sh | bash
```

To preserve existing files before replacement:

```bash
bash install.sh --backup-existing
```

## Install on Windows

```powershell
irm https://raw.githubusercontent.com/thinkforward-ai/agent-hub/main/bin/install.ps1 | iex
```

To preserve existing files before replacement:

```powershell
.\install.ps1 -BackupExisting
```

## What the installer does

The installer downloads a clean snapshot to `~/.agent-hub` and creates symlinks to:

- **Skills:**
  - `~/.factory/skills` (Factory)
  - `~/.config/devin/skills` (Devin CLI)
  - `~/.claude/skills` (Claude Code)

- **Global Instructions:**
  - `~/.factory/AGENTS.md` (Factory)
  - `~/.config/devin/AGENTS.md` (Devin CLI)
  - `~/.claude/CLAUDE.md` (Claude Code, which reads `CLAUDE.md` instead of `AGENTS.md`)

If any of these paths already exist, the installer will fail unless you use the backup option.

## Updating

Run the installer again to update the central snapshot. Existing `~/.agent-hub/.env` content is preserved.

## Planned skill management

The current installer still links the entire skills directory and does not support selecting individual skills or adding sources. Bundled defaults in [`sources.json`](sources.json) list Agent Hub and project-guide, but the installer does not use them yet. The accepted [multi-source skill management](decisions/20261002-1759-multi-source-skill-management.md), [one-time migration](decisions/20261002-1831-one-time-skills-reset-migration.md), [URL-only source registry](decisions/20261002-2026-url-only-skill-source-registry.md), and [safety review](decisions/20261002-2058-skill-source-safety-review.md) decisions describe the remaining intended design. In the future, the installer will set up or migrate skills once, and a management skill will handle later changes.

## Instruction Hierarchy

Agent Hub follows this instruction hierarchy:

1. `~/.agent-hub/current/AGENTS.md` — Universal behavior (all projects)
2. `project/AGENTS.md` — Project-specific rules
3. `project/subdirectory/AGENTS.md` — Area-specific refinements

This ensures global Agent Hub instructions apply universally while allowing project-specific overrides.
