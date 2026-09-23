# Open Questions

This file contains only unresolved questions that currently require investigation or a decision.

**Next question ID:** Q2

## Q1: Selective skill installation from multiple sources

### Question

How should agent-hub let users choose which skills to install locally when skills come from several sources?

### Why It Matters

The installer (`bin/install.sh`, `bin/install.ps1`) installs one central snapshot of all agent-hub skills. As domain projects add skills, users need only the relevant subset, and the installer can't select skills or pull them from other sources.

### Context

Skill sources now include:
- common skills (agent-hub `skills/`);
- household skills (`household/.claude/skills/`: `use-claude-in-chrome`, `ah-order-history`);
- business skills (business-lab);
- possibly external skill registries.

Some project skills are generic. For example, `use-claude-in-chrome` lives in household but could be common.

### Resolution Points

- ❓ **Source model**
  - **Resolution:** Pending
  - **Details:** How sources (agent-hub, domain repos, external registries) are declared and discovered.
- ❓ **Selection UX**
  - **Resolution:** Pending
  - **Details:** How the user picks skills: per skill, per source, or per bundle.
- ❓ **Install scope and targets**
  - **Resolution:** Pending
  - **Details:** Global vs project-local install, and which agent directories are targeted.
- ❓ **Skill placement**
  - **Resolution:** Pending
  - **Details:** Criteria for whether a skill is common or domain-specific.
- ❓ **Updates and conflicts**
  - **Resolution:** Pending
  - **Details:** Keeping installed skills current and handling name collisions between sources.
