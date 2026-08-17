---
name: turboplan
description: "Analyze task complexity and route to a mode by artifact: direct fix for clear-scope changes, or a plan file when the approach needs to be written down. Use when the user asks to \"turboplan\", \"run turboplan\", \"plan this task\", \"turbo plan mode\", \"plan and implement\", or \"use turboplan instead of plan mode\"."
---

# Turboplan

Analyze task complexity to recommend an execution mode, then let the user set the final route.

Categorize the user-supplied task along these dimensions using subjective judgment. This analysis makes the recommendation informed:

- **Scope**: single feature / single subsystem vs multi-feature / multi-subsystem
- **Stakes**: one-off change vs long-lived project with architectural implications
- **Unknowns**: clear approach vs needs exploration and product decisions

Modes are named by what they produce: no plan, or a plan file.

| Mode | Criteria | Route |
|---|---|---|
| **Direct** | Clear scope, with any remaining decisions small enough to settle in conversation rather than write down. Aligns on the shape, then implements. | Read [references/direct-mode.md](references/direct-mode.md) and follow its steps. |
| **Plan** | The approach warrants writing down before implementing — to survey patterns, settle architectural decisions, or survive a fresh session. Produces a plan file, however large the work turns out to be. | Read [references/plan-mode.md](references/plan-mode.md) and follow its steps. |

## Recommend and Confirm the Route

Form a recommended route from the dimensions and criteria above. Output the recommendation as text: the recommended mode and a line or two on why it fits over its neighbor.

Then use `AskUserQuestion` to have the user set the final route. Offer the recommended mode first, marked "(Recommended)", alongside the other mode; the auto-appended "Other" lets the user describe a different path.

Add a third **Get a second opinion** option whenever committing to the wrong mode would cost a session of rework, and whenever the recommended mode does not earn "(Recommended)" with conviction. It runs the `/consult-codex` skill for the soundest route given the task's scope, stakes, and unknowns. Then resolve the route with that answer in hand, re-asking when the choice stays the user's.

Carry the confirmed route into its reference file from the table above and follow its steps.

## Rules

- Diff size, perceived task simplicity, and context window concerns are not reasons to skip the chosen mode's phases.
