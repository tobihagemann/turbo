---
name: turboplan
description: "Analyze task complexity and route to a mode by artifact: direct fix for clear-scope changes, plan file when the approach needs to be written down, or spec and shells for multi-session projects. Use when the user asks to \"turboplan\", \"run turboplan\", \"plan this task\", \"turbo plan mode\", \"plan and implement\", or \"use turboplan instead of plan mode\"."
---

# Turboplan

Analyze task complexity to recommend an execution mode, then let the user set the final route.

Categorize the user-supplied task along these dimensions using subjective judgment. This analysis makes the recommendation informed:

- **Scope**: single feature / single subsystem vs multi-feature / multi-subsystem
- **Stakes**: one-off change vs long-lived project with architectural implications
- **Unknowns**: clear approach vs needs exploration and product decisions

Modes are named by what they produce: no plan, a plan file, or a spec plus shells.

| Mode | Criteria | Route |
|---|---|---|
| **Direct** | Clear scope, with any remaining decisions small enough to settle in conversation rather than write down. Aligns on the shape, then implements. | Read [references/direct-mode.md](references/direct-mode.md) and follow its steps. |
| **Plan** | The approach warrants writing down before implementing — to survey patterns or survive a fresh session. Fits a single implementation session and touches one or two related subsystems. Produces a plan file. | Read [references/plan-mode.md](references/plan-mode.md) and follow its steps. |
| **Spec** | Spans multiple subsystems, requires multiple implementation sessions, or has architectural decisions that need a spec-level discussion before planning begins. Produces a spec plus shells. | Read [references/spec-mode.md](references/spec-mode.md) and follow its steps. |

## Recommend and Confirm the Route

Form a recommended route from the dimensions and criteria above. Output the recommendation as text: the recommended mode and a line or two on why it fits over its neighbors.

Then use `request_user_input` to have the user set the final route. Offer the recommended mode first, marked "(Recommended)", alongside the other two modes; the auto-appended "Other" lets the user describe a different path.

Workflow state lives at `.turbo/workflows/<slug>.md` — slug from the task summary (lowercased, non-alphanumerics to hyphens, truncated to 40 characters at a word boundary). It pairs one-to-one with the thread's goal. When this run's `create_goal` attempt succeeds, write the file fresh: `Status: active` plus the confirmed route's step list from its reference file as a checkbox list. When an unfinished goal already exists, mirror into the workflow file its objective names; when it names none, continue without workflow state. Mirror every `update_plan` call into the file; it holds the pipeline's remaining steps and their statuses. When this run created the goal, run the terminal step in order: mark the final entry completed and mirror it, set `Status: closed`, mark the goal complete with `update_goal`, then emit any halt message.

Attempt `create_goal` with the objective: "Carry the task '<task summary>' through the confirmed <route> route's final step; for plan and spec routes that is the route's designed summarize-and-halt, and if the route re-routes, the new route's final step applies. Workflow state: `.turbo/workflows/<slug>.md`; mirror every `update_plan` call into it. Loop state lives under `.turbo/loops/`. After any context compaction, re-read the workflow file and any active ledger, and continue from the first unfinished entry. Mark this goal complete at the route's final step, before any designed halt message." If an unfinished goal already exists, an outer workflow owns it; continue without creating one.

Carry the confirmed route into its reference file from the table above and follow its steps. If this run created the goal, resolve it inside the route's own flow rather than after it: mark it complete with `update_goal` when the route's final step is reached, before emitting any designed halt message.

## Rules

- Diff size, perceived task simplicity, and context window concerns are not reasons to skip the chosen mode's phases.
