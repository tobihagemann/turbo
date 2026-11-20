# Plan: Plan Mode

Draft → refine → self-improve → settle lesson edits → mark ready → offer to implement the plan file in a fresh conversation.

## Task Tracking

Use `TaskCreate` to create a task for each phase:

1. Run `/draft-plan` skill
2. Run `/refine-plan` skill
3. Run `/self-improve` skill
4. Settle lesson edits
5. Mark plan ready
6. Summarize and offer implementation

## Phase 1: Run `/draft-plan` Skill

Run the `/draft-plan` skill with the input. The input may be a freeform task description, an explicit slug, or a path to a background document. Capture the resolved plan path from `/draft-plan`'s output for the next phases, and the path of any gated plan it also wrote. When it wrote one, use `TaskUpdate` to name both paths in the Phase 2 task's description.

## Phase 2: Run `/refine-plan` Skill

Run the `/refine-plan` skill with `<path>` from Phase 1. When Phase 1 captured a gated plan, run the `/refine-plan` skill again with that path once the first run finishes.

## Phase 3: Run `/self-improve` Skill

Run the `/self-improve` skill to compound planning learnings.

## Phase 4: Settle Lesson Edits

**Skip** this phase when every file Phase 3 created or changed lies outside this repository or is ignored by git.

Otherwise output as text that `/self-improve` left the remaining files changed and uncommitted, with their paths. Then use `AskUserQuestion` to ask what to do with them before the plan is implemented:

- **Commit and push** — run the `/stage-commit-push` skill for the changes Phase 3 made to those files
- **Commit only** — run the `/stage-commit` skill for the changes Phase 3 made to those files
- **Leave uncommitted** — keep them as they are

## Phase 5: Mark Plan Ready

Update the YAML frontmatter of each plan from Phase 1 to `status: ready`.

## Phase 6: Summarize and Offer Implementation

Use the TaskList tool. When it shows pending tasks besides this phase, complete each of them, then continue with this phase's summary.

Present a brief summary of the finished plan: the essence of what it builds and the key decisions behind it, short enough to read at a glance so the user does not have to open the full plan file. When the plan delivers value to a user, developer, or operator, also present a short list of stories capturing what that person gains, in the form "As a <persona>, I want <capability> so that <outcome>". Skip the stories only when no beneficiary or outcome can be named, such as a purely mechanical refactor. Fit both to the plan rather than a fixed template.

Output "Plan ready at `<plan path>`." as text. When Phase 1 captured a gated plan, add a line naming its path and the gate that must pass before running `/turbo:implement-plan` on it. When Phase 4 left files uncommitted, add a line naming them.

Call the `mcp__turbo__open-items` tool with `action` set to `list`. For each open item whose edit and target file are already settled, with no decision or action left to the user, add that edit to the plan named in the "Plan ready" line as a final implementation step, naming the file it lands in, then `resolve` the item. Then use `AskUserQuestion` to ask how to implement the plan in a fresh conversation. Name each item carried into the plan, and the step it became, in the question. When the list still shows open items, name them in the question and say that clearing empties the list.

- **Clear and implement** — clears this conversation, then runs `/turbo:implement-plan` on the plan in this checkout
- **Implement in worktree** — clears this conversation, then runs `/turbo:implement-plan` on the plan in a git worktree of its own, leaving this checkout to other sessions. When Phase 4 left files uncommitted, add that the worktree starts without them.
- **Stop here** — keeps this conversation; run `/clear`, then `/turbo:implement-plan <slug>` when ready

Mark **Implement in worktree** recommended when an instruction addressed to this session says to implement the plan in a worktree of its own, and **Clear and implement** recommended otherwise.

On either clear option, call the `mcp__turbo__clear-and-continue` tool with the slug of the plan named in the "Plan ready" line as `plan`, and `worktree` set to true for the worktree option. The fallback commands are `/clear`, then `/turbo:implement-plan <slug>`, with "in a worktree" added for the worktree option. When the tool confirms the clear is queued, tell the user that the session clears and starts implementing once this turn ends. Name the fallback commands for the case that it does not. When the tool refuses, tell the user to run the fallback commands themselves.

On **Stop here**, tell the user to run `/clear`, then `/turbo:implement-plan <slug>` to implement.

Then use the TaskList tool and proceed to any remaining task.

## Rules

- Route revisions through `/refine-plan` or `/draft-plan`.
- Leave implementation to a fresh conversation through the Phase 6 question.
