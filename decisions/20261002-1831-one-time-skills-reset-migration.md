# One-time skills reset migration

**Accepted by:** Maxim Nikitin (project manager)
**Date:** 2026-10-02

## Problem Description

The legacy installer links one versioned Agent Hub skills directory into Factory Droid, Devin CLI, and Claude Code, and deletes the previous release after updates. The project owner's installation also contains `synced/` inside that directory. The [multi-source skill management decision](20261002-1759-multi-source-skill-management.md) requires a shared, individually managed skill set and review and permission before installing every skill, including core skills. For the first rollout to the project owner and one other user, transferring each old skill or shipping a separate bridge release would add complexity. They prefer a single, skills-only fresh start. This decision makes a one-time exception to the earlier decision's per-skill permission requirement for legacy migration only; the earlier record remains unchanged.

## Decision

Build and test skill browsing, installation, and source registration before rollout. The existing installer entry point performs a one-time, unattended migration of a legacy installation: verify a compressed backup, replace the active legacy skills with fresh Agent Hub core skills and the new shared layout, verify the result, and automatically roll back on failure. Previously installed skills, including `synced/`, are not transferred to the active set. The management skill handles subsequent source and skill changes; rerunning the installer on an already migrated layout makes no skill changes.

## Explanation

The reset affects skills only. Preserve local settings, global instructions, user-added sources, and unrelated files. Before changing the old setup, archive the managed release, including old skill files, and record original client link targets. Back up an unexpected directory before replacing it, or preserve an unexpected link and its target metadata without deleting the target; stop if a safe backup is impossible. Stage the new layout before switching the clients, then verify they can see the core skills. On failure, restore the previous setup. Report the backup location and which old skills are no longer active.

Keep at most two Agent Hub-managed compressed old-version backups. Prune the oldest only after a new installation has been verified; do not prune user-owned backups. Old skills are available from these short-term backups, not kept indefinitely in active or separate recovery storage.

Legacy migration alone skips the earlier decision's per-skill review and permission prompts, including for the newly installed manager skill. Automated safety checks still apply; a serious failure in a new core skill blocks migration. A fresh initial installation follows normal review and approval. After migration, the management skill follows the earlier decision's review and approval rules for additions and updates. The installer is not a recurring updater for the new layout.

## Consequences

- Replace the legacy installer upgrade path with a one-time fresh-layout migration while retaining the existing installer command for customers.
- Implement verified backup, short-term two-version retention, safe replacement of unexpected client paths, post-switch verification, and automatic rollback.
- Ship and test the management skill and its source registry before making the migration available.
- Explain that old skills must be reinstalled through the manager if wanted, and that the installer no longer updates skills after migration.
