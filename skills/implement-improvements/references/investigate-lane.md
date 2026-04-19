# Implement Improvements: Investigate Lane

Diagnose each working-set entry via `/investigate`, then apply the concluded fixes via `/implement`.

The working set is the active entries matching the confirmed lane and category filter, computed in SKILL.md Step 3.

## Task Tracking

Use `TaskCreate` to create a task for each phase:

1. Run `/investigate` skill for each working-set entry
2. Run `/implement` skill for the concluded fixes

## Phase 1: Run `/investigate` Skill for Each Working-Set Entry

Before starting the loop, use `TaskCreate` to add one sub-task per entry in the working set (e.g., `Investigate: <summary>`). Mark each sub-task `in_progress` before the corresponding `/investigate` run and `completed` after.

For each entry in the working set, run the `/investigate` skill. In the problem statement passed to `/investigate`, include the entry's summary and rationale, then append a note that this is an improvement-backlog entry likely to be a symptom and that `/investigate` must run `/consult-codex` regardless of how many hypotheses surface.

If `/investigate` surfaces complexity that exceeds a single-session fix (multi-subsystem change, architectural decision), stop that entry and re-classify it as `standard` (leave it in the backlog for a future run).

## Phase 2: Run `/implement` Skill for the Concluded Fixes

In the turn that invokes `/implement`, write out each investigation's concluded fix as an explicit bullet: summary + files + change description. Being explicit matters here because `/investigate`'s earlier output has likely displaced continuation context, so `/implement` needs a fresh, self-contained description.

Then run the `/implement` skill. `/implement` loads `/code-style`, applies the fixes, and runs `/finalize` to review, test, and commit.

Then use the TaskList tool and proceed to any remaining task.

## Rules

- Run `/finalize` only once (inside `/implement` in Phase 2), not once per investigation.
