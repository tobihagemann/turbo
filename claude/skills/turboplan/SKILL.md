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

Then use `AskUserQuestion` to have the user set the final route. Offer the recommended mode first, marked "(Recommended)", alongside the other two modes; the auto-appended "Other" lets the user describe a different path.

Add a fourth **Get a second opinion** option whenever committing to the wrong mode would cost a session of rework, and whenever the recommended mode does not earn "(Recommended)" with conviction. It runs the `/consult-codex` skill for the soundest route given the task's scope, stakes, and unknowns. Then resolve the route with that answer in hand, re-asking when the choice stays the user's.

Carry the confirmed route into its reference file from the table above and follow its steps.

## Rules

- Diff size, perceived task simplicity, and context window concerns are not reasons to skip the chosen mode's phases.
