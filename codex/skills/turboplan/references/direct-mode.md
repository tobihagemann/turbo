# Turboplan: Direct Mode

Run `$implement`. Direct mode goes straight to implementation; `.turbo/plans/` stays untouched.

## Task Tracking

Use `update_plan` to track each phase, restating any remaining steps of a parent workflow alongside them:

1. Run `$implement` skill

## Phase 1: Run `$implement` Skill

Run the `$implement` skill.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

## Rules

- Direct mode applies the change via `$implement` and leaves `.turbo/plans/` untouched.
- If the work turns out to need writing down — unclear scope surfaces, the approach needs surveying first, or context risks being lost across sessions — stop and re-route through plan mode.
