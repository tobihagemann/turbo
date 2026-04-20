# Turboplan: Trivial Mode

Run `/implement`. No plan file is written.

## Task Tracking

Use `TaskCreate` to create a task for each phase:

1. Run `/implement` skill

## Phase 1: Run `/implement` Skill

Run the `/implement` skill.

Then use the TaskList tool and proceed to any remaining task.

## Rules

- Do not write a plan file. Trivial tasks bypass `.turbo/plans/` entirely.
- If the change turns out to exceed a one-line edit (multiple unrelated lines, touches multiple files), stop and re-route through small-task mode.
