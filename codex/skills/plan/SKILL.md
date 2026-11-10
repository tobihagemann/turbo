---
name: plan
description: "Universal planning entry: analyze task complexity and route to a direct change or a plan file. Use when the user asks to \"plan this task\", \"plan and implement\", or \"run $turbo:plan\"."
---

# Plan

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

Then use `request_user_input` to have the user set the final route. Offer the recommended mode first, marked "(Recommended)", alongside the other mode; the auto-appended "Other" lets the user describe a different path.

Add a third **Get a second opinion** option whenever committing to the wrong mode would cost a session of rework, and whenever the recommended mode does not earn "(Recommended)" with conviction. It runs the `$consult-claude` skill for the soundest route given the task's scope, stakes, and unknowns. Then resolve the route with that answer in hand, re-asking when the choice stays the user's.

Workflow state lives in a file under `.turbo/workflows/` that pairs one-to-one with the thread's goal. When no unfinished goal exists, mint its path once as `.turbo/workflows/<label>-<tag>.md`. The label is the task summary, lowercased, with non-alphanumerics replaced by hyphens and truncated to 40 characters at a word boundary. The tag is the output of `head -c 4 /dev/urandom | xxd -p`. Only when this run's `create_goal` attempt succeeds, write the file with the confirmed route's step list from its reference file as a checkbox list. When an unfinished goal already exists, mint nothing and mirror into the workflow file its objective names; when it names none, continue without workflow state. Mirror every `update_plan` call into the file; it holds the pipeline's remaining steps and their statuses. When this run created the goal, run the terminal step in order: mark the final entry completed, mark the goal complete with `update_goal`, delete the workflow file, then emit any halt message.

Attempt `create_goal` with the objective, filling in the minted path: "Carry the task '<task summary>' through the confirmed <route> route's final step; for the plan route that is the route's designed summarize-and-halt, and if the confirmed route changes, the new route's final step applies. Workflow state: <workflow path>; mirror every `update_plan` call into it. Loop state lives under `.turbo/loops/`. After any context compaction, re-read the workflow file and every ledger it registers, and continue from the first unfinished entry. Mark this goal complete at the route's final step, before any designed halt message." If an unfinished goal already exists, an outer workflow owns it; continue without creating one.

Carry the confirmed route into its reference file from the table above and follow its steps. If this run created the goal, resolve it inside the route's own flow rather than after it: when the route's final step is reached, mark it complete with `update_goal` and delete the workflow file, before emitting any designed halt message.

## Rules

- Diff size, perceived task simplicity, and context window concerns are not reasons to skip the chosen mode's phases.
