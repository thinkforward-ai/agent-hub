---
name: make-decision
description: >
  Guide a registered open question through analysis, explicit acceptance, immutable
  decision creation, propagation, and follow-up review. Use when the user wants to
  work through or resolve an existing entry in open-questions.md. Use open-question
  first when the issue has not been registered.
source: https://github.com/thinkforward-ai/agent-hub
---

# Make a Decision

Use this skill to explore and resolve a registered open question:

**Explore → Decide → Resolve → Propagate → Review Follow-ups**

The open-question record is the source of truth while analysis is active. Once the
decision is made, an individual decision record becomes the durable source of truth.
Conversation supports these records but does not replace them.

If no matching entry exists in `open-questions.md`, propose opening a new question and
stop decision work until the question is registered. Do not assume or name another
skill that will perform the registration.

## Core Principles

- `open-questions.md` contains only unresolved questions (no status field).
- Store each accepted decision in its own file under `decisions/` (no indexes/metadata).
- Decision files are immutable after creation; no status field (creation = acceptance).
- Record accepting individual and role; ask when unknown; do not infer.
- Keep facts, constraints, proposals, evaluation, and decision separate.
- No silent inferences from discussion; resolution requires explicit user confirmation.
- Record interim conclusions in `### Resolution Points`, not as separate decisions.
- Keep question open until all points answered and user confirms readiness.
- Keep records concise: remove repetition/transcripts; preserve meaning and specifics.
- Summarize discussion faithfully; never copy verbatim.
- Never auto-create follow-ups; propose each for review; confirmed = new open question.
- Resolution complete when: decision record exists, entry removed, consequences reflected.

## Question Lifecycle

### 1. Explore

Guide user through decision; do not present arbitrary answer.

1. Restate decision in plain language.
2. Confirm missing constraints that could change outcome.
3. Generate focused set of materially different proposals.
4. Evaluate proposals against recorded criteria.
5. Investigate external facts when required (availability, cost, compatibility, legal).
6. Record durable findings; do not save conversational tangents.
7. Recommend leading option and explain decisive trade-off.
8. Mark resolution point complete only when user confirms.
9. Store confirmed outcome under `Resolution` and context under `Details`. Use `✅` for confirmed, `❓` for pending.

Use `AskUser` for clear choice decisions. Answer from project context when possible.

Expand open record during exploration:

```md
### Findings
- <Verified fact and implication>

### Evaluated Proposals
#### <Proposal>
- **Strengths:** <...>
- **Weaknesses:** <...>
- **Constraint fit:** <...>
```

Keep question in `open-questions.md` while analysis/confirmation incomplete.

### 2. Decide

Complete decision when: all `### Resolution Points` use `✅`, each has confirmed `Resolution`/`Details`, combined resolutions form coherent outcome, user confirms readiness.

Choosing one point in multi-part question ≠ decision record. Update that item's `Resolution`/`Details`, replace `❓` with `✅`, continue with pending points.

Before resolving: state exact decision (one sentence), summarize confirmed resolution points, confirm accepting individual/role, confirm ambiguous naming/scope/wording, distinguish decision from implementation.

Do not reopen settled aspects unless new evidence invalidates them.

### 3. Resolve

Resolution changes record type; resolved question removed from `open-questions.md`.

1. At acceptance, convert current time to UTC; create `decisions/<yyyymmdd-hhmm>-<title>.md`.
2. Use filesystem-safe title unique within same UTC minute; specify if collision possible.
3. Remove question from `open-questions.md`.
4. Advance next-question ID without reusing removed identifiers.
5. Never edit accepted decision file after creation.

Timestamp prefix is always UTC (filename omits timezone) for consistent chronological ordering across distributed teams. Do not use local time or rename files.

Use this decision-record structure:

```md
# <Decision title>

**Accepted by:** <Full name> (<relevant role>)
**Date:** YYYY-MM-DD

## Problem Description

<A concise synthesis of the problem and important context, including material facts,
constraints, proposals, opinions, comments, and disagreements.>

## Decision

<The final decision, stated directly.>

## Explanation

<What the decision means in practice, its scope and boundaries, and why it was chosen.>

## Consequences

- <What must now change or how future work should behave>
```

Carry open question into `## Problem Description` without losing meaning. Condense facts, constraints, proposals, findings, opinions, disagreements into short synthesis. Remove repetition/incidental conversation; retain specifics that materially explain problem/decision.

Do not carry open-question ID into decision record. Resolution removes question; preserve only concise context in `## Problem Description`.

### 4. Propagate

Update every in-scope source document made stale by decision (concept docs, architecture/records, plans/tasks, terminology, config/implementation).

Preserve one source of truth. Avoid copying full decision record into multiple files. Other documents should state resulting fact and link/refer to decision record.

### 5. Review Follow-ups

After propagation:

1. Identify work, uncertainty, verification, or further decisions following accepted decision.
2. Present concise list for user review; explain why each matters.
3. Use `AskUser` with multi-select for several follow-ups together.
4. Create no follow-up record before user confirmation.
5. For each confirmed follow-up, propose opening separate new question with registration context.
6. Do not assume/name registration skill; if capability available, action may trigger automatically; otherwise leave user with proposal/context.
7. Do not record declined follow-ups.

Follow-ups are separate open questions linked through concise context; not a field in decision record.

## Superseding a Decision

Do not reopen old question because implementation remains.

When new evidence undermines accepted decision:

1. Open new question with new `Q<n>` ID.
2. Preserve accepted decision while exploring new question.
3. If replacement accepted, create new decision record.
4. Identify earlier decision filename concisely in new record's `## Problem Description`.
5. Leave earlier decision file completely unchanged.

Never correct/annotate/reformat/change metadata of accepted decision file. If record contains error, open new question and create correcting decision.

## Validation

Before completing workflow, verify:

**Question structure:** one ID/title, no status field, all resolution points use `✅` with `Resolution`/`Details`, user confirmed complete question (not just interim points).

**Decision accuracy:** final decision matches user's exact choice, decision record names accepting individual/role, no status field.

**File integrity:** decision has own immutable `<yyyymmdd-hhmm>-<title>.md` file, timestamp is UTC, title unique within minute, `decisions/` contains only immutable records, no previous decision files modified, resolved question removed from `open-questions.md`, question IDs not reused.

**Content quality:** explanation/consequences do not contradict decision, question/decision concise/repetition-free, problem description preserves meaning/specifics including viewpoints/disagreements, affected documents reflect decision, no stale proposals described as selected outcome.

**Follow-ups:** every potential follow-up proposed for review, only user-confirmed follow-ups proposed as new open questions.

Report: accepted decision filename/decision, documents updated, confirmed follow-up proposals (if any).
