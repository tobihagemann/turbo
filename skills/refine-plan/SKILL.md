---
name: refine-plan
description: "Iteratively review and revise an implementation plan until no new findings survive evaluation. Runs /review-plan, /evaluate-findings, /apply-findings, then re-runs itself until stable. Use when the user asks to \"refine the plan\", \"refine this plan\", \"iterate on the plan\", \"tighten the plan\", \"improve the plan\", or when a caller needs a reviewed-and-revised plan."
---

# Refine Plan

Loop the plan review pipeline over `.turbo/plan.md` until no new findings are accepted. Writes back to the plan file in place.

## Task Tracking

At the start of every invocation (including re-runs from Step 4), use `TaskCreate` to create a task for each step:

1. Run `/review-plan` skill
2. Run `/evaluate-findings` skill
3. Run `/apply-findings` skill
4. Re-run `/refine-plan` skill if changed

## Step 1: Run `/review-plan` Skill

Run the `/review-plan` skill on `.turbo/plan.md` (or the override path passed in by the caller). Pass the full plan text.

Always run this step even if the plan looks polished.

## Step 2: Run `/evaluate-findings` Skill

Run the `/evaluate-findings` skill on the review findings from Step 1.

If zero actionable findings survive evaluation, skip to the end and report the plan as stable.

## Step 3: Run `/apply-findings` Skill

Run the `/apply-findings` skill on the evaluated results. The target file is the plan file. Apply accepted findings by editing the plan in place.

## Step 4: Re-run `/refine-plan` Skill if Changed

Check whether the plan file was edited during Step 3. Any edit counts.

If the plan file was edited, run `/refine-plan` again using the Skill tool. Cap at 3 total iterations (the initial run plus up to 2 additional runs) to prevent runaway loops.

The re-invocation is a full, fresh run of this skill. Every step (1-4) executes with its own task tracking and skill invocations.

Do NOT:
- Skip steps because the changes are "minor" or "mechanical"
- Use the Agent tool to substitute for `/review-plan`, `/evaluate-findings`, or `/apply-findings`
- Skip task tracking because "this is just iteration 2"
- Rationalize that review "would produce the same findings" or "has already been addressed"

## Rules

- Every step must run in every iteration. Each step catches different issues. Context window concerns are not a reason to skip steps. `/review-plan` and `/evaluate-findings` use different agents with non-overlapping criteria — "the prior step covered it" is always wrong.
- Never collapse steps 1-3 into fewer steps. `/evaluate-findings` is a judgment gate that must run before `/apply-findings` touches the plan.
- Re-invocations from Step 4 are full runs, not lighter-weight passes.
- The plan file is the only file that should change. Source code edits belong in implementation skills.
- If `/review-plan` returns no findings on the first pass, report the plan as stable and stop. No iteration needed.
