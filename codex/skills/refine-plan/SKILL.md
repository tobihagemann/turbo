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
6. **Nothing found** — tell the user to run `$turbo:plan` and stop

If multiple candidates exist and the choice is non-obvious, use `request_user_input`.

State the resolved path before continuing.

Unless an explicit path or slug was passed, confirm the resolved plan still describes work that remains to be done. The signal is a frontmatter `status:` of `done`.

When the signal fires, output it as text. Then use `request_user_input` to offer:

- **Refine anyway** — the marker is stale
- **Pick another plan** — resolve to a different file under `.turbo/plans/`, then confirm that plan against this same signal
- **Leave the plan alone** — skip refining

On **Leave the plan alone**, call `update_plan` to drop the remaining refine steps, restating any remaining steps of a parent workflow, then continue with the next step of the active workflow.

Once the plan is settled, resolve the ledger as Loop State describes.

## Loop State

Loop state lives in a ledger at `.turbo/loops/refine-plan-<label>-<tag>.md`. The label is the resolved plan's slug, or the file's basename for a legacy single-file fallback. The tag is the output of `head -c 4 /dev/urandom | xxd -p`, minted once when the loop starts. The ledger records `Branch:` (the unmodified branch name, or `(detached)`), `Plan:` (the resolved plan path), a one-line purpose, and per iteration its verdicts and Step 5's classification. A ledger that exists belongs to an active loop.

Resolve the ledger:

- **Carried path:** this invocation was handed a ledger path, by the re-run Step 5 starts, by the goal objective, or by a `Loop ledger:` line for this loop in the workflow file an inherited goal names. Continue that ledger. A carried path whose file no longer exists falls through to discovery.
- **Discovery:** with nothing carried, list the ledgers in `.turbo/loops/` that git does not track whose name starts with `refine-plan-` and whose `Plan:` is the resolved plan, on any branch. Show each one's purpose, last classified iteration, and file modification time. When any are listed, use `request_user_input` to offer resuming a ledger, discarding a ledger, or starting fresh, naming the ledger in each resume and discard option; when more ledgers are listed than options fit, first ask which ledger to act on, offering the most recently modified ones and leaving the rest to the free-text answer. Starting fresh mints a new path and deletes nothing. Discarding deletes the named ledger, then discovery runs again. When `request_user_input` cannot reach the user, start fresh and delete nothing.
- **Fresh:** mint a new path and write the ledger.

When no unfinished goal exists, attempt `create_goal` with the objective, filling in the ledger path: "Run the `$refine-plan` loop on <plan path> until converged: a run with no changes, a prose-only round, or remaining findings that do not justify another re-run. Loop state: <ledger path>; re-read it after any context compaction and do not re-adjudicate findings it records as rejected or escalated. Mark this goal complete when the loop converges." When an unfinished goal already exists, an outer workflow owns it: when its objective names a workflow file, make sure that file holds a `Loop ledger: <ledger path>` line for this ledger. When `create_goal` fails, or the inherited objective names no workflow file, the path lives in context only, and discovery recovers it after a compaction.

A continuing ledger makes this invocation the iteration after the last one the ledger classifies, whether a Step 5 re-run or a resumption after an interruption. Continue from the recorded state.

**During each iteration:** have the ledger path in context when Steps 2 and 3 run so recorded verdicts are honored. Append each applied, rejected, and escalated verdict with its reason to the ledger under the iteration number as Steps 3-4 reach it, along with the user's resolution of an escalated one. After Step 5's classification, append the classification.

**Convergence stop** (a run with no changes, a prose-only round, or a further re-run judged pointless): delete the ledger and any `Loop ledger:` line for it in the workflow file, then, if this loop created the goal, mark it complete with `update_goal`. An inherited goal stays active for the outer workflow. A halt on an unresolved failure leaves the ledger and the goal untouched, so the next invocation resumes the recorded state.

## Step 2: Run `$review-plan` Skill

Run the `$review-plan` skill on the resolved plan. Supply every rejected and escalated verdict the ledger records, across all iterations, as the already-adjudicated list, one line each: the finding, its verdict, and the recorded reason. An escalated verdict the user resolved carries their resolution. A finding that re-proposes a design an earlier round left behind stays in scope regardless of the list: the alternatives having since failed on their own grounds is evidence the earlier reason did not account for, and Step 5's rule for a loop that arrives back at a design it left behind depends on that signal.

Always run this step even if the plan looks polished.

## Step 3: Run `$evaluate-findings` Skill

Run the `$evaluate-findings` skill on the review findings from Step 2.

## Step 4: Run `$apply-findings` Skill

Run the `$apply-findings` skill on the evaluated results.

## Step 5: Re-run `$refine-plan` Skill if Changed

Check whether the plan file was edited during Step 4. Any edit counts.

Iteration 1 is the initial run; iteration 2 is the first auto-re-run; and so on. The loop is not capped; it terminates on its own: when a run makes no changes, when a round makes only prose-only edits, or when you judge a further re-run pointless.

**If changes were made**, classify what Step 4 edited:

- **Structural edits** — run `$refine-plan` again by reading and following the installed skill instructions, passing the resolved path and the ledger path. If the round contains both structural and prose-only edits, treat it as structural and re-run automatically.
- **Prose-only edits only** (reworded sentences in place, fixed stale examples, clarified existing text without changing meaning) — the loop has converged. Output a summary of what changed and stop; do not re-run.

**If changes were made but you judge a re-run unnecessary**, output a summary of what changed and your reasoning for stopping, then stop instead of re-running.

Judge convergence by the trend across iterations: when rounds have stopped surfacing defects (contradictions, infeasible steps, missing requirements) and keep surfacing improvements of kinds earlier rounds already applied, a further re-run is pointless even though the edits were structural. A round that surfaces no defects is the termination signal; never add a confirmation round, an extra reviewer, or review steps beyond this skill's own.

Judge the kind of surviving defect as well as the trend. Once earlier rounds have drained the design- and requirement-level defects and a round's findings are dominated by claims that a named identifier does not exist or does not match its declaration, the plan has passed the point where reviewing it as text pays, even when the count is rising and every finding is genuine. Implementation surfaces that class immediately; a further re-run is pointless. Expect any round that adds mechanism to seed defects at the seams it creates.

When a round's findings turn on behavior nobody has observed, either how a platform, framework, or dependency behaves, or what a plan-specified algorithm produces on its inputs, prefer a cheap instrumented experiment to another review round. Run it in a temp directory outside the repo, confirm that each setting it varies took effect, and record what it shows in the plan before judging whether another round is warranted. For a plan-specified algorithm, write it as a script there, assert the plan's stated postconditions over randomized and degenerate inputs, and rewrite its rule only from what that run shows. Keep in the sample the inputs on which a postcondition is hard or impossible to meet, and judge each of their outcomes against that postcondition. Measure each postcondition on the outcome the algorithm produces, never by reading back a value it set in order to meet that postcondition, and count how often the condition of each conditional postcondition arose in the sample. A postcondition that could not fail on the sample was not tested: measure it on the outcome, or add inputs that reach its condition, and record the count. Pair a postcondition that holds only once a state is reached, such as "once nothing is pending", with one asserting that the state is reached whenever it should be. Check each postcondition at the moment it must hold, such as when the operation it describes completes. When only a person's real input can show the behavior, such as keyboard focus or a gesture, use `request_user_input` to ask the user for a short hands-on check in place of the experiment, and record what they report the same way. When the check needs the user to act outside this session, such as in another terminal, output its numbered steps, with the exact commands and what to reply once done, as text instead of `request_user_input`, record the pending check in the ledger, and end the turn; read the result from the user's reply or from a log the check writes. A goal continuation turn that carries no reply from the user is not the check's result: end it without calling any tool, and read the log only after the user replies. Mark a behavior that could not be observed as unobserved.

**When the same class of defect recurs across iterations**, stop patching the individual instance. Count as the same class recurring a defect that swings to the opposite failure after its fix, such as a check found too strict in one round and too lax in the next. Count a design- or requirement-level defect in the mechanism an earlier round's fix added the same way. First weigh whether the plan can do without what carries the class, such as a stored value that could be read where it is used. When it can, remove it and fix every part of the plan that relied on it, unless the user chose it: then surface it as Escalate, naming the original decision and this evidence beside it. Otherwise write the root-cause invariant into the plan itself, enumerating the worked failures it must prevent. In the same pass, re-read the whole plan against the new invariant and fix every instance it catches, including text written before the invariant existed. Treat recurrence on a new axis of the same invariant as a signal that the invariant is incomplete: widen it to cover the new axis rather than assuming the latest fix failed. When the recurring defect turns on behavior nobody has observed, run that experiment, or ask for that hands-on check, before writing the invariant: an invariant derived from reasoning can be wrong in exactly the way the mechanism it replaces was wrong, and every later round is measured against it.

**When successive rounds move away from each alternative in turn on a different ground and the loop arrives back at a design an earlier round left behind**, treat that as evidence the first finding's severity was misjudged against the alternatives' failure modes. Re-examine that finding rather than inventing another mechanism: when the earlier design survives the comparison, adopt it and record that finding as Skip, citing the alternatives' failure modes; when the user chose the direction that displaced it, surface it as Escalate, naming the original decision and this evidence beside it.

**When a round has adopted a scope narrowing to limit blast radius**, check that the narrowing is derivable. The narrow case is implementable only when the fact distinguishing it from the broad case is available to the implementation at the point the rule runs, whether from persisted state, the request, configuration, or data already at hand; when nothing supplies that fact, the two cases are indistinguishable at runtime and the rule silently strands whatever it excludes. Widen back to the broad case rather than carrying a rule nothing can evaluate, unless the user chose the narrowing: then surface it as Escalate, naming the original decision and this evidence beside it.

The re-invocation is a full, fresh run of this skill. Every step (1-5) executes with its own task tracking and skill invocations. When the classification above sends the run into another iteration, pass that iteration the ledger path.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

### Structural Edit Examples

Added or removed steps, new or removed design decisions, rewired dependencies between steps, changed acceptance criteria, changed the deployment's stated bounds, changed testing strategy.

## Rules

- Every step must run in every iteration. `$evaluate-findings` is a judgment gate that must run before `$apply-findings` touches the plan. Each step must invoke its designated skill by reading and following the installed skill instructions.
- Re-invocations from Step 5 are full runs with fresh task tracking and complete skill invocations.
- Besides the loop ledger and workflow-state bookkeeping under `.turbo/`, the plan file is the only file that should change.
