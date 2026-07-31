---
name: implement
description: "Load code-style and task-specific skills, make the change described by the current context, then run post-implementation QA. Use for ad-hoc changes when no plan file or improvements backlog governs the work, and when the user asks to \"just implement\", \"implement directly\", \"implement without a plan\", or \"apply the change\"."
---

# Implement

Standard implementation flow: load style rules, make the change, run post-implementation QA.

## Task Tracking

At the start, use `update_plan` to track each step, restating any remaining steps of a parent workflow alongside them:

1. Run `$code-style` skill
2. Load task-specific skills
3. Make the change
4. Run verification
5. Run `$preview` skill for UI/UX changes
6. Run `$finalize` skill

Workflow state lives at `.turbo/workflows/<slug>.md` — slug from the governing plan when one is in context, otherwise the current branch name with non-alphanumerics replaced by hyphens. It pairs one-to-one with the thread's goal. When this run's `create_goal` attempt succeeds, write the file fresh: `Status: active` plus this invocation's `update_plan` list as a checkbox list. When an unfinished goal already exists, mirror into the workflow file its objective names; when it names none, continue without workflow state. Mirror every `update_plan` call into the file; it holds the pipeline's remaining steps and their statuses. When this run created the goal, run the terminal step in order: mark the final entry completed and mirror it, set `Status: closed`, mark the goal complete with `update_goal`, then emit any halt message.

Then attempt `create_goal` with the objective: "Make this change: <one-line task summary>. Carry it through Step 6, which runs `$finalize` unless a lighter pass or stopping is chosen. Workflow state: `.turbo/workflows/<slug>.md`; mirror every `update_plan` call into it. Loop state lives under `.turbo/loops/`. After any context compaction, re-read the workflow file and any active ledger, and continue from the first unfinished entry. Mark this goal complete when Step 6 has finished." If an unfinished goal already exists, an outer workflow owns it; continue without creating one.

## Step 1: Run `$code-style` Skill

Run the `$code-style` skill to load existence, reuse, mirror, and symmetry rules before editing.

## Step 2: Load Task-Specific Skills

Scan the work for types that match available skills, matching against the richest context available: a plan's **Implementation Steps** if a plan is in conversation context, otherwise the user request, a prior skill's task description, or an improvement entry. For each unambiguous match, run the skill by reading and following the installed skill instructions. For example, if the work includes "add a Drizzle migration" and a skill exists whose triggers reference Drizzle migrations, load it. If a work type has no matching skill trigger, do not load a generic skill.

If unsure, do not load.

## Step 3: Make the Change

Apply the change described by the current context — the user request, a prior skill's task description, or an improvement entry. Keep the edit scoped to what the context describes. If the scope balloons beyond what the context specified, stop and confirm scope before continuing.

## Step 4: Run Verification

If a Verification section is in conversation context (e.g., from a plan file), execute the commands, smoke checks, or MCP tool invocations it specifies. If a check fails, run the `$investigate` skill. If a check is blocked by a dependency, unclear requirement, or environmental issue, use `request_user_input` to surface the blocker and let the user choose how to proceed. If no Verification section is in context, skip this step.

## Step 5: Run `$preview` Skill for UI/UX Changes

If the change touches a user-facing surface (UI components, styles, templates, markup, user-facing routes or screens), run the `$preview` skill so the user can try it firsthand before QA. When it is unclear whether the change is user-facing, use `request_user_input` to ask whether to preview rather than skipping silently. Skip this step for changes with no user-facing surface (backend-only, CLI, library, build or config).

## Step 6: Run `$finalize` Skill

When a plan file governs the work, hold this step until every Implementation Step has been applied, and continue to the next Implementation Step at every earlier boundary. Then run the `$finalize` skill.

When no plan file governs the work and this run did not create a goal, an outer workflow owns the work: run the `$finalize` skill. When this run created the goal, use `request_user_input` to offer three options:

- **Full QA** — run the `$finalize` skill
- **Lighter pass** — load the `$simplify-code` and `$simplify-docs` skills together, then run both their review agents before applying any fixes
- **Stop here** — leave the change as-is

If this run created a goal, mark it complete with `update_goal`. Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

## Rules

- Defer `git commit`, `git push`, and PR creation to Step 6.
- Don't reference `.turbo/` content (filenames, requirement IDs, shell references, headings) in code or comments. `.turbo/` is gitignored, so these references would be opaque to anyone reading without local copies.
