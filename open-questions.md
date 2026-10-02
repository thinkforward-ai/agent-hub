# Open Questions

This file contains only unresolved questions that currently require investigation or a decision.

**Next question ID:** Q8

## Q4: Upstream skill contributions

### Question

How should Agent Hub help a user contribute improvements to a skill's original repository when its source is identifiable?

### Why It Matters

Skills may come from project or third-party repositories; changes should be directed to their actual maintainers rather than silently diverging in the local installation.

### Context

Follow-up to [multi-source skill management](decisions/20261002-1759-multi-source-skill-management.md) and [URL-only skill source registry](decisions/20261002-2026-url-only-skill-source-registry.md).

### Constraints

- Use the installed skill's `source` URL when present; no exact installed revision is stored. If missing or questionable, investigate only on user request.
- Do not publish or send changes without a user request.

### Resolution Points

- ❓ **Contribution workflow**
  - **Resolution:** Pending
  - **Details:** Define how to prepare and review a change against its source without a recorded revision, and handle missing, read-only, or unavailable upstream repositories.

## Q5: Cross-platform skill validation

### Question

How should the new installation and management workflows be verified across supported operating systems and clients?

### Why It Matters

Linux/macOS symlinks and Windows junctions or file links behave differently; migration, removal, and updates must preserve a consistent global skill set.

### Context

Follow-up to [multi-source skill management](decisions/20261002-1759-multi-source-skill-management.md), [one-time skills reset migration](decisions/20261002-1831-one-time-skills-reset-migration.md), [URL-only skill source registry](decisions/20261002-2026-url-only-skill-source-registry.md), [skill source safety review](decisions/20261002-2058-skill-source-safety-review.md), and [trusted Agent Hub core installation](decisions/20261002-2152-trusted-agent-hub-core-installation.md).

### Constraints

- Cover Factory Droid, Devin CLI, and Claude Code, with a path for future compatible clients.
- Preserve unrelated user-owned data and settings; legacy skill contents are kept only in the two-backup rotation.

### Resolution Points

- ❓ **Test matrix**
  - **Resolution:** Pending
  - **Details:** Define supported platform/client combinations and no-prompt trusted core setup, unattended legacy reset, repeat-install no-op, URL-only registry persistence, root `skills/` discovery, source-less skill updates, source URL restrictions, unsafe/incomplete skill reviews, behavioral explanations, separate approvals for non-core changes, managed updates, collision, backup restoration, link reconstruction, and oldest-backup pruning scenarios.

### Findings

1. Before the trusted-core exception, twelve temporary offline Linux installer checks passed (fresh approval, legacy reset, backup retention, archive link rejection, source seeding, and rollback). The test file was removed at the user's request.
2. macOS and Windows runtime validation remains open; PowerShell is unavailable in the current environment.
3. Skill-only browsing, installation, updates, removal, and behavioral safety review remain unverified.
4. After the trusted-core exception, a temporary offline Linux check passed for no-prompt fresh setup, hardcoded URL despite an override variable, and repeat-install no-op.
