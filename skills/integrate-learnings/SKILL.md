---
name: integrate-learnings
description: Review and integrate reusable learnings through two approval gates. Use when the user mentions a knowledge gem, learning points, lessons learned, or learning findings, or when mandatory passive detection finds a candidate, such as a workaround after a failed attempt, a non-obvious fix, a command, path, or setting that took several tries to find, or a user correction.
source: https://github.com/thinkforward-ai/agent-hub
---

# Integrate Learnings

## Triggers

Activate only when:

1. The user asks about `knowledge gem`, `learning point`, `lessons learned`, or `learning findings`.
2. Mandatory passive detection identifies a reusable finding that can save time, shortcut to a solution, avoid unnecessary attempts, or prevent repeated failures.

Skip temporary, duplicate, unsupported, or non-actionable findings.

## Passive detection

When invoked, check whether effective session instructions contain an equivalent rule:

```md
## Mandatory passive learning detection

At every session start or resume, you MUST activate passive learning detection and keep it active for the entire session. Do not skip or defer activation. Confirm activation by starting your first response of the session with `Learning detection: active`.

During all work, watch for reusable findings that save time, shortcut to a solution, avoid unnecessary attempts, or prevent repeated failures, such as a workaround after a failed attempt, a non-obvious fix, a command, path, or setting that took several tries to find, or a user correction. When one is found, invoke `integrate-learnings`.

This is mandatory passive session behavior, not background polling.
```

If absent, propose the exact addition and install it only after approval. Continue the current review either way.

## First gate

For passively detected candidates, use `AskUser`:

`Hooray! Knowledge gem found: <short learning>. Review it?`

Options:

1. `Review`
2. `Ignore`

An explicit user trigger implies `Review`. If ignored, stop without recording anything.

If the user answers any gate with a question or feedback, answer it, then repeat the same gate with its exact wording and options.

## Multiple candidates

If several candidates appear, list them numbered with short descriptions and ask:

`Hooray! Multiple knowledge gems found. Review one by one?`

Options: `Review`, `Ignore`.

On `Review`, process them in order, finishing each before the next. On `Ignore`, stop.

## Review

Present:

```md
**Finding:** <reusable learning>

**Why:** <evidence → impact>

**Where:** <destinations>; upstream: <source URL, if a remote skill>

**Change:** <exact wording, edit, setting, or instruction>
```

Recommend every destination that should change to integrate the learning consistently. Explain why each destination is appropriate. Consider scope, lifetime, audience, ownership, and mutability. The user may choose different destinations.

When a destination is a skill file from a remote source repository, name its source URL as upstream and make the fix in the source, cloning it or finding it locally.

Add `Trade-offs` only when material.

## Second gate

Use `AskUser` with the review as each option's preview, fields separated by blank lines, so the dialog cannot hide it. If it does not fit, print the review and give the options as text instead:

1. `Adopt`
2. `Ignore`

The user may type feedback instead. Do not edit persistent artifacts before `Adopt`.

## Adoption

On `Adopt`, apply only the approved exact change, validate it, and report the destination and result.

On `Ignore`, stop without recording or changing anything.
