# Implement Improvements: Direct Lane

Apply the working-set fixes directly via `$implement`.

The working set is the entries the user confirmed in SKILL.md Step 3.

## Task Tracking

Use `update_plan` to track each phase:

1. Run `$implement` skill

## Phase 1: Run `$implement` Skill

In the turn that invokes `$implement`, write out each fix in the working set as an explicit bullet: summary + files + change description. If an entry turns out to need broader scope or deeper analysis during implementation, stop and re-classify it as `investigate` or `plan` (leave it in the backlog for a future run).

Then run the `$implement` skill.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.
