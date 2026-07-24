# Turboplan: Plan Mode

Draft → refine → self-improve → mark ready → halt to produce a plan file the user implements after an optional `/compact`.

## Task Tracking

Use `update_plan` to track each phase, restating any remaining steps of a parent workflow alongside them:

1. Run `$draft-plan` skill
2. Run `$refine-plan` skill
3. Run `$self-improve` skill
4. Mark plan ready
5. Summarize and halt

## Phase 1: Run `$draft-plan` Skill

Run the `$draft-plan` skill with the input. The input may be a freeform task description, an explicit slug, or a spec path. Capture the resolved plan path from `$draft-plan`'s output for the next phases.

## Phase 2: Run `$refine-plan` Skill

Run the `$refine-plan` skill with `<path>` from Phase 1.

## Phase 3: Run `$self-improve` Skill

Run the `$self-improve` skill to compound planning learnings.

## Phase 4: Mark Plan Ready

Update the plan's YAML frontmatter to `status: ready`.

## Phase 5: Summarize and Halt

Present a brief summary of the finished plan: the essence of what it builds and the key decisions behind it, short enough to read at a glance so the user does not have to open the full plan file. When the plan delivers value to a user, developer, or operator, also present a short list of stories capturing what that person gains, in the form "As a <persona>, I want <capability> so that <outcome>". Skip the stories only when no beneficiary or outcome can be named, such as a purely mechanical refactor. Fit both to the plan rather than a fixed template.

Then halt with this message:

> Plan ready at `<plan path>`.
>
> This is a good point to `/compact` before implementing. Then run `$implement-plan <slug>` to implement.

## Rules

- Route revisions through `$refine-plan` or `$draft-plan`.
- Hand implementation to the user via the Phase 5 halt; the user runs `$implement-plan` after an optional `/compact`.
