# Turboplan: Small-Task Mode

Draft → refine → confirm → implement for a user-supplied small task.

## Task Tracking

Use `TaskCreate` to create a task for each phase:

1. Run `/draft-plan` skill (full mode)
2. Run `/refine-plan` skill
3. Confirm plan with user
4. Run `/implement-plan` skill (if approved)

## Phase 1: Run `/draft-plan` Skill (Full Mode)

Run the `/draft-plan` skill with the user's task description. This produces a new plan at `.turbo/plans/<slug>.md`. If a slug was passed, forward it. Capture the resolved plan path from `/draft-plan`'s output for the next phases.

## Phase 2: Run `/refine-plan` Skill

Run the `/refine-plan` skill, passing the plan path captured in Phase 1. This loops review, evaluation, and application until the plan stabilizes or the iteration cap is hit.

## Phase 3: Confirm Plan with User

Report the plan's location and summarize it in one paragraph. Point the user at the file path so they can open it for full detail.

Use `AskUserQuestion` to ask how to proceed:

- **Implement now** — Chain into Phase 4
- **Revise more** — Use a follow-up `AskUserQuestion` to choose: run the `/refine-plan` skill again (if review-loop refinement is needed) or the `/draft-plan` skill again (if the shape itself needs rework). After the chosen skill completes, return to Phase 3 and re-run this confirmation gate.
- **Stop** — Leave the plan file in place and end. The user can start a fresh implementation session later.

If the user chooses **Stop**, report the plan path and halt.

## Phase 4: Run `/implement-plan` Skill

Only run this phase if the user approved implementation in Phase 3.

Run the `/implement-plan` skill, passing the plan path. It handles pre-implementation prep, task-specific skill loading, step execution, and `/finalize`.

## Rules

- Phase 1 (draft) and Phase 2 (refine) must both run.
- The `AskUserQuestion` gate in Phase 3 is mandatory. Never chain into implementation without explicit user approval.
- Do not edit the plan file directly in Phase 3 or Phase 4. Revisions go through `/refine-plan` or `/draft-plan`.
- If the user keeps choosing "Revise more" more than twice, surface the pattern and ask whether the task needs to be re-scoped as a complex project.
