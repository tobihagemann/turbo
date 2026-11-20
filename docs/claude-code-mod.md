# Claude Code Mod

[← Back to Turbo](../README.md) · [Workflow guide](workflows.md) · [Prompt examples](examples.md) · [Requirements](requirements.md) · [Customization](customization.md)

The Claude Code plugin ships a [mod](https://claude.com/blog/claude-code-mods) alongside its skills. It keeps you informed while a pipeline runs, keeps long pipelines going when the context window fills up, and starts a fresh conversation that continues from a finished plan or a handoff. The Codex edition loads the same rules through a `SessionStart` hook and has none of the rest.

## Open Items

Whenever a turn ends with something only you can decide or do, such as a plan to approve or a sign-in to complete, Claude records it through the `turbo - open-items` tool. Open items are listed in the band above the prompt.

![Claude Code session with two open items and their details listed above the prompt, and Turbo's status line below it](../assets/mod-prompt-area.svg)

The band keeps those items in view after the reply that raised them scrolls away. Click **Resolve** to run [`/turbo:resolve-open-items`](../claude/skills/resolve-open-items/SKILL.md), which walks each item through a question with the recommendation first. From the keyboard, press `ctrl+x tab` to focus the band, then `r`. You can also settle an item in your own words, and Claude resolves it from your reply. A resolved item shows struck through for a moment before it disappears. When an item's wording or choices change before you settle it, Claude updates it in place, keeping its spot in the band.

Each row shows the item's summary, cut to one line. When Claude recorded more about an item, such as a decision's choices, click **Show details** or press `d` in the focused band. Every summary then shows in full, with what Claude recorded under it. **Hide details** folds them away again.

The list survives compaction. `/clear` and `/resume` start it empty. Before a `/clear`, run [`/turbo:handoff`](../claude/skills/handoff/SKILL.md) to carry the items into the handoff.

## Status Line

The line under the prompt shows how much of the context window is left, when the prompt cache expires, and which model and effort level answered the last turn. Once the cache expires, the next turn re-reads the whole conversation at full price, so the countdown tells you when stepping away gets costly. It learns whether your session caches for five minutes or an hour. While Claude works, the countdown drops out.

The same reading also appears above every `AskUserQuestion` dialog, where a skill waits on your answer:

![Claude Code question dialog with Turbo's context, cache, and model reading above it](../assets/mod-dialog-status.svg)

## Context Level

Skills read how much context is left through the `turbo - context-level` tool. [`/refine-plan`](../claude/skills/refine-plan/SKILL.md) and [`/polish-code`](../claude/skills/polish-code/SKILL.md) check it before each decision on another iteration, [`/implement`](../claude/skills/implement/SKILL.md) checks it once before QA, and [`/land-pr`](../claude/skills/land-pr/SKILL.md) before resolving each round of a pull request's feedback. [`/implement-plan`](../claude/skills/implement-plan/SKILL.md) uses it to project whether reading the plan's files fits the window. [`/turbo:context-level`](../claude/skills/context-level/SKILL.md) gives you the same reading on request:

![Claude Code session running /turbo:context-level and reporting how much of the context window remains](../assets/mod-context-level.svg)

## Compaction That Continues

When one of those checks finds context running low, the skill asks whether to write a handoff and compact. When you agree, [`/handoff`](../claude/skills/handoff/SKILL.md) saves the session's state to a file, and the `turbo - compact-and-continue` tool tells the mod to compact once the turn ends. After compacting, the mod sends a prompt that has Claude read the handoff and pick up the next step, so the pipeline continues without you retyping anything:

![Claude Code session queueing a compaction from a handoff, then resuming from a prompt sent by the turbo plugin, with Claude Code's Conversation compacted notice above the prompt](../assets/mod-compaction.svg)

If you ask Claude to compact during a pipeline, its next check takes the same path without asking. If compaction is skipped or fails, a notice asks you to run `/compact` and reply "continue".

## Clearing That Continues

When [`/plan`](../claude/skills/plan/SKILL.md) finishes a plan file, it asks whether to clear the conversation and implement the plan. When you pick either clear option, the `turbo - clear-and-continue` tool tells the mod to run `/clear` once the turn ends, then [`/turbo:implement-plan`](../claude/skills/implement-plan/SKILL.md) on the plan, either in your checkout or in a git worktree of its own:

![Claude Code session where the answer to how to implement a ready plan is a worktree, and the turbo - clear-and-continue tool queues the clear](../assets/mod-clear-and-continue-queued.svg)

The conversation then starts fresh and implements the plan without you typing anything:

![Claude Code session starting fresh after a /clear the turbo plugin ran, then running /turbo:implement-plan on the plan in a worktree and creating that worktree](../assets/mod-clear-and-continue-started.svg)

The question recommends the worktree in a session that [`/implement-backlog`](../claude/skills/implement-backlog/SKILL.md) briefed to work beside others.

Clearing empties the open items list. An item that only needs a settled edit goes into the plan as a final step first, and the question names the rest before you choose. If either command fails, a notice names the commands to run yourself.

The same tool continues from a handoff file. Ask Claude to write a handoff and clear, and the mod runs `/clear` once the turn ends. It then sends a prompt that has the fresh session read the handoff and pick up its next step. Unlike compaction, nothing of the old conversation carries over beyond the handoff itself. If the clear or the prompt fails, a notice names the command to run and the reply to send.

## Rules and Startup Checks

The mod injects [Turbo's rules](../claude/ADDITIONS.md) into every session and into the subagents Claude spawns, so skills load and gates hold the same way everywhere. [Harness Instructions](customization.md#harness-instructions) covers why the rules exist.

At startup the mod also checks your setup and shows a notice for what to fix. Claude passes the notice on to you as well:

- **`CLAUDE_CODE_ENABLE_TODO_TOOLS` not set**: Turbo's step tracking stays off until you [enable the task tracking tools](../claude/SETUP.md#step-4-enable-task-tracking-tools).
- **An earlier copy install is still present**: run `/update-turbo` once to move to the plugin.
