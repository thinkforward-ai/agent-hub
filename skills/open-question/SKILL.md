---
name: open-question
description: >
  Register a new blocker, unresolved choice, question, or user-confirmed follow-up in
  open-questions.md using the project's concise question format. Use when something
  new requires investigation or resolution. This skill records the question only; it
  does not analyze, decide, or resolve it.
source: https://github.com/thinkforward-ai/agent-hub
---

# Open Question

Register work that requires investigation, judgment, verification, or a decision.
Do not solve the question in this skill.

## When to Use

Use when:

- a new blocker, ambiguity, contradiction, or unresolved choice appears;
- missing information prevents safe progress;
- the user confirms a proposed follow-up should be tracked;
- an accepted decision must be reconsidered through a new question.

Do not use for a routine task whose required action is already known, unless the user
explicitly confirms it as a follow-up question.

## Rules

- `open-questions.md` contains only unresolved questions (no status field).
- Use next stable `Q<n>` ID; advance `Next question ID`; never reuse IDs.
- One question = one coherent decision. Split independent issues.
- Keep records concise: preserve meaning, not conversation transcripts.
- Check existing questions and decisions before creating duplicates.
- Record only known context; do not invent constraints or resolutions.
- Registration does not authorize investigation or external action.

## Workflow

### 1. Establish the Need

Capture: exact question, impact/blocker, minimum context, known constraints, resolution points.

For follow-ups: frame as investigation/decision question. Mention source decision filename in `### Context` when useful.

Ask user only when missing information prevents a clear record.

### 2. Check for Duplication

Read `open-questions.md` and `decisions/`:

- If open question exists: update with non-duplicative context only.
- If decision answers it: do not duplicate; explain existing answer.
- If new evidence challenges decision: open new question; identify earlier decision in `### Context`.

### 3. Register the Question

If `open-questions.md` does not exist, create:

```md
# Open Questions

This file contains only unresolved questions that currently require investigation or a decision.

**Next question ID:** Q1
```

Append the new question using:

```md
## Q<n>: <Concise title>

### Question

<One specific question to answer.>

### Why It Matters

<Concise impact, risk, or blocker.>

### Context

<Only the background needed to understand the question.>

### Constraints

- <Known hard requirement or boundary>

### Resolution Points

- ❓ **<Point>**
  - **Resolution:** Pending
  - **Details:** <Known context or remaining question>
```

Omit `### Constraints` when unknown. Add `### Decision Criteria`, `### Findings`, or `### Proposals` later only when useful.

Advance `Next question ID` after appending.

### 4. Validate

Verify: new ID, next ID advanced, coherent issue, no status field, concise/no placeholders, resolution points use `❓`/`Resolution: Pending`, no duplicates, no unauthorized investigation.

Report only created/updated question ID and title.

## Completion Boundary

This skill ends after registration. Do not analyze, decide, resolve, propagate, or
create follow-up work.
