# Multi-source skill management

**Accepted by:** Maxim Nikitin (project manager)
**Date:** 2026-10-02

## Problem Description

The existing installer links one Agent Hub snapshot of all skills into Factory Droid, Devin CLI, and Claude Code. It cannot select individual skills or combine Agent Hub, project, and third-party sources. Users want to browse and remove skills, assess their safety and stated purpose, and contribute improvements back to their original repositories. Keeping a single central snapshot would be simpler but would not support these requirements. A separate manifest in every external repository would limit use of existing third-party skills.

## Decision

Agent Hub owns a source manifest, initially listing its own repository, and installs its own skills as removable core skills. Users can add trusted repository URLs and use a built-in management skill to browse skills by source and choose individual skills for one globally shared skill set. Every source addition and skill installation requires review and explicit permission; serious safety-check failures block installation. Updates require delta review and approval, duplicate skill names block until the user chooses, and updates ask before restoring previously removed core skills.

## Explanation

The source manifest belongs to Agent Hub, not to external repositories. User-added URLs survive Agent Hub updates. The management skill follows registered URLs to discover skills and explains each skill's expected actions, effects, and risks before installation. Review applies to core and external skills alike. Discovery must not execute untrusted code, and safety checks can identify risks but cannot guarantee that instructions perfectly match their description. Each installed skill retains its source and exact revision for review, updates, and upstream contributions.

Selected skills are installed globally into a shared skill folder, linked by Factory Droid, Devin CLI, Claude Code, and future compatible clients. Source location does not limit install scope: a skill hosted in a project repository can still be installed globally. Users may remove core skills; an update offers to restore them rather than doing so silently. A collision does not silently replace an installed or user-owned skill.

## Consequences

- Replace whole-directory skill links with per-skill management and migrate existing installs without overwriting user-owned skills.
- Ship a built-in source manifest and preserve separately added trusted URLs across updates.
- Provide a management skill and local install mechanism for browsing, reviewing, installing, removing, updating, and tracking skill provenance.
- Define and implement review checks, explicit permission prompts, update-diff review, collision resolution, and restore prompts for removed core skills.
