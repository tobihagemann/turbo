# Resolve Findings: Direct Path

Apply evaluated findings via `$apply-findings`.

## Task Tracking

Use `update_plan` to track each phase:

1. Run `$code-style` skill
2. Run `$apply-findings` skill
3. Close out the change

## Phase 1: Run `$code-style` Skill

Run the `$code-style` skill to load existence, reuse, mirror, and symmetry rules before editing.

## Phase 2: Run `$apply-findings` Skill

Run the `$apply-findings` skill on the evaluated findings.

## Phase 3: Close Out the Change

If no changes were made, skip this phase.

Use `request_user_input` to choose how to close out the change:

- **Full QA** — run the `$finalize` skill
- **Quick close** — run the `$quick-finalize` skill

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.
