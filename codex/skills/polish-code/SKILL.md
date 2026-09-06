---
name: polish-code
description: "Stage, format, lint, test, review, smoke test, and re-run itself until stable. Use when the user asks to \"polish code\", \"refine code\", \"iterate on code quality\", \"review loop\", \"clean up, test, and review loop\", or \"run the polish loop\"."
---

# Polish Code

## Task Tracking

At the start of every invocation (including re-runs from Step 7), use `update_plan` to track each step, restating any remaining steps of a parent workflow alongside them:

1. Run `$stage` skill
2. Run `$run-checks` skill
3. Run `$review-code` skill
4. Run `$evaluate-findings` skill
5. Run `$apply-findings` skill
6. Run `$smoke-test` skill
7. Re-run `$polish-code` skill if changed

## Loop State

Loop state lives at `.turbo/loops/<slug>.md` — slug from the governing plan when one is in context, otherwise the current branch name with non-alphanumerics replaced by hyphens. At the start of every invocation, read the ledger if it exists.

- **Fresh loop** (no ledger, or its `Status:` line is `closed`): write a fresh ledger with `Status: active`, then attempt `create_goal` with the objective: "Run the `$polish-code` loop on <scope> until converged: a run with no changes, an in-place-only round, or remaining findings that do not justify another re-run. Loop state: `.turbo/loops/<slug>.md`; re-read it after any context compaction and do not re-adjudicate findings it records as rejected, escalated, or applied with a narrowed remedy. Mark this goal complete when the loop converges." If an unfinished goal already exists, an outer workflow owns it; continue without creating one.
- **Continuing loop** (`Status: active`): this invocation is the iteration after the last one the ledger records, whether a Step 7 re-run or a resumption after an interruption. Continue from the recorded state. A `Pending smoke-test baseline` entry means a previous iteration was interrupted between delegating the smoke test and verifying the tree: reconcile the tree against that entry and clear it before Step 1, so Step 1 does not stage what the interrupted sub-agent left behind. If no unfinished goal exists, attempt `create_goal` with the same objective as a fresh loop.
- **During each iteration:** have the ledger path in context when Steps 3 and 4 run so recorded verdicts are honored. After Step 7's classification, append the iteration number, the round's applied, rejected, and escalated verdicts with reasons, and the classification.
- **Convergence stop** (a run with no changes, an in-place-only round, or a further re-run judged pointless): set `Status: closed`; if this loop created the goal, mark it complete with `update_goal`. An inherited goal stays active for the outer workflow. A halt on an unresolved failure leaves `Status: active` and the goal untouched, so the next invocation resumes the recorded state.

## Step 1: Run `$stage` Skill

Run the `$stage` skill.

## Step 2: Run `$run-checks` Skill

Run the `$run-checks` skill.

Stage all changes made in this step before continuing.

## Step 3: Run `$review-code` Skill

Run the `$review-code` skill on the staged changes. The diff command is `git diff --cached`.

## Step 4: Run `$evaluate-findings` Skill

Run the `$evaluate-findings` skill on the results from Step 3.

## Step 5: Run `$apply-findings` Skill

Run the `$apply-findings` skill on the evaluated results.

Append any fix whose remedy you deliberately narrowed to the ledger as you make it, naming what the remedy covered and what it left, so Step 7 carries it forward without reconstructing the decision later.

When a fix ships with a regression test, confirm the test fails with the fix reverted, then restore the fix.

Stage the fix immediately before mutating it (`git add <file>`), so `git checkout -- <file>` restores it exactly from the index. A file staged in an earlier step has an index copy older than the current edits, and restoring reverts them. Stage only the files about to be mutated, and reach for `git add -p <file>` when one also carries unrelated changes: a broader restore point sweeps in working-tree changes the project may require stay uncommitted. Each mutation edits the shared working tree in place, so hold anything that reads or builds that tree until the mutation is restored.

When the fixed code combines several signals, also apply the plausible rewrites a maintainer might reach for — reordering the signals, substituting a fallback chain for a conjunction, dropping a term that looks redundant — and confirm each fails at least one test, then restore the fixed code. A rewrite that passes every test while changing behavior on some input means the tests pin the examples rather than the invariant; add the test that distinguishes it. When the fix guards against an unbounded loop or wait, bound the test itself so that reverting the fix fails rather than hangs: cap the iteration count for a loop; enforce a deadline for a wait.

When the fix changes when, whether, or how often a mechanism runs, mutate the changed line and run the whole affected suite, not only the test written for this fix: a fix can disarm tests that already existed, and those keep passing. Concentrate on the tests whose pass condition is an absence, and establish for each one that still passes whether it passes for the reason it did before. Those tests cannot distinguish a guard that rejected the work from a mechanism that never ran.

A test whose pass condition is an absence needs an assertion establishing the mechanism was reachable. Place that arming assertion before anything that can consume the state it reads. Placed after, the assertion holds whether or not the guard exists, and the test looks rigorous while pinning nothing.

**When the test still passes with the fix reverted**, suspect the mutation before the test: confirm it reaches the branch under test and reproduces the original behavior rather than a third one. Name the branch under test and the original behavior it reproduces before running the mutation, then re-read the mutated lines. A mutation that lands a statement away from that branch also changes paths the fix never touched, and the resulting failure is indistinguishable from a caught mutation.

**When the mutation is faithful and the test still passes**, the test cannot observe the defect. Determine which of three shapes applies before reworking the test's setup:

- The assertion inspects output that is identical whether or not the defect is present. Assert on the mechanism itself rather than on the output it produces: teardown, cancellation, deduplication, and ran-only-once fixes leave no trace there.
- The inputs the test drives land the same way under the fixed value and the mutated one. When the fix seeds an initial value, drive an input on the far side of that seed; a test that only advances past it never observes the seed.
- An earlier guard against the same condition catches first, leaving the guard under test unreachable. Construct the ordering that reaches the later guard specifically. A defense-in-depth guard is reachable only through the window its predecessor does not cover, and an end-to-end exercise of the operation misses it systematically.

A test that genuinely cannot be made to fail does not pin the behavior; say so rather than counting it as coverage.

After every mutation in this step, re-run whatever that mutation was checked against and confirm it passes again before reporting the result. A clean `git status` looks identical whether the fix was restored or deleted.

Stage all changes made in this step before continuing.

## Step 6: Run `$smoke-test` Skill

Run the `$smoke-test` skill to produce the smoke test plan.

Capture `git status --short`, `git diff HEAD | git hash-object --stdin`, and `git symbolic-ref --short -q HEAD` before spawning, and record all three outputs in the ledger as `Pending smoke-test baseline`, replacing any entry already there.

Delegate test execution to a Codex sub-agent with inherited model defaults. Pass the plan and the diff command (`git diff --cached`) into the sub-agent's context.

**Verify the tree:** re-run all three commands when the sub-agent returns, including when it terminates early or reports incomplete results. Compare against `Pending smoke-test baseline`. Delete what the sub-agent created, revert what it modified or staged, and return HEAD to the captured branch, leaving everything that baseline already showed untouched. Clear the entry once the tree matches.

If any test fails, fix the issues and stage the fixes.

## Step 7: Re-run `$polish-code` Skill if Changed

Check whether any file was edited during Steps 5-6. Any edit counts.

Iteration 1 is the initial run; iteration 2 is the first auto-re-run; and so on. The loop is not capped; it terminates on its own: when a run makes no changes, when a round makes only in-place edits, or when you judge a further re-run pointless.

**If changes were made**, classify what Steps 5-6 edited:

- **Structural edits** (fixed bugs, new or removed functions, changed function signatures, moved code between files, changed control flow, added or removed dependencies, corrected a stale or wrong comment that was itself a documentation bug) — run `$polish-code` again as a fresh skill invocation. Scope the diff command to only the files modified in Steps 5-6: use `git diff --cached -- <file1> <file2> ...` as the diff command for `$review-code`. Smoke test scope remains unchanged (full feature scope, not file-narrowed). If the round contains both structural and in-place edits, treat it as structural and re-run automatically.
- **In-place edits only** (renamed local variables without changing behavior, reformatted, adjusted whitespace, edited neutral comments) — the loop has converged. Output a summary of what changed and stop; do not re-run.

**If changes were made but you judge a re-run unnecessary**, output a summary of what changed, where this round's defects lived (in the product, or in the build, CI, and gate scaffolding around it), and your reasoning for stopping, then stop instead of re-running.

Judge convergence by the trend across iterations: when rounds have stopped surfacing defects (wrong behavior, security exposures, broken contracts) and keep surfacing improvements of kinds earlier rounds already applied, a further re-run is pointless even though the edits were structural. A round that surfaces no defects is the termination signal; never add a confirmation round, an extra reviewer, or review steps beyond this skill's own.

Treat reversal as the stronger signal: when a round's accepted findings undo an earlier round's accepted findings on the same lines, the reviewers are trading equally defensible positions rather than converging on one answer. A further re-run is pointless there even though such edits classify as structural. Keep the current round's version of the reversed code, which is as likely to be the better answer as the one it replaced.

**When the same class of defect recurs across iterations**, stop patching the individual instance and instead encode the root-cause invariant structurally — a shared guard or type, or a regression test that pins the class against the worked failures it must prevent. In the same pass, audit the existing code against the newly encoded invariant and fix every instance it catches, including code written before it existed. Treat recurrence on a new axis of the same invariant as a signal that the invariant is incomplete: widen it to cover the new axis rather than assuming the latest fix failed.

The re-invocation is a full, fresh run of this skill. Every step (1-7) executes with its own task tracking and skill invocations. "Scoped to modified files" only affects the diff command passed to `$review-code`. It does not affect which steps run or whether skills are invoked. When the classification above sends the run into another iteration, supply that iteration with every rejected and escalated verdict the ledger records, and every application the ledger records as narrowed, across this run and earlier iterations, as the already-adjudicated list for `$review-code`, one line each: the finding, its verdict, and the recorded reason. A narrowed application carries what the remedy covered and what it left, so the untouched remainder reads as settled rather than as an unaddressed gap. A finding that re-proposes a remedy an earlier round narrowed stays in scope regardless of the list: the remainder having since caused a defect is evidence the earlier reason did not account for, and it is the signal the rule above depends on. Source it from the ledger rather than from in-context state, which compaction drops.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

## Rules

- Every step must run in every iteration. `$review-code` covers correctness, security, consistency, API usage, coverage, and simplicity across parallel internal reviewers plus peer review. `$evaluate-findings` is a judgment gate that must run before `$apply-findings`.
- Each step must invoke its designated skill by reading and following that installed skill's instructions, not by substituting inline reasoning.
- Re-invocations from Step 7 are full runs with fresh task tracking and complete skill invocations.
