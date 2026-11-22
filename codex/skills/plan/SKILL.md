---
name: plan
description: "Universal planning entry: analyze task complexity and route to a direct change or a plan file. Use when the user asks to \"plan this task\", \"plan and implement\", or \"run $turbo:plan\"."
---

# Plan

Analyze task complexity to recommend an execution mode, then let the user set the final route.

Open or continue this chat’s [workflow checkpoint](../../ADDITIONS.md#workflow-recovery).

Categorize the user-supplied task along these dimensions using subjective judgment. This analysis makes the recommendation informed:

- **Scope**: single feature / single subsystem vs multi-feature / multi-subsystem
- **Stakes**: one-off change vs long-lived project with architectural implications
- **Unknowns**: open decisions the user or a code read can answer now vs decisions that need exploration first

Modes are named by what they produce: no plan, or a plan file.

| Mode | Criteria | Route |
|---|---|---|
| **Direct** | Every open decision, scope included, is one the user or a code read can answer in conversation now, however many there are. Aligns on the shape, then implements. | Read [references/direct-mode.md](references/direct-mode.md) and follow its steps. |
| **Plan** | A decision needs a pattern survey, research beyond a quick lookup, or a runtime probe before it can be made, or the work has to survive a fresh session. Produces a plan file, however large the work turns out to be. | Read [references/plan-mode.md](references/plan-mode.md) and follow its steps. |

## Recommend and Confirm the Route

Form a recommended route from the criteria above, reading the dimensions as evidence for them: recommend Plan when any Plan criterion holds, and Direct otherwise. Output the recommendation as text: the recommended mode and a line or two on why it fits over its neighbor.

Then use `request_user_input` to have the user set the final route. Offer the recommended mode first, marked "(Recommended)", alongside the other mode; the auto-appended "Other" lets the user describe a different path.

Add a third **Get a second opinion** option whenever committing to the wrong mode would cost a session of rework, and whenever the recommended mode does not earn "(Recommended)" with conviction. It runs the `$consult-claude` skill for the soundest route given the task's scope, stakes, and unknowns. Then resolve the route with that answer in hand, re-asking when the choice stays the user's.

Record the confirmed route and its reference file in the checkpoint and follow its steps.

## Rules

- Diff size, perceived task simplicity, and context window concerns are not reasons to skip the chosen mode's phases.
