# Overview

## Goal

Provide one shared collection of agent skills and general instructions for Factory Droid, Devin CLI, and Claude Code, with controlled discovery and management of skills from multiple repositories.

## Context

Agent Hub moved from linking one complete skills snapshot to a shared set of individually managed skills. This repository contains the installers, core skills, default source list, accepted decisions, and remaining research questions.

## Scope

1. Install global instructions and shared skill links for supported clients on Linux/macOS and Windows.
2. Seed trusted Agent Hub core skills during setup. Use the management skill to browse, review, install, update, and remove skills afterward.
3. Keep source repositories unchanged and maintain the editable repository URL list separately from installed skills.
4. Keep current understanding here, unresolved questions in `open-issues.md`, accepted decisions in `decisions/`, and any future raw input artifacts unchanged in `inputs/`.

## Constraints

1. Preserve unrelated user data and settings; back up and verify legacy migrations before replacing active skills.
2. Review external sources and skills without executing them. Block unsafe or incomplete reviews and unresolved name collisions.
3. Require separate approval for non-core source additions and skill changes. Installing a skill does not authorize its later consequential actions.
4. Keep accepted decision records immutable. The later URL-only registry and trusted-core decisions narrow earlier decisions without editing them.

## Contributing Roles

1. Project manager: sets direction and accepts decisions.
2. Skill maintainer: designs and reviews skill workflows.
3. Installer maintainer: handles platform setup, migration, and recovery.
4. Safety and validation reviewer: assesses skill sources and cross-platform behavior.

## Open Questions

The remaining questions are tracked in [open-issues.md](open-issues.md).
