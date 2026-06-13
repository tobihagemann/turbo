# Subagent Wrapping

If you are a subagent invoking `/peer-review`, follow these guardrails. They cover the subagent return contract; the codex run mechanics (timeout, force-background recovery, the `Monitor` ban) live in `/codex-exec`.

## Guardrails

1. **Wait synchronously, in this turn.** Do not return until codex's complete output is in hand, then forward it verbatim. If codex was force-backgrounded, `Read` the output file repeatedly within this same turn until it holds the final result. You are not re-invoked by the completion `<task-notification>` after you return, so you cannot end your turn to wait for it. If you truly cannot finish in-turn, surface the task ID and cause verbatim and request the parent resume you via `SendMessage` once codex completes.
2. **Treat as peer-review failure** (not as a successful empty result): premature return before codex completes, `"Waiting for codex to finish"` text, empty output, partial output (missing dimensions in a multi-dimension fan-out), or a background ID returned in place of findings.
3. **Report the failure cause specifically** (usage limit, timeout, force-background without recovery, error message) when applicable.

## Failure Reporting

`/peer-review` Step 4 specifies an `AskUserQuestion` gate for failure modes. You cannot reach the user. If codex returned partial output, emit Step 4's "Incomplete output" notice verbatim and name what is missing. If codex returned nothing or failed, emit Step 4's "No output / codex failed" notice verbatim. Do not synthesize an empty no-finding peer review.
