---
name: refine-plan
description: "Iteratively review and revise a plan until no new findings survive evaluation. Use when the user asks to \"refine the plan\", \"iterate on the plan\", \"tighten the plan\", or \"improve the plan\"."
---

# Refine Plan

Loop the review pipeline over a plan until no new findings are accepted. Writes back to the plan file in place.

## Task Tracking

At the start of every invocation (including re-runs from Step 5), use `TaskCreate` to create a task for each step:

1. Resolve the plan
2. Run `/review-plan` skill
3. Run `/evaluate-findings` skill
4. Run `/apply-findings` skill
5. Re-run `/refine-plan` skill if changed

## Step 1: Resolve the Plan

1. **Explicit path** — use it
2. **Explicit slug** — resolve to `.turbo/plans/<slug>.md`
3. **Single file** — Glob `.turbo/plans/*.md`. If exactly one file exists, use it
4. **Most recent** — most recently modified file
5. **Legacy fallback** — `.turbo/plan.md` if `.turbo/plans/` does not exist
6. **Nothing found** — tell the user to run `/turboplan` and stop

If multiple candidates exist and the choice is non-obvious, use `AskUserQuestion`.

State the resolved path before continuing.

Unless an explicit path or slug was passed, confirm the resolved plan still describes work that remains to be done. The signal is a frontmatter `status:` of `done`.

When the signal fires, output it as text. Then use `AskUserQuestion` to offer:

- **Refine anyway** — the marker is stale
- **Pick another plan** — resolve to a different file under `.turbo/plans/`, then confirm that plan against this same signal
- **Leave the plan alone** — skip refining

On **Leave the plan alone**, mark the remaining refine steps deleted, then use the TaskList tool and proceed to any remaining task.

## Step 2: Run `/review-plan` Skill

Run the `/review-plan` skill on the resolved plan.

Always run this step even if the plan looks polished.

## Step 3: Run `/evaluate-findings` Skill

Run the `/evaluate-findings` skill on the review findings from Step 2.

## Step 4: Run `/apply-findings` Skill

Run the `/apply-findings` skill on the evaluated results.

## Step 5: Re-run `/refine-plan` Skill if Changed

Check whether the plan file was edited during Step 4. Any edit counts.

The iteration number below refers to the `/refine-plan` run currently executing Step 5. It is not the iteration number of a prospective re-run. Iteration 1 is the initial run; iteration 2 is the first auto-re-run; iteration 3 is the second auto-re-run; iteration 4 and beyond exist only when the user opts in at the hard-cap ask. Iterations 1 and 2 always follow the classification gate (they never trigger the hard cap at their own Step 5, even when the auto-re-run they spawn would be iteration 3). The hard cap fires at the end of iteration 3 and every iteration thereafter.

**Iterations 1 and 2, if changes were made**, classify what Step 4 edited:

- **Structural edits** — run `/refine-plan` again via the Skill tool, passing the resolved path. If the round contains both structural and prose-only edits, treat it as structural and re-run automatically.
- **Prose-only edits only** (reworded sentences in place, fixed stale examples, clarified existing text without changing meaning) — output a summary of what changed, then use `AskUserQuestion` to ask whether to run one more round or stop here. Do not silently continue or silently stop.

**Iterations 1 and 2, if changes were made but you believe re-running is unnecessary**, use `AskUserQuestion` to ask for skip permission. Do not skip silently.

Judge whether another round is worthwhile by the trend across iterations: when rounds have stopped surfacing defects (contradictions, infeasible steps, missing requirements) and keep surfacing improvements of kinds earlier rounds already applied, the loop has converged even though the edits were structural — recommend stopping. A round that surfaces no defects is the termination signal; never add a confirmation round, an extra reviewer, or review steps beyond this skill's own.

Judge the kind of surviving defect as well as the trend. Once earlier rounds have drained the design- and requirement-level defects and a round's findings are dominated by claims that a named identifier does not exist or does not match its declaration, the plan has passed the point where reviewing it as text pays, even when the count is rising and every finding is genuine. Implementation surfaces that class immediately, so recommend stopping. Expect any round that adds mechanism to seed defects at the seams it creates.

When a round's findings turn on how a platform, framework, or dependency behaves and nobody has observed that behavior, prefer a cheap instrumented experiment to another review round. Run it in a temp directory outside the repo, and record what it shows in the plan before judging whether another round is warranted.

**Iteration 3 or later, if Step 4 of this run made changes**, the hard cap is reached. This replaces the classification gate above for iteration 3 and every iteration after it. Output a summary of what is still changing and whether it is structural or prose-only. Then use `AskUserQuestion` to offer three options: continue for another iteration, stop here and accept the plan as-is, or escalate to `/consult-oracle` for a different perspective on the remaining issues.

**When the same class of defect recurs across iterations**, stop patching the individual instance and instead write the root-cause invariant into the plan itself, enumerating the worked failures it must prevent. In the same pass, re-read the whole plan against the new invariant and fix every instance it catches, including text written before the invariant existed. Treat recurrence on a new axis of the same invariant as a signal that the invariant is incomplete: widen it to cover the new axis rather than assuming the latest fix failed. When the recurring defect turns on how a platform, framework, or dependency behaves and nobody has observed that behavior, run the instrumented experiment before writing the invariant: an invariant derived from reasoning can be wrong in exactly the way the mechanism it replaces was wrong, and every later round is measured against it.

**When successive rounds move away from each alternative in turn on a different ground and the loop arrives back at a design an earlier round left behind**, treat that as evidence the first finding's severity was misjudged against the alternatives' failure modes. Re-examine that finding rather than inventing another mechanism: when the earlier design survives the comparison, adopt it and record that finding as Skip, citing the alternatives' failure modes; when the user chose the direction that displaced it, surface it as Escalate, naming the original decision and this evidence beside it.

**When a round has adopted a scope narrowing to limit blast radius**, check that the narrowing is derivable. The narrow case is implementable only when the fact distinguishing it from the broad case is available to the implementation at the point the rule runs, whether from persisted state, the request, configuration, or data already at hand; when nothing supplies that fact, the two cases are indistinguishable at runtime and the rule silently strands whatever it excludes. Widen back to the broad case rather than carrying a rule nothing can evaluate, unless the user chose the narrowing: then surface it as Escalate, naming the original decision and this evidence beside it.

The re-invocation is a full, fresh run of this skill, always passing the resolved path. Every step (1-5) executes with its own task tracking and skill invocations. Whichever gate above sends the run into another iteration, supply that iteration with every Skip and Escalate verdict recorded so far, across this run and earlier iterations, as the already-adjudicated list for `/review-plan`, one line each: the finding, its verdict, and the recorded reason. Fresh task tracking leaves that list intact. A finding that re-proposes a design an earlier round left behind stays in scope regardless of the list: the alternatives having since failed on their own grounds is evidence the earlier reason did not account for, and it is the signal the rule above depends on.

Then use the TaskList tool and proceed to any remaining task.

### Structural Edit Examples

Added or removed steps, new or removed design decisions, rewired dependencies between steps, changed acceptance criteria, changed the deployment's stated bounds, changed testing strategy.

## Rules

- Every step must run in every iteration. `/evaluate-findings` is a judgment gate that must run before `/apply-findings` touches the plan. Each step must invoke its designated skill via the Skill tool.
- Re-invocations from Step 5 are full runs with fresh task tracking and complete skill invocations.
- The plan file is the only file that should change.
