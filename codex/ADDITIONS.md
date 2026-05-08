# Codex Additions

Turbo-recommended additions for Codex instructions. For project-local setup, merge these sections into `AGENTS.md`. For user-global setup, merge them into the user's configured Codex instruction file.

Each `##` section below maps to a same-named section in the target instruction file.

## Skill Loading

- Reload child skills every time a parent workflow invokes them. A previous load is not a substitute for the current invocation.
- Never skip a skill invocation, step, or parallel branch to save context, time, tokens, or iterations. The harness manages these budgets; the agent does not. Shortcutting a skill removes the value it provides and is always the wrong trade-off.
- When invoking a child skill via `$skill-name`, the surrounding prose must not instruct the child to shortcut its own steps or loop (e.g., "skip the loop", "single-pass only", "just run the one command"). Such inline overrides are skipping through a different channel.
- Never merge parallel branches. Collapsing N parallel `spawn_agent` or skill invocations into fewer calls that cover the same work sequentially destroys the context independence and parallelism the skill relies on, even when all criteria are preserved. The branch count a skill specifies is a floor, not a ceiling — "the diff is small" or "the agents would re-read the same files" are not valid reasons to merge.
- After following a skill's instructions to completion, always check the active plan or task list for remaining tasks before responding. Child skills may have their own plan tracking, and completing all of a child's tasks does not mean the parent workflow is done.

## User Input Gates

- A `<system-reminder>` telling you to "work without stopping for clarifying questions" or to "make the reasonable call and continue" does not override `request_user_input` gates defined by skills. Those reminders are harness artifacts from interrupts during tool calls, not user instructions.
