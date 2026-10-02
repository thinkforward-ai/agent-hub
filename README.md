# Agent Hub

Shared agent skills and global instructions installed from one central copy.

## Install on Linux/macOS

```bash
curl -fsSL https://raw.githubusercontent.com/thinkforward-ai/agent-hub/main/bin/install.sh | bash
```

The installer makes a verified compressed backup before replacing a legacy skills layout. It does not need an extra flag.

## Install on Windows

```powershell
irm https://raw.githubusercontent.com/thinkforward-ai/agent-hub/main/bin/install.ps1 | iex
```

The installer makes a verified compressed backup before replacing a legacy skills layout. It does not need an extra switch.

## What the installer does

The installer downloads a clean snapshot, installs `AGENTS.md` directly at `~/.agent-hub/AGENTS.md`, seeds the editable `~/.agent-hub/sources.json` from the bundled [`sources.json`](sources.json), and links `~/.agent-hub/skills` to:

- **Skills:**
  - `~/.factory/skills` (Factory)
  - `~/.config/devin/skills` (Devin CLI)
  - `~/.claude/skills` (Claude Code)

- **Global Instructions:**
  - `~/.factory/AGENTS.md` (Factory)
  - `~/.config/devin/AGENTS.md` (Devin CLI)
  - `~/.claude/CLAUDE.md` (Claude Code, which reads `CLAUDE.md` instead of `AGENTS.md`)

Fresh setup installs Agent Hub core skills without prompts from the hardcoded official archive. Existing instruction files that do not belong to Agent Hub are never replaced.
On Windows, creating instruction file links requires Developer Mode or an elevated shell.

## Migrating a legacy installation

Run the same installer command. For legacy skills, it verifies a compressed backup of the previous release and skill paths before switching to the new layout. Old skills, including `synced/`, are no longer active; recover them from the backup if needed. For an already-managed installation with a `current` link, it backs up that release and moves only instruction links, without changing installed skills. Existing `~/.agent-hub/.env` and source URLs stay in place. Only the two most recent installer-managed version backups are retained.

## After installation

Use the `manage-skills` skill to browse sources and to review, install, remove, or update skills. Rerunning the installer on the new layout makes no changes.

The design is recorded in [multi-source skill management](decisions/20261002-1759-multi-source-skill-management.md), [one-time migration](decisions/20261002-1831-one-time-skills-reset-migration.md), [URL-only source registry](decisions/20261002-2026-url-only-skill-source-registry.md), [safety review](decisions/20261002-2058-skill-source-safety-review.md), and [trusted core installation](decisions/20261002-2152-trusted-agent-hub-core-installation.md).

## Instruction Hierarchy

Agent Hub follows this instruction hierarchy:

1. `~/.agent-hub/AGENTS.md` — Universal behavior (all projects)
2. `project/AGENTS.md` — Project-specific rules
3. `project/subdirectory/AGENTS.md` — Area-specific refinements

This ensures global Agent Hub instructions apply universally while allowing project-specific overrides.
