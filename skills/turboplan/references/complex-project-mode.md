# Turboplan: Complex-Project Mode

Spec out the project and decompose into shell plans, then halt for the user to drive implementation.

## Task Tracking

Use `TaskCreate` to create a task for each phase:

1. Run `/draft-spec` skill
2. Run `/refine-spec` skill
3. Run `/draft-plan-shells` skill
4. Run `/refine-plan-shells` skill
5. Run `/self-improve` skill
6. Halt and tell the user to run `/clear` then `/pick-next-plan-shell`

## Phase 1: Run `/draft-spec` Skill

Run the `/draft-spec` skill with the user's task description. `/draft-spec` guides the discussion and writes `.turbo/specs/<slug>.md`. Capture the spec path.

## Phase 2: Run `/refine-spec` Skill

Run the `/refine-spec` skill, passing the spec path from Phase 1. This loops review, evaluation, and application until the spec stabilizes or the iteration cap is hit.

## Phase 3: Run `/draft-plan-shells` Skill

Run the `/draft-plan-shells` skill, passing the spec path from Phase 1. `/draft-plan-shells` decomposes the spec into shell plans at `.turbo/plans/<spec-slug>-NN-<title>.md` with YAML frontmatter.

## Phase 4: Run `/refine-plan-shells` Skill

Run the `/refine-plan-shells` skill, passing the spec slug from Phase 3. This loops review, evaluation, and application until the shells stabilize or the iteration cap is hit.

## Phase 5: Run `/self-improve` Skill

Run the `/self-improve` skill to compound planning learnings.

## Phase 6: Halt with Next-Step Instructions

Halt with this message:

> Spec and plan shells ready.
> - Spec: `<spec path>`
> - Shells: `<N>` shell plans in `.turbo/plans/`
>
> Planning context is likely full, and the artifacts above are comprehensive enough to continue fresh. Run `/clear`, then `/pick-next-plan-shell` to pick the first draft shell and carry it through planning. After that, run `/implement-plan <slug>` to implement. It will expand the shell with a fresh pattern survey, refine, and chain into `/implement-plan` → `/finalize`.

## Rules

- Phase 5 runs before halting so learnings are captured before the user runs `/clear`.
- Do not attempt to auto-implement shells. The user drives implementation with `/pick-next-plan-shell`, one session per shell.
