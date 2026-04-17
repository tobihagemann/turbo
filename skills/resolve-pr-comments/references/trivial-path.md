# Resolve PR Comments: Trivial Path

Apply evaluated findings directly. `/apply-findings` handles the verdict-aware routing: Escalate prompts, note-for-later captures, and conflict detection.

## Task Tracking

Use `TaskCreate` to create a task for each phase:

1. Run `/code-style` skill
2. Run `/apply-findings` skill
3. Run `/finalize` skill

## Phase 1: Run `/code-style` Skill

Run the `/code-style` skill to load mirror, reuse, and symmetry rules before editing.

## Phase 2: Run `/apply-findings` Skill

Run the `/apply-findings` skill on the evaluated results, including any items reclassified in SKILL.md Step 6.

## Phase 3: Run `/finalize` Skill

If changes were made, run the `/finalize` skill. The commit SHA from finalize is needed for reply messages. If no changes were made, skip to SKILL.md Step 10.

Check your task list for remaining tasks and proceed.
