# Implement Improvements: Plan Lane

Run `/turboplan` with the working-set entries. When `/turboplan` writes a plan, the user runs `/implement-plan` in a fresh session afterward.

The working set is the entries the user confirmed in SKILL.md Step 3.

## Task Tracking

Use `TaskCreate` to create a task for each phase:

1. Run `/turboplan` skill

## Phase 1: Run `/turboplan` Skill

Run the `/turboplan` skill with the working set as the task description. Include planning constraints:

- **Synergies** — Group improvements that touch the same files or areas
- **Dependencies** — Order so foundational changes come first
- **Conflicts** — Flag if two improvements contradict each other

`/turboplan` either writes a plan and halts its own flow, or implements the change in this session.

Then use the TaskList tool and proceed to any remaining task.
