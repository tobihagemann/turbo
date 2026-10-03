# Turboplan: Plan Mode

Draft → refine → self-improve → settle lesson edits → mark ready → halt to produce a plan file the user implements in a fresh session.

## Task Tracking

Use `TaskCreate` to create a task for each phase:

1. Run `/draft-plan` skill
2. Run `/refine-plan` skill
3. Run `/self-improve` skill
4. Settle lesson edits
5. Mark plan ready
6. Summarize and halt

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

## Phase 6: Summarize and Halt

Present a brief summary of the finished plan: the essence of what it builds and the key decisions behind it, short enough to read at a glance so the user does not have to open the full plan file. When the plan delivers value to a user, developer, or operator, also present a short list of stories capturing what that person gains, in the form "As a <persona>, I want <capability> so that <outcome>". Skip the stories only when no beneficiary or outcome can be named, such as a purely mechanical refactor. Fit both to the plan rather than a fixed template.

Then halt with this message:

> Plan ready at `<plan path>`.
>
> Planning context is likely full, and the plan is comprehensive enough to continue fresh. Run `/clear`, then `/implement-plan <slug>` to implement.

When Phase 1 captured a gated plan, add a line to that message naming its path and the gate that must pass before running `/implement-plan` on it. When Phase 4 left files uncommitted, add a line naming them.

## Rules

- Route revisions through `/refine-plan` or `/draft-plan`.
- Hand implementation to the user via the Phase 6 halt; the user runs `/implement-plan` in a fresh session.
