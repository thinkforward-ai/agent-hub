# Skill source safety review

**Accepted by:** Maxim Nikitin (project manager)
**Date:** 2026-10-02

## Problem Description

The [multi-source skill management decision](20261002-1759-multi-source-skill-management.md) requires review and permission before adding repositories or installing and updating skills, with serious findings blocking installation. Skills can contain instructions, scripts, and supporting files whose effects differ from their description. Treating every use of code or the network as unsafe would reject legitimate skills; treating those capabilities as harmless would conceal risk. Static inspection cannot prove that a skill is safe or perfectly aligned with its stated purpose. The [legacy migration decision](20261002-1831-one-time-skills-reset-migration.md) allows a one-time exception to permission prompts, not to safety checks.

## Decision

Review source repositories and candidate skills separately, without executing source content. For the first version, fetch only public HTTPS repository URLs without embedded credentials, checking redirects and blocking private or local destinations. Disclose expected actions and capabilities, warn and require approval for unexpected but not clearly harmful ones, and block clear harmful behavior or incomplete/unsafe review without override. Explain effects and uncertainty before separately approving each source addition, installation, or update. Installation approval does not authorize consequential actions when the skill is later used.

## Explanation

Before registering a source, verify its reachable destination, owner/host, and expected root `skills/` layout. Registering a source permits browsing, not installing its skills. Apply the same checks to a skill's own `source` URL when checking for updates, even when that URL is not registered. Treat every remote file as data during review; do not run scripts, tests, hooks, or dependencies. Inspect the candidate's `SKILL.md` and effect-bearing supporting files. Block if the source or files cannot be reviewed, a path escapes the skill directory, or a name collision remains unresolved. Stage the reviewed files and re-review if the source changes before use.

Compare the skill's actual instructions and tool capabilities with its declared purpose. Expected file writes, network calls, or code execution must be disclosed but are not blocked solely for being powerful. Warn about unexpected capabilities that are not clearly harmful. Block clear instructions to steal secrets, bypass safeguards, conceal actions, or perform unrelated destructive or external actions; explain the reason and offer no override.

For a new skill, summarize purpose, expected and unexpected actions, files and tools it may access, external services and data it may send, side effects, warnings, and review limits. For an update, compare the installed copy with the same fetched snapshot that would be installed, explain changes in behavior, context, and concept, and highlight contradictions, breaking changes, and uncertainty, not only a textual diff. Declined approval means no change. Legacy migration may install reviewed core skills without prompts, but a blocking finding in a new core skill prevents cutover.

## Consequences

- Incorporate this policy into the draft management skill; do not claim that its static review certifies safety.
- Validate URL restrictions, incomplete review, malicious instructions, path escapes, collisions, behavioral summaries, and separate approvals before enabling installations.
- Preserve use-time permission checks for consequential actions, independently of installation approval.
