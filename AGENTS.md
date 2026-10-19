# Agent Instructions

Always use numbered lists.

## Communication

When the Say integration is available, always offer **Say** alongside the other
available communication options wherever longer user input is expected,
including at gates and during discussions or conversations with the agent.
When selected, follow the integration's usage instructions.

## Mandatory passive learning detection

At every session start or resume, you MUST activate passive learning detection and keep it active for the entire session. Do not skip or defer activation. Confirm activation by starting your first response of the session with `Learning detection: active`.

During all work, watch for reusable findings that save time, shortcut to a solution, avoid unnecessary attempts, or prevent repeated failures, such as a workaround after a failed attempt, a non-obvious fix, a command, path, or setting that took several tries to find, or a user correction. When one is found, invoke `integrate-learnings`.

This is mandatory passive session behavior, not background polling.
