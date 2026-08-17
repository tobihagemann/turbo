---
name: refine-plan
description: "Iteratively review and revise a plan until no new findings survive evaluation. Use when the user asks to \"refine the plan\", \"iterate on the plan\", \"tighten the plan\", or \"improve the plan\"."
---

# Refine Plan

Loop the review pipeline over a plan until no new findings are accepted. Writes back to the plan file in place.

## Task Tracking

At the start of every invocation (including re-runs from Step 5), use `update_plan` to track each step, restating any remaining steps of a parent workflow alongside them:

1. Resolve the plan
2. Run `$review-plan` skill
3. Run `$evaluate-findings` skill
4. Run `$apply-findings` skill
5. Re-run `$refine-plan` skill if changed

## Step 1: Resolve the Plan

1. **Explicit path** — use it
2. **Explicit slug** — resolve to `.turbo/plans/<slug>.md`
3. **Single file** — Glob `.turbo/plans/*.md`. If exactly one file exists, use it
4. **Most recent** — most recently modified file
5. **Legacy fallback** — `.turbo/plan.md` if `.turbo/plans/` does not exist
6. **Nothing found** — tell the user to run `$turboplan` and stop

If multiple candidates exist and the choice is non-obvious, use `request_user_input`.

State the resolved path before continuing.

## Loop State

Loop state lives at `.turbo/loops/<slug>.md` — slug from the resolved plan; for a legacy single-file fallback, use the file's basename. At the start of every invocation, read the ledger if it exists.

- **Fresh loop** (no ledger, or its `Status:` line is `closed`): write a fresh ledger with `Status: active`, then attempt `create_goal` with the objective: "Run the `$refine-plan` loop on <plan path> until converged: a run with no changes, a prose-only round, or remaining findings that do not justify another re-run. Loop state: `.turbo/loops/<slug>.md`; re-read it after any context compaction and do not re-adjudicate findings it records as rejected. Mark this goal complete when the loop converges." If an unfinished goal already exists, an outer workflow owns it; continue without creating one.
- **Continuing loop** (`Status: active`): this invocation is the iteration after the last one the ledger records, whether a Step 5 re-run or a resumption after an interruption. Continue from the recorded state. If no unfinished goal exists, attempt `create_goal` with the same objective as a fresh loop.
- **During each iteration:** have the ledger path in context when Step 3 runs so recorded verdicts are honored. After Step 5's classification, append the iteration number, the round's applied and rejected verdicts with reasons, and the classification.
- **Convergence stop** (a run with no changes, a prose-only round, or a further re-run judged pointless): set `Status: closed`; if this loop created the goal, mark it complete with `update_goal`. An inherited goal stays active for the outer workflow. A halt on an unresolved failure leaves `Status: active` and the goal untouched, so the next invocation resumes the recorded state.

## Step 2: Run `$review-plan` Skill

Run the `$review-plan` skill on the resolved plan.

Always run this step even if the plan looks polished.

## Step 3: Run `$evaluate-findings` Skill

Run the `$evaluate-findings` skill on the review findings from Step 2.

## Step 4: Run `$apply-findings` Skill

Run the `$apply-findings` skill on the evaluated results.

## Step 5: Re-run `$refine-plan` Skill if Changed

Check whether the plan file was edited during Step 4. Any edit counts.

Iteration 1 is the initial run; iteration 2 is the first auto-re-run; and so on. The loop is not capped; it terminates on its own: when a run makes no changes, when a round makes only prose-only edits, or when you judge a further re-run pointless.

**If changes were made**, classify what Step 4 edited:

- **Structural edits** — run `$refine-plan` again by reading and following the installed skill instructions, passing the resolved path. If the round contains both structural and prose-only edits, treat it as structural and re-run automatically.
- **Prose-only edits only** (reworded sentences in place, fixed stale examples, clarified existing text without changing meaning) — the loop has converged. Output a summary of what changed and stop; do not re-run.

**If changes were made but you judge a re-run unnecessary**, output a summary of what changed and your reasoning for stopping, then stop instead of re-running.

Judge convergence by the trend across iterations: when rounds have stopped surfacing defects (contradictions, infeasible steps, missing requirements) and keep surfacing improvements of kinds earlier rounds already applied, a further re-run is pointless even though the edits were structural. A round that surfaces no defects is the termination signal; never add a confirmation round, an extra reviewer, or review steps beyond this skill's own.

Judge the kind of surviving defect as well as the trend. Once earlier rounds have drained the design- and requirement-level defects and a round's findings are dominated by claims that a named identifier does not exist or does not match its declaration, the plan has passed the point where reviewing it as text pays, even when the count is rising and every finding is genuine. Implementation surfaces that class immediately; a further re-run is pointless. Expect any round that adds mechanism to seed defects at the seams it creates.

When a round's findings turn on how a platform, framework, or dependency behaves and nobody has observed that behavior, prefer a cheap instrumented experiment to another review round. Run it in a temp directory outside the repo, and record what it shows in the plan before judging whether another round is warranted.

**When the same class of defect recurs across iterations**, stop patching the individual instance and instead write the root-cause invariant into the plan itself, enumerating the worked failures it must prevent. In the same pass, re-read the whole plan against the new invariant and fix every instance it catches, including text written before the invariant existed. Treat recurrence on a new axis of the same invariant as a signal that the invariant is incomplete: widen it to cover the new axis rather than assuming the latest fix failed. When the recurring defect turns on how a platform, framework, or dependency behaves and nobody has observed that behavior, run the instrumented experiment before writing the invariant: an invariant derived from reasoning can be wrong in exactly the way the mechanism it replaces was wrong, and every later round is measured against it.

**When successive rounds move away from each alternative in turn on a different ground and the loop arrives back at a design an earlier round left behind**, treat that as evidence the first finding's severity was misjudged against the alternatives' failure modes. Re-examine that finding rather than inventing another mechanism: when the earlier design survives the comparison, adopt it and record that finding as Skip, citing the alternatives' failure modes; when the user chose the direction that displaced it, surface it as Escalate, naming the original decision and this evidence beside it.

**When a round has adopted a scope narrowing to limit blast radius**, check that the narrowing is derivable. The narrow case is implementable only when the fact distinguishing it from the broad case is available to the implementation at the point the rule runs, whether from persisted state, the request, configuration, or data already at hand; when nothing supplies that fact, the two cases are indistinguishable at runtime and the rule silently strands whatever it excludes. Widen back to the broad case rather than carrying a rule nothing can evaluate, unless the user chose the narrowing: then surface it as Escalate, naming the original decision and this evidence beside it.

The re-invocation is a full, fresh run of this skill. Every step (1-5) executes with its own task tracking and skill invocations.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

### Structural Edit Examples

Added or removed steps, new or removed design decisions, rewired dependencies between steps, changed acceptance criteria, changed the deployment's stated bounds, changed testing strategy.

## Rules

- Every step must run in every iteration. `$evaluate-findings` is a judgment gate that must run before `$apply-findings` touches the plan. Each step must invoke its designated skill by reading and following the installed skill instructions.
- Re-invocations from Step 5 are full runs with fresh task tracking and complete skill invocations.
- Besides the loop ledger and workflow-state bookkeeping under `.turbo/`, the plan file is the only file that should change.
