# Implement Improvements: Plan Lane

Run `$turboplan` with the working-set entries. The user runs `$implement-plan` in a fresh session afterward.

The working set is the entries the user confirmed in SKILL.md Step 3.

## Task Tracking

Use `update_plan` to track each phase:

1. Run `$turboplan` skill

## Phase 1: Run `$turboplan` Skill

Run the `$turboplan` skill with the working set as the task description. Include planning constraints:

- **Synergies** — Group improvements that touch the same files or areas
- **Dependencies** — Order so foundational changes come first
- **Conflicts** — Flag if two improvements contradict each other

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.
