---
name: turboplan
description: "Planning pipeline: draft a plan, refine it through an AI review loop, confirm with the user, then chain into implementation. Produces a plan file at .turbo/plan.md that survives a fresh session. Use when the user asks to \"turboplan\", \"run turboplan\", \"plan this task\", \"turbo plan mode\", \"plan and implement\", \"use turboplan instead of plan mode\", or wants a structured alternative to Claude Code's built-in plan mode."
---

# Turboplan

End-to-end planning pipeline: draft, refine, confirm, implement. Produces `.turbo/plan.md` and optionally chains into implementation in the same session.

Turboplan is Turbo's structured alternative to Claude Code's built-in plan mode, which can feel too restrictive for iterative planning. It runs whether plan mode is active or not, with no requirement to enter or exit it.

## Task Tracking

At the start, use `TaskCreate` to create a task for each phase:

1. Run `/draft-plan` skill
2. Run `/refine-plan` skill
3. Confirm plan with user
4. Run `/implement-plan` skill (if approved)

## Phase 1: Run `/draft-plan` Skill

Run the `/draft-plan` skill with the user's task description. This produces the initial `.turbo/plan.md`.

## Phase 2: Run `/refine-plan` Skill

Run the `/refine-plan` skill on `.turbo/plan.md`. This loops review, evaluation, and application until the plan stabilizes or the iteration cap is hit.

## Phase 3: Confirm Plan with User

Report the plan's location (`.turbo/plan.md`) and summarize it in one paragraph. Point the user at the file path so they can open it for full detail.

Use `AskUserQuestion` to ask how to proceed:

- **Implement now** — Chain into Phase 4
- **Revise more** — Use a follow-up `AskUserQuestion` to choose: run the `/refine-plan` skill again (if review-loop refinement is needed) or the `/draft-plan` skill again (if the shape itself needs rework). After the chosen skill completes, return to Phase 3 and re-run this confirmation gate.
- **Stop** — Leave the plan file in place and end. The user can start a fresh implementation session later using the plan file's Context Files section.

If the user chooses **Stop**, report the plan path and halt.

## Phase 4: Run `/implement-plan` Skill

Only run this phase if the user approved implementation in Phase 3.

Run the `/implement-plan` skill. It handles pre-implementation prep, task-specific skill loading, step execution, and `/finalize`.

## Rules

- Phases 1 and 2 must both run in every invocation. Drafting without refinement skips the review loop. Refinement without drafting has nothing to refine.
- The AskUserQuestion gate in Phase 3 is mandatory. Never chain into implementation without explicit user approval.
- Do not edit the plan file directly in Phase 3 or Phase 4. Revisions go through `/refine-plan` or `/draft-plan`. Implementation edits source code.
- If the user keeps choosing "Revise more" more than twice, surface the pattern and ask whether the task needs to be re-scoped rather than re-refined.
- Diff size, perceived task simplicity, and context window concerns are not reasons to skip Phase 1 or Phase 2.
- For trivial changes (typo fixes, one-line renames), tell the user turboplan is overkill and suggest editing directly.
