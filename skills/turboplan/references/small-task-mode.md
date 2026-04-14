# Turboplan: Small-Task Mode

Draft → refine → self-improve → halt for a user-supplied small task.

## Task Tracking

Use `TaskCreate` to create a task for each phase:

1. Run `/draft-plan` skill
2. Run `/refine-plan` skill
3. Run `/self-improve` skill
4. Halt with next-step instructions

## Phase 1: Run `/draft-plan` Skill

Run the `/draft-plan` skill with the user's task description. This produces a new plan at `.turbo/plans/<slug>.md`. If a slug was passed, forward it. Capture the resolved plan path from `/draft-plan`'s output for the next phases.

## Phase 2: Run `/refine-plan` Skill

Run the `/refine-plan` skill with `<path>` from Phase 1. This loops review, evaluation, and application until the plan stabilizes or the iteration cap is hit.

## Phase 3: Run `/self-improve` Skill

Run the `/self-improve` skill to compound planning learnings.

## Phase 4: Halt with Next-Step Instructions

Update the plan's YAML frontmatter to `status: ready`.

Halt with this message:

> Plan ready at `<plan path>`.
>
> Planning context is likely full, and the plan is comprehensive enough to continue fresh. Run `/clear`, then `/implement-plan <slug>` to implement.

## Rules

- Phases 1, 2, and 3 always run.
- Do not edit the plan file directly. Revisions go through `/refine-plan` or `/draft-plan`.
- Do not attempt to auto-implement. The user drives implementation with `/implement-plan` in a fresh session.
