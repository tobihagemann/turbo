# Turboplan: Complex-Project Mode

Spec out the project and decompose into shell plans, then halt for the user to drive implementation.

## Task Tracking

Use `TaskCreate` to create a task for each phase:

1. Run `/create-spec` skill
2. Run `/create-prompt-plan` skill
3. Halt and tell the user to run `/pick-next-prompt`

## Phase 1: Run `/create-spec` Skill

Run the `/create-spec` skill with the user's task description. `/create-spec` guides the discussion and writes `.turbo/specs/<slug>.md`. Capture the spec path.

## Phase 2: Run `/create-prompt-plan` Skill

Run the `/create-prompt-plan` skill, passing the spec path from Phase 1. `/create-prompt-plan` decomposes the spec into shell plans at `.turbo/plans/<spec-slug>-NN-<title>.md` and writes the index at `.turbo/prompt-plans/<slug>.md`.

## Phase 3: Halt with Next-Step Instructions

After `/create-prompt-plan` completes, halt with this message:

> Spec and prompt plan ready.
> - Spec: `<spec path>`
> - Prompt plan index: `<index path>`
> - Shells: `<N>` shell plans in `.turbo/plans/`
>
> To start implementation, run `/pick-next-prompt`. It will pick the first ready shell, hand it to `/turboplan` in shell mode for fill-in, and chain into `/refine-plan` → `/implement-plan` → `/finalize`.

## Rules

- Halt after `/create-prompt-plan`. Do not attempt to auto-implement shells. The user drives implementation with `/pick-next-prompt`, one session per shell.
