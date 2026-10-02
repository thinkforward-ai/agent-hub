# Trusted Agent Hub core installation

**Accepted by:** Maxim Nikitin (project manager)
**Date:** 2026-10-02

## Problem Description

The [skill source safety review](20261002-2058-skill-source-safety-review.md) requires approval for fresh skill installs; the [one-time skills reset migration](20261002-1831-one-time-skills-reset-migration.md) exempts only legacy migration from prompts. For first-party setup, the owner trusts Agent Hub's own source and wants core skills installed without interaction. Both installers also allowed an `AGENT_HUB_ARCHIVE_URL` override, which would otherwise let an unrelated archive inherit that trust.

## Decision

Both installers must fetch only the hardcoded official Agent Hub archive and install its core skills without per-skill approval prompts on fresh setup or legacy migration. Remove the archive URL override. Keep structural archive and package checks and stop on unsafe or incomplete input.

## Explanation

This is a narrow exception to the earlier fresh-install approval rule, not a waiver for arbitrary sources. Registering outside repositories and installing or updating skills through the manager still require their own review and approval. Installing a core skill does not authorize consequential actions when it is later used. Earlier decision records stay unchanged.

## Consequences

- Remove approval prompts and `AGENT_HUB_ARCHIVE_URL` override from both installers.
- Make initial setup non-interactive while retaining archive-path, link, and required-file checks.
- Update setup documentation and keep the safety boundary explicit.
