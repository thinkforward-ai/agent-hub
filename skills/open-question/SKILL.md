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

- Keep `open-questions.md` limited to unresolved questions.
- Presence in the file implies the question is open; never add a status field.
- Give each question the next stable `Q<n>` ID and advance `Next question ID`.
- Never reuse an ID removed during resolution.
- One question covers one coherent decision. Split independent issues.
- Keep the record concise. Preserve meaning and important specifics, not conversation
  transcripts.
- Check existing open questions and accepted decisions before creating a duplicate.
- Record only known context. Do not invent constraints, criteria, resolutions, or
  details.
- Creating the question does not authorize investigation or external action.

## Workflow

### 1. Establish the Need

Capture:

- the exact question,
- why it matters or what it blocks,
- the minimum relevant context,
- known constraints,
- the points that must be resolved.

For a confirmed follow-up, frame the follow-up as a question to investigate or decide.
Mention the source decision filename in `### Context` only when useful.

Ask the user only when missing information prevents a clear, useful record.

### 2. Check for Duplication

Read `open-questions.md` and relevant files under `decisions/`.

- If an open question already covers the issue, update that question only with
  non-duplicative important context.
- If an accepted decision already answers it, do not open a duplicate. Explain the
  existing answer.
- If new evidence challenges an accepted decision, open a new question and identify
  the earlier decision concisely in `### Context`.

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

Omit `### Constraints` when none are known. Add `### Decision Criteria`,
`### Findings`, or `### Proposals` later only when they contain useful information.

After appending the question, advance `Next question ID` to the next unused value.

### 4. Validate

Verify:

- the ID is new and the next ID advanced,
- the title and question describe one coherent issue,
- no status field exists,
- the record is concise and contains no placeholders,
- every resolution point uses `❓` and says `Resolution: Pending`,
- no duplicate question or already-settled decision was created,
- no investigation or external action was performed without separate authorization.

Report only the created or updated question ID and title.

## Completion Boundary

This skill ends after registration. Do not analyze, decide, resolve, propagate, or
create follow-up work.
