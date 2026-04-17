# CLAUDE.md Additions

Turbo-recommended additions for `~/.claude/CLAUDE.md`. Managed during [setup](SETUP.md) and [`/update-turbo`](UPDATE.md).

Each `##` section below maps to a `#` section in `~/.claude/CLAUDE.md`.

## Skill Loading

- Always use the Skill tool to invoke skills — never substitute by executing steps from memory, even if the skill was loaded earlier in this conversation, including skills invoked by other skills or by themselves
- "Already running" only means don't call a skill *in the same turn* where its `<command-name>` tag already appeared
- Never skip a skill invocation, step, or parallel branch to save context, time, tokens, or iterations — including in auto mode or `/loop`, and including indirectly by passing arguments that instruct a child skill to skip its own steps or shortcut its loop (e.g., "skip the loop", "single-pass only", "just run the one command"). An argument is legitimate only when it matches the child skill's documented interface; ad-hoc overrides of the child's steps count as bypasses. The harness manages these budgets; the agent does not. Shortcutting a skill removes the value it provides and is always the wrong trade-off.
- After following a skill's instructions to completion, always check your task list for remaining tasks before responding. Child skills may have their own task tracking, and completing all of a child's tasks does not mean the parent workflow is done.
