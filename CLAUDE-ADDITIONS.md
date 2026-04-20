# CLAUDE.md Additions

Turbo-recommended additions for `~/.claude/CLAUDE.md`. Managed during [setup](SETUP.md) and [`/update-turbo`](UPDATE.md).

Each `##` section below maps to a `#` section in `~/.claude/CLAUDE.md`.

## Skill Loading

- Always use the Skill tool to invoke skills — never substitute by executing steps from memory, even if the skill was loaded earlier in this conversation, including skills invoked by other skills or by themselves
- "Already running" only means don't call a skill *in the same turn* where its `<command-name>` tag already appeared
- Never skip a skill invocation, step, or parallel branch to save context, time, tokens, or iterations — including in auto mode or `/loop`. The harness manages these budgets; the agent does not. Shortcutting a skill removes the value it provides and is always the wrong trade-off.
- Arguments to a child skill are legitimate only when they match its documented interface. Ad-hoc overrides that instruct the child to shortcut its own steps or loop (e.g., "skip the loop", "single-pass only", "just run the one command") are skipping through a different channel.
- Never merge parallel branches. Collapsing N parallel Agent or Skill calls into fewer calls that cover the same work sequentially destroys the context independence and parallelism the skill relies on, even when all criteria are preserved. The branch count a skill specifies is a floor, not a ceiling — "the diff is small" or "the agents would re-read the same files" are not valid reasons to merge.
- After following a skill's instructions to completion, always check your task list for remaining tasks before responding. Child skills may have their own task tracking, and completing all of a child's tasks does not mean the parent workflow is done.
