# Turboplan: Spec Mode

Spec out the project and decompose into shells, then halt for the user to drive implementation.

## Task Tracking

Use `TaskCreate` to create a task for each phase:

1. Run `/draft-spec` skill
2. Run `/refine-plan` skill (spec)
3. Run `/draft-shells` skill
4. Run `/refine-plan` skill (shells)
5. Run `/self-improve` skill
6. Halt and tell the user to run `/clear` then `/pick-next-shell`

## Phase 1: Run `/draft-spec` Skill

Run the `/draft-spec` skill with the user's task description. `/draft-spec` guides the discussion and writes `.turbo/specs/<slug>.md`. Capture the spec path.

## Phase 2: Run `/refine-plan` Skill (Spec)

Run the `/refine-plan` skill with `spec <path>` from Phase 1. This loops review, evaluation, and application until the spec stabilizes or the iteration cap is hit.

## Phase 3: Run `/draft-shells` Skill

Run the `/draft-shells` skill, passing the spec path from Phase 1. Capture the resulting shell paths.

## Phase 4: Run `/refine-plan` Skill (Shells)

Run the `/refine-plan` skill with `shells <slug>` from Phase 3. This loops review, evaluation, and application until the shells stabilize or the iteration cap is hit.

## Phase 5: Run `/self-improve` Skill

Run the `/self-improve` skill to compound planning learnings.

## Phase 6: Halt with Next-Step Instructions

Halt with this message:

> Spec and shells ready.
> - Spec: `<spec path>`
> - Shells: `<N>` shells in `.turbo/shells/`
>
> Planning context is likely full, and the artifacts above are comprehensive enough to continue fresh. Run `/clear`, then `/pick-next-shell` to pick the first shell and carry it through expand → refine → self-improve → halt. After that, run `/implement-plan <slug>` in a fresh session to execute the plan and chain into `/finalize`.

## Rules

- Hand shell implementation to the user via the Phase 6 halt; each shell is implemented in its own fresh session via `/implement-plan` after `/pick-next-shell` halts.
