# Turboplan: Spec Mode

Spec out the project and decompose into shells, then halt for the user to drive implementation. If the spec turns out to fit a single session, automatically switch to plan mode.

## Task Tracking

Use `TaskCreate` to create a task for each phase:

1. Run `/draft-spec` skill
2. Run `/refine-plan` skill (spec)
3. Run `/draft-shells` skill
4. Run `/refine-plan` skill (shells)
5. Run `/self-improve` skill
6. Summarize and halt

If `/draft-shells` lands on the single-shell bail-out (Phase 3), the flow switches to plan mode by following [plan-mode.md](plan-mode.md). Mark tasks 4-6 deleted via `TaskUpdate`, then create five new tasks for [plan-mode.md](plan-mode.md)'s Phases 1-5 before continuing.

## Phase 1: Run `/draft-spec` Skill

Run the `/draft-spec` skill with the user's task description. `/draft-spec` guides the discussion and writes `.turbo/specs/<slug>.md`. Capture the spec path.

## Phase 2: Run `/refine-plan` Skill (Spec)

Run the `/refine-plan` skill with `spec <path>` from Phase 1.

## Phase 3: Run `/draft-shells` Skill

Run the `/draft-shells` skill, passing the spec path from Phase 1.

After it returns, check `.turbo/shells/<spec-slug>-*.md`:

- **Shells written** — capture the shell paths and continue with Phase 4.
- **No shells written** — `/draft-shells` hit the single-shell bail-out. Switch to plan mode: read [plan-mode.md](plan-mode.md) and follow its phases, passing `<spec path>` from Phase 1 as the Phase 1 input. Phases 4-6 of this file do not run.

## Phase 4: Run `/refine-plan` Skill (Shells)

Run the `/refine-plan` skill with `shells <slug>` from Phase 3.

## Phase 5: Run `/self-improve` Skill

Run the `/self-improve` skill to compound planning learnings.

## Phase 6: Summarize and Halt

Present a brief summary of the finished spec and shell decomposition: the problem, the chosen solution, and how the work splits across shells, short enough to read at a glance so the user does not have to open the full spec. When the project delivers value to a user, developer, or operator, also present a short list of stories capturing what that person gains, in the form "As a <persona>, I want <capability> so that <outcome>". Skip the stories only when no beneficiary or outcome can be named, such as a purely mechanical refactor. Fit both to the artifacts rather than a fixed template.

Then halt with this message:

> Spec and shells ready.
> - Spec: `<spec path>`
> - Shells: `<N>` shells in `.turbo/shells/`
>
> Planning context is likely full, and the artifacts above are comprehensive enough to continue fresh. Run `/clear`, then `/pick-next-shell` to pick the first shell and carry it through expand → refine → self-improve → halt. After that, run `/implement-plan <slug>` in a fresh session to execute the plan and chain into `/finalize`.

## Rules

- Hand shell implementation to the user via the Phase 6 halt; each shell is implemented in its own fresh session via `/implement-plan` after `/pick-next-shell` halts.
- When `/draft-shells` triggers the single-shell bail-out, [plan-mode.md](plan-mode.md)'s phases replace Phases 4-6 here. The spec from Phase 1 and its refinement from Phase 2 already happened and remain the source of truth for the plan.
