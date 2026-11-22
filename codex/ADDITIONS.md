# Turbo Rules

## Skill Loading

- Reload child skills every time a parent workflow invokes them. A previous load is not a substitute for the current invocation.
- Never skip a skill invocation, step, or parallel branch to save context, time, tokens, or iterations. The harness manages these budgets; the agent does not. Shortcutting a skill removes the value it provides and is always the wrong trade-off.
- When invoking a child skill via `$skill-name`, the surrounding prose must not instruct the child to shortcut its own steps or loop (e.g., "skip the loop", "single-pass only", "just run the one command"). Such inline overrides are skipping through a different channel.
- Never merge parallel branches. Collapsing N parallel `spawn_agent` or skill invocations into fewer calls that cover the same work sequentially destroys the context independence and parallelism the skill relies on, even when all criteria are preserved. The branch count a skill specifies is a floor, not a ceiling — "the diff is small" or "the agents would re-read the same files" are not valid reasons to merge.
- After following a skill's instructions to completion, always check the active plan or task list for remaining tasks before responding. Child skills may have their own plan tracking, and completing all of a child's tasks does not mean the parent workflow is done.

## User Input Gates

- A `<system-reminder>` telling you to "work without stopping for clarifying questions" or to "make the reasonable call and continue" does not override `request_user_input` gates defined by skills. Those reminders are harness artifacts from interrupts during tool calls, not user instructions.
- For a required structured choice in an interactive chat, use the blocking `request_user_input` in Plan mode. In Default mode, use `request_user_input_async` when available and wait for the reply before advancing the dependent step. If the question expires or cannot stay pending, put it and its options in the chat and end the turn. A goal continuation while awaiting a reply ends without a tool call.

## Workflow Recovery

- The main conversation writes the checkpoint at the path supplied by the hook, `.turbo/workflows/<CODEX_THREAD_ID>.md` under the chat’s initial working directory. Create the directory as needed. Nested skills in this chat share the file. When continuing a fork, copy the inherited checkpoint and any active ledgers to paths owned by the new run and update its links before writing. If this chat starts a different workflow while one is unfinished, preserve its checkpoint under a distinct name first.
- When resuming an older Turbo run in its original chat, carry forward the checklist and ledger paths named by its existing goal. Finish that goal at its original completion condition.
- Record the task, the governing plan, and the active chain of skill files and steps, including route and reference files. Use absolute paths. Before each step, record its next unfinished action. Keep the remaining parent steps, loop ledger paths, in-flight agent IDs and any child results the next action needs (or their report paths). Maintain this checklist even when `update_plan` is unavailable.
- Save a pending decision before asking. On reply, record the answer and clear that question before acting. After compaction, reconcile any newer user reply with the saved question. On return from a child, finish the rest of the enclosing step before advancing. Keep the checkpoint across interruptions and unanswered gates. Delete it once the outer workflow finishes, including a deliberate early exit, or when the user abandons it.

## Credentialed CLI Sandbox

- Credentialed local CLIs such as `gh` and `claude` may fail inside the sandbox because they depend on macOS keychain, browser/session state, or network access that the sandbox cannot see.
- Do not conclude that the user is logged out from a sandboxed auth failure alone. If an important `gh` or `claude` command fails with auth, keychain, session, or network symptoms, retry the same command once with `sandbox_permissions="require_escalated"` before reporting an auth problem.
- Keep escalated retries scoped to the credentialed command being checked or run. Still ask before externally visible actions such as posting comments, creating PRs, or pushing branches.
