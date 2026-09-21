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

- Keep only unresolved questions in `open-questions.md`. Presence in this file implies
  that the question is open; do not add a status field.
- Store each accepted decision in its own file under `decisions/`.
- Keep `decisions/` free of indexes, READMEs, and other mutable metadata.
- Treat every accepted decision file as immutable after creation.
- Do not add a status to decision records. Creating the immutable record means the
  decision is accepted; otherwise the question remains open.
- Record the individual who accepted the proposal and their relevant role. Ask when
  either is unknown; do not infer identity or authority.
- Keep facts, constraints, proposals, evaluation, and the final decision separate.
- Do not silently infer a decision from discussion. Resolution requires an explicit
  user choice or confirmation.
- Record interim conclusions in the relevant `### Resolution Points` item, not as
  separate accepted decisions.
- Keep a question open until every in-scope point is answered and the user explicitly
  confirms that the complete decision is ready to resolve.
- Keep open questions and decisions concise. Remove repetition, transcript-like detail,
  and wording that does not affect understanding.
- Preserve meaning and important specifics, including material facts, constraints,
  proposals, opinions, comments, disagreements, and rejected alternatives.
- Summarize discussion faithfully instead of copying it verbatim.
- Never create follow-up work automatically. Propose each follow-up for user review;
  every confirmed follow-up becomes a new open question.
- A question is not resolved until its decision record exists, the open entry is
  removed, and consequences are reflected in the relevant source documents.

## Question Lifecycle

### 1. Explore

Guide the user through the decision rather than presenting an arbitrary answer.

1. Restate the decision in plain language.
2. Confirm missing constraints that could change the outcome.
3. Generate a focused set of materially different proposals.
4. Evaluate proposals against the recorded criteria.
5. Investigate external facts when required, such as availability, cost, compatibility,
   or legal restrictions.
6. Record durable findings in the question. Do not save every conversational tangent.
7. Recommend a leading option and explain the decisive trade-off.
8. Mark a resolution point complete only when the user confirms it.
9. Store the confirmed outcome under `Resolution` and concise supporting context under
   `Details`. Mark confirmed points with `✅`; keep unresolved points marked `❓` with
   `Resolution: Pending`.

Use `AskUser` when the next step requires the user to choose between clear options.
Do not ask questions that can be answered from available project context.

During exploration, expand the open record as needed:

```md
### Findings

- <Verified fact and its implication>

### Evaluated Proposals

#### <Proposal>

- **Strengths:** <...>
- **Weaknesses:** <...>
- **Constraint fit:** <...>
```

Keep the question in `open-questions.md` while analysis or confirmation is incomplete.

### 2. Decide

A complete decision exists only when:

- every item under `### Resolution Points` uses `✅`,
- every item contains a confirmed `Resolution` and sufficient `Details`,
- the combined resolutions form one coherent outcome, and
- the user explicitly confirms that the whole question is ready to resolve.

Choosing one point within a multi-part question does not create a decision record.
Update that item's `Resolution` and `Details`, replace `❓` with `✅`, then continue
with the pending points.

Before resolving:

- state the exact decision in one sentence,
- summarize all confirmed resolution points that form the decision,
- confirm the individual accepting the proposal and their relevant role,
- confirm any naming, scope, or wording that would otherwise remain ambiguous,
- distinguish the decision itself from later implementation work.

Do not keep reopening settled aspects unless new evidence invalidates them.

### 3. Resolve

Resolution changes the record type. A resolved question is no longer kept in
`open-questions.md`.

1. At acceptance time, convert the current time to UTC and create
   `decisions/<yyyymmdd-hhmm>-<title>.md`.
2. Use a filesystem-safe title that is unique among decisions accepted in the same UTC
   minute. Make the title more specific if the filename would collide.
3. Remove the question from `open-questions.md`.
4. Advance the next-question ID without reusing removed identifiers.
5. After creation, never edit the accepted decision file.

The timestamp prefix is always UTC even though the filename omits a timezone marker.
This provides consistent chronological ordering across distributed teams without a
bounded sequence number. Do not use local time. Do not rename an accepted decision
file later.

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

Carry the open question into `## Problem Description` without losing its meaning.
Condense facts, constraints, proposals, findings, opinions, comments, disagreements,
and rejected alternatives into a short synthesis. Remove repetition and incidental
conversation, but retain every specific that materially explains the problem or
decision.

Do not carry the open-question ID into the decision record. Resolution removes that
question; preserve only its concise, meaningful context in `## Problem Description`.

### 4. Propagate

Update every in-scope source document that is made stale by the decision. Examples:

- concept or requirements documents,
- architecture or design records,
- plans and task lists,
- user-facing terminology,
- configuration or implementation.

Propagation must preserve one source of truth. Avoid copying the full decision record
into several files. Other documents should state the resulting fact and link or refer
to the decision record when appropriate.

### 5. Review Follow-ups

After propagation:

1. Identify work, uncertainty, verification, or further decisions that follow from the
   accepted decision.
2. Present a concise list for user review. Explain why each item matters.
3. Use `AskUser` with multi-select when several follow-ups can be reviewed together.
4. Create no follow-up record before the user confirms it.
5. For each confirmed follow-up, propose opening a separate new question and provide
   the concise context needed to register it.
6. Do not assume or name another skill that will perform the registration. If a
   matching capability is available, the proposed action may trigger it automatically;
   otherwise leave the user with the proposal and context.
7. Do not record declined follow-ups.

Follow-ups do not appear as a field in the accepted decision record. They are separate
open questions linked through concise context where relevant.

## Superseding a Decision

Do not reopen the old question merely because implementation remains.

When new evidence undermines an accepted decision:

1. Open a new question with a new `Q<n>` ID.
2. Preserve the accepted decision while the new question is explored.
3. If a replacement is accepted, create a new decision record.
4. Identify the earlier decision filename concisely in the new record's
   `## Problem Description`.
5. Leave the earlier decision file completely unchanged.

Never correct, annotate, reformat, change the metadata of, or otherwise modify an
accepted decision file. If an accepted record contains an error, open a new question
and create a correcting decision.

## Validation

Before completing the workflow, verify:

- the question has one ID and title, with no redundant status field,
- every resolution point uses `✅` and contains `Resolution` and `Details`,
- the user confirmed the complete question, not only one interim point,
- the final decision matches the user's exact choice,
- the decision record names one accepting individual and their relevant role,
- the decision record has no status field,
- the accepted decision has its own immutable `<yyyymmdd-hhmm>-<title>.md` file,
- its filename timestamp represents the UTC acceptance time,
- its title makes the filename unique within that UTC minute,
- the `decisions/` directory contains only immutable decision records,
- no previously accepted decision file was modified,
- the resolved question is no longer in `open-questions.md`,
- question IDs have not been reused,
- explanation and consequences do not contradict the decision,
- the question and decision are concise and free of repetition,
- the problem description preserves the meaning and important specifics of the open
  question, including material viewpoints and disagreements,
- affected source documents reflect the decision,
- no stale proposal is still described elsewhere as the selected outcome,
- every potential follow-up was proposed for review,
- only user-confirmed follow-ups were proposed as new open questions.

Report:

1. the accepted decision filename and recorded decision,
2. the documents updated,
3. confirmed follow-up proposals, if any.
