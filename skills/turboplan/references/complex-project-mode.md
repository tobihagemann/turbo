# Turboplan: Complex-Project Mode

Spec out the project and decompose into shell plans, then halt for the user to drive implementation.

## Task Tracking

Use `TaskCreate` to create a task for each phase:

1. Run `/draft-spec` skill
2. Run `/refine-spec` skill
3. Run `/draft-prompt-plan` skill
4. Run `/refine-prompt-plan` skill
5. Halt and tell the user to run `/pick-next-prompt`

## Phase 1: Run `/draft-spec` Skill

Run the `/draft-spec` skill with the user's task description. `/draft-spec` guides the discussion and writes `.turbo/specs/<slug>.md`. Capture the spec path.

## Phase 2: Run `/refine-spec` Skill

Run the `/refine-spec` skill, passing the spec path from Phase 1. This loops review, evaluation, and application until the spec stabilizes or the iteration cap is hit.

## Phase 3: Run `/draft-prompt-plan` Skill

Run the `/draft-prompt-plan` skill, passing the spec path from Phase 1. `/draft-prompt-plan` decomposes the spec into shell plans at `.turbo/plans/<spec-slug>-NN-<title>.md` and writes the index at `.turbo/prompt-plans/<slug>.md`.

## Phase 4: Run `/refine-prompt-plan` Skill

Run the `/refine-prompt-plan` skill, passing the index path from Phase 3. This loops review, evaluation, and application until the prompt plan stabilizes or the iteration cap is hit.

## Phase 5: Halt with Next-Step Instructions

After `/refine-prompt-plan` completes, halt with this message:

> Spec and prompt plan ready.
> - Spec: `<spec path>`
> - Prompt plan index: `<index path>`
> - Shells: `<N>` shell plans in `.turbo/plans/`
>
> To start implementation, run `/pick-next-prompt`. It will pick the first ready shell, hand it to `/turboplan` in shell mode for fill-in, and chain into `/refine-plan` → `/implement-plan` → `/finalize`.

## Rules

- Halt after `/refine-prompt-plan`. Do not attempt to auto-implement shells. The user drives implementation with `/pick-next-prompt`, one session per shell.
