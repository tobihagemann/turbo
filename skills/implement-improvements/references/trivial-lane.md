# Implement Improvements: Trivial Lane

Apply the working-set fixes directly via `/implement`.

The working set is the active entries matching the confirmed lane and category filter, computed in SKILL.md Step 3.

## Task Tracking

Use `TaskCreate` to create a task for each phase:

1. Run `/implement` skill

## Phase 1: Run `/implement` Skill

In the turn that invokes `/implement`, write out each fix in the working set as an explicit bullet: summary + files + change description. If an entry turns out to need broader scope or deeper analysis during implementation, stop and re-classify it as `investigate` or `standard` (leave it in the backlog for a future run).

Then run the `/implement` skill.

Then use the TaskList tool and proceed to any remaining task.
