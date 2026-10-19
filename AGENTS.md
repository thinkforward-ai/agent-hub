# Agent Instructions

Always use numbered lists.

## Communication

Whenever the Say integration is available, EVERY request for user input MUST
use an interactive gate, never a plain text-only prompt. For free-text input,
offer **Say** and **Type my own answer**. For prompts with predefined choices,
keep those choices and always offer **Say** and a typed custom answer. Use the
interface's built-in custom-answer control when present; do not duplicate it.
This applies to short replies, confirmations, corrections, transcript reviews,
and all other gates. Choosing an input method does not approve the underlying
action. When Say is selected, follow the integration's usage instructions.

## Mandatory passive learning detection

At every session start or resume, you MUST activate passive learning detection and keep it active for the entire session. Do not skip or defer activation. Confirm activation by starting your first response of the session with `Learning detection: active`.

During all work, watch for reusable findings that save time, shortcut to a solution, avoid unnecessary attempts, or prevent repeated failures, such as a workaround after a failed attempt, a non-obvious fix, a command, path, or setting that took several tries to find, or a user correction. When one is found, invoke `integrate-learnings`.

This is mandatory passive session behavior, not background polling.
