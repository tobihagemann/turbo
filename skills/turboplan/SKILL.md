---
name: turboplan
description: "Universal entry point for planning. Analyzes task complexity and routes: small tasks run draft → refine → confirm → implement; complex tasks go to /create-spec + /create-prompt-plan; shells handed in from /pick-next-prompt go straight to fill-in. Produces a plan file at .turbo/plans/<slug>.md. Use when the user asks to \"turboplan\", \"run turboplan\", \"plan this task\", \"turbo plan mode\", \"plan and implement\", \"use turboplan instead of plan mode\", or wants a structured alternative to Claude Code's built-in plan mode."
---

# Turboplan

Universal planning entry point. Turboplan analyzes what the user is trying to do and routes through the right pipeline: a single plan for small tasks, a spec + prompt plan decomposition for complex projects, or a direct fill-in for shells picked up by `/pick-next-prompt`.

Turboplan is Turbo's structured alternative to Claude Code's built-in plan mode, which can feel too restrictive for iterative planning. It runs whether plan mode is active or not, with no requirement to enter or exit it.

## Mode Selection

Turboplan has three modes plus an early-exit:

- **Shell mode**: When the caller (typically `/pick-next-prompt`) passes a shell file path, skip Step 1 and route directly to fill-in.
- **Small-task mode**: Default for a user-supplied task description that Step 1's analysis judges as a single-session change.
- **Complex-project mode**: Step 1's analysis judges the task as multi-subsystem. Routes to `/create-spec` and `/create-prompt-plan`, then halts.
- **Trivial early-exit**: For true one-line edits, Step 1 tells the user turboplan is overkill and suggests editing directly without entering any of the three modes.

## Step 1: Analyze Task Complexity (User-Supplied Tasks Only)

**Skip this step entirely in shell mode.** Shells come from a prompt plan that was already analyzed at create time. Jump straight to the "Shell Mode" section below.

For a user-supplied task description, read it and categorize along these dimensions. Use subjective judgment, no heuristics. This mirrors `/finalize` Phase 4 Step 1's approach.

- **Scope**: single feature / single subsystem vs multi-feature / multi-subsystem
- **Stakes**: one-off change vs long-lived project with architectural implications
- **Unknowns**: clear approach vs needs exploration and product decisions

A task is **small** when it fits a single implementation session, touches one or two related subsystems, and has no major architectural decisions left to make.

A task is **complex** when it spans multiple subsystems, requires multiple implementation sessions, or has architectural decisions that need a spec-level discussion before planning begins.

A task is **trivial** when it is a true one-line edit (typo fix, single rename, single config tweak) where opening turboplan adds no value.

Output the analysis as text. For borderline cases, use `AskUserQuestion` to confirm:

- **Small, run draft/refine/implement**: Continue in Small-Task Mode
- **Complex, run spec + prompt plan**: Continue in Complex-Project Mode
- **Trivial, skip turboplan**: Tell the user turboplan is overkill and suggest editing directly. Halt without entering any of the three modes.

If the task is clearly small, complex, or trivial, skip the confirmation and proceed directly. Record the chosen route.

## Small-Task Mode

For a user-supplied task description judged as a small task in Step 1.

### Task Tracking

Use `TaskCreate` to create a task for each phase:

1. Run `/draft-plan` skill (full mode)
2. Run `/refine-plan` skill
3. Confirm plan with user
4. Run `/implement-plan` skill (if approved)

### Phase 1: Run `/draft-plan` Skill (Full Mode)

Run the `/draft-plan` skill with the user's task description. This produces a new plan at `.turbo/plans/<slug>.md`. If the caller passed a slug, forward it. Capture the resolved plan path from `/draft-plan`'s output for the next phases.

### Phase 2: Run `/refine-plan` Skill

Run the `/refine-plan` skill, passing the plan path captured in Phase 1. This loops review, evaluation, and application until the plan stabilizes or the iteration cap is hit.

### Phase 3: Confirm Plan with User

Report the plan's location and summarize it in one paragraph. Point the user at the file path so they can open it for full detail.

Use `AskUserQuestion` to ask how to proceed:

- **Implement now** — Chain into Phase 4
- **Revise more** — Use a follow-up `AskUserQuestion` to choose: run the `/refine-plan` skill again (if review-loop refinement is needed) or the `/draft-plan` skill again (if the shape itself needs rework). After the chosen skill completes, return to Phase 3 and re-run this confirmation gate.
- **Stop** — Leave the plan file in place and end. The user can start a fresh implementation session later.

If the user chooses **Stop**, report the plan path and halt.

### Phase 4: Run `/implement-plan` Skill

Only run this phase if the user approved implementation in Phase 3.

Run the `/implement-plan` skill, passing the plan path. It handles pre-implementation prep, task-specific skill loading, step execution, and `/finalize`.

## Shell Mode

For a shell file path passed in by a caller (typically `/pick-next-prompt`). Step 1 is skipped because the complexity analysis already happened at `/create-prompt-plan` time.

### Task Tracking

Use `TaskCreate` to create a task for each phase:

1. Run `/draft-plan` skill (fill-in mode)
2. Run `/refine-plan` skill
3. Confirm plan with user
4. Run `/implement-plan` skill (if approved)

### Phase 1: Run `/draft-plan` Skill (Fill-In Mode)

Run the `/draft-plan` skill with the shell file path as input. `/draft-plan` detects the shell and runs in fill-in mode: it reads the shell, verifies Consumes against the current codebase, refreshes the pattern survey, escalates the shell's Open Questions, runs parallel internal+peer fill-in, and writes the completed plan back to the shell path. The plan path equals the shell path.

### Phase 2: Run `/refine-plan` Skill

Run the `/refine-plan` skill, passing the filled-in plan path. Loops until the plan stabilizes.

### Phase 3: Confirm Plan with User

Same as Small-Task Mode Phase 3. AskUserQuestion with Implement / Revise / Stop options.

### Phase 4: Run `/implement-plan` Skill

Only run if approved in Phase 3. Run the `/implement-plan` skill, passing the plan path. The plan's final implementation step should mark the corresponding prompt `done` in the prompt plan index (this instruction is added by `/pick-next-prompt` when it calls this skill).

## Complex-Project Mode

For a user-supplied task description judged as complex in Step 1.

### Task Tracking

Use `TaskCreate` to create a task for each phase:

1. Run `/create-spec` skill
2. Run `/create-prompt-plan` skill
3. Halt and tell the user to run `/pick-next-prompt`

### Phase 1: Run `/create-spec` Skill

Run the `/create-spec` skill with the user's task description. `/create-spec` guides the discussion and writes `.turbo/specs/<slug>.md`. Capture the spec path.

### Phase 2: Run `/create-prompt-plan` Skill

Run the `/create-prompt-plan` skill, passing the spec path from Phase 1. `/create-prompt-plan` decomposes the spec into shell plans at `.turbo/plans/<spec-slug>-NN-<title>.md` and writes the index at `.turbo/prompt-plans/<slug>.md`.

### Phase 3: Halt with Next-Step Instructions

After `/create-prompt-plan` completes, halt with this message:

> Spec and prompt plan ready.
> - Spec: `<spec path>`
> - Prompt plan index: `<index path>`
> - Shells: `<N>` shell plans in `.turbo/plans/`
>
> To start implementation, run `/pick-next-prompt`. It will pick the first ready shell, hand it to `/turboplan` in shell mode for fill-in, and chain into `/refine-plan` → `/implement-plan` → `/finalize`.

Do not attempt to auto-implement shells. Each implementation session runs in isolation so every prompt gets fresh codebase context at fill-in time.

## Rules

- Step 1 (complexity analysis) runs for every user-supplied task description. Shell mode skips it because the analysis already happened at `/create-prompt-plan` time.
- In Small-Task and Shell modes, the draft (Phase 1) and refine (Phase 2) phases must both run. Drafting without refinement skips the review loop. Refinement without drafting has nothing to refine.
- The AskUserQuestion gate in Phase 3 (Small-Task and Shell modes) is mandatory. Never chain into implementation without explicit user approval.
- Complex-Project Mode halts after `/create-prompt-plan`. Do not attempt to auto-implement shells. The user drives implementation with `/pick-next-prompt`, one session per shell.
- Do not edit the plan file directly in Phase 3 or Phase 4. Revisions go through `/refine-plan` or `/draft-plan`. Implementation edits source code.
- If the user keeps choosing "Revise more" more than twice, surface the pattern and ask whether the task needs to be re-scoped (possibly re-routed as Complex-Project Mode) rather than re-refined.
- Diff size, perceived task simplicity, and context window concerns are not reasons to skip any phase.
- For true one-line edits, tell the user turboplan is overkill and suggest editing directly. This check happens in Step 1 for user-supplied tasks; shells bypass it because they were already judged worth a session at `/create-prompt-plan` time.
