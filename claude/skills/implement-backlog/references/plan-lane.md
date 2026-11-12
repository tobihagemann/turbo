# Implement Backlog: Plan Lane

Run `/plan` with the working-set entries. When `/plan` writes a plan, the user runs `/turbo:implement-plan` in a fresh session afterward.

The working set is the entries the user confirmed in SKILL.md Step 3, or the set that was passed in.

## Task Tracking

Use `TaskCreate` to create a task for each phase:

1. Run `/plan` skill

## Phase 1: Run `/plan` Skill

Run the `/plan` skill with the working set as the task description. Include planning constraints:

- **Synergies** — Group improvements that touch the same files or areas
- **Dependencies** — Order so foundational changes come first
- **Conflicts** — Flag if two improvements contradict each other

`/plan` either writes a plan and halts its own flow, or implements the change in this session.

Then use the TaskList tool and proceed to any remaining task.
