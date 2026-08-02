# Turboplan: Direct Mode

Run `$discuss-change`. Direct mode aligns on the shape and implements it; `.turbo/plans/` stays untouched.

## Task Tracking

Use `update_plan` to track each phase, restating any remaining steps of a parent workflow alongside them:

1. Run `$discuss-change` skill

## Phase 1: Run `$discuss-change` Skill

Run the `$discuss-change` skill.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

## Rules

- Direct mode applies the change via `$discuss-change` and leaves `.turbo/plans/` untouched.
