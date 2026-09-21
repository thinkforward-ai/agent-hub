# Agent Hub

Shared agent skills and global instructions installed from one central copy.

## Install

1. Download the installer:

   ```bash
   curl -fsSLO https://raw.githubusercontent.com/thinkforward-ai/agent-hub/main/bin/install.sh
   ```

2. Review `install.sh`.

3. Install:

   ```bash
   bash install.sh
   ```

The installer downloads a clean snapshot to `~/.agent-hub` and links both:

- **Skills:**
  - `~/.factory/skills` (Factory)
  - `~/.config/devin/skills` (Devin CLI)

- **Global Instructions:**
  - `~/.factory/AGENTS.md` (Factory)
  - `~/.config/devin/AGENTS.md` (Devin CLI)

to its central skills and instruction directories.

**Warning:** If any of these paths already exist, the installer will fail unless you use `--backup-existing`. Existing files will be backed up with a timestamp before replacement.

If existing files exist, preserve them before replacement:

```bash
bash install.sh --backup-existing
```

Run the installer again to update the central snapshot. Existing
`~/.agent-hub/.env` content is preserved.

## Instruction Hierarchy

Agent Hub follows this instruction hierarchy:

1. `~/.agent-hub/current/AGENTS.md` — Universal behavior (all projects)
2. `project/AGENTS.md` — Project-specific rules
3. `project/subdirectory/AGENTS.md` — Area-specific refinements

This ensures global Agent Hub instructions apply universally while allowing project-specific overrides.
