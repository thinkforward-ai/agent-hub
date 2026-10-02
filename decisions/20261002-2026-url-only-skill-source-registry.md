# URL-only skill source registry

**Accepted by:** Maxim Nikitin (project manager)
**Date:** 2026-10-02

## Problem Description

The [multi-source skill management decision](20261002-1759-multi-source-skill-management.md) calls for an Agent Hub-owned source manifest, user-added repositories, and exact installed-skill revisions. The draft manager also assumed a separate installation record. Users want a simpler source list and a skill-only manager. A structured per-skill record would make exact provenance and reproducibility easier, but adds state they do not want to maintain. This decision replaces the earlier exact-revision and per-skill ownership-record assumptions; the earlier decision file remains unchanged.

## Decision

Use one editable `~/.agent-hub/sources.json` containing only a JSON array of repository URL strings, seeded with the Agent Hub repository on first setup. Browse each registered repository's latest default branch for skills at its root `skills/<name>/SKILL.md`. Keep installed skills as local copies without a separate installation or revision record. The management skill owns the shared skills folder and compares installed files with the latest source files when updating.

## Explanation

Preserve the edited registry across Agent Hub updates. Registry membership enables discovery, not ownership of installed skills: removing a URL does not uninstall its skills. An installed skill with a `source` URL can still be checked for updates even if that URL was removed from the registry. A skill without a source URL receives no update offer unless the user asks to find its source and add the URL.

Do not execute repository content during discovery or treat remote instructions as commands. Present candidates grouped by source. For updates, explain differences in behavior, context, and concept between the installed copy and current source, including contradictions, breaking changes, and uncertainty; do not rely on a textual diff alone. Ask permission before installing or changing a skill, and block unresolved name collisions. Source URLs declared by skills are untrusted until reviewed. No semantic-version interface or stored per-skill commit is required.

The manager treats the shared skills folder as manager-owned as a whole, including entries placed there manually. It still requires explicit approval for removals and replacements rather than silently overwriting a folder. The initial layout rule is deliberately narrow; revisit it if skill repositories use other paths.

## Consequences

- Seed and preserve a URL-only `sources.json` outside versioned releases; do not require manifests in external repositories.
- Revise the draft management skill to browse root `skills/` directories, use optional `source` URLs for updates, and drop references to an installation or exact-revision record.
- Review the same fetched source content that is installed; do not execute source files during discovery or updates.
- Upstream contributions cannot assume an exact stored revision; missing or questionable source URLs need user-directed investigation.
