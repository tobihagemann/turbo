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
- **Continuing loop** (`Status: active`): this invocation is the iteration after the last one the ledger records, whether a Step 7 re-run or a resumption after an interruption. Continue from the recorded state, using the most recent `$review-code` diff command the ledger records, when it records one, in place of Step 3's default. A `Pending smoke-test baseline` entry means a previous iteration was interrupted between delegating the smoke test and verifying the tree: reconcile the tree against that entry and clear it before Step 1, so Step 1 does not stage what the interrupted sub-agent left behind. If no unfinished goal exists, attempt `create_goal` with the same objective as a fresh loop.
- **During each iteration:** have the ledger path in context when Steps 3 and 4 run so recorded verdicts are honored. Append each applied, rejected, and escalated verdict with its reason to the ledger under the iteration number as Steps 4-6 reach it, along with the user's resolution of an escalated one. After Step 7's classification, append the classification and, when the run goes into another iteration, that iteration's `$review-code` diff command with the tree ID filled in. For an escalated verdict the user resolved, the reason attributes to the user only what they decided; the details you picked while implementing it stay open to review.
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

Record the staged tree with `git write-tree` before applying anything, and write the tree ID it prints to the ledger as `Review tree`, replacing any entry already there.

Run the `$apply-findings` skill on the evaluated results.

**When a defect this run fixes, in this step or in Step 6, is a further instance of a class of defect an earlier iteration already fixed**, stop patching the individual instance and instead encode the root-cause invariant structurally — a shared guard or type, or a regression test that pins the class against the worked failures it must prevent. For a finding, make that the fix `$apply-findings` applies for it, so that skill's checks run on it. Recognize a class by its failure and what triggers it, so a further instance in another function or file counts as the class recurring. Count a defect that swings to the opposite failure after its fix, such as a check found too strict in one round and too lax in the next, as the same class recurring. In the same pass, audit the existing code against the newly encoded invariant and fix every instance it catches, including code written before it existed. When the recurring instance sits in code outside the changeset and so reaches the user as an escalated finding, make the invariant and that audit the remedy offered for it, with a fix to the individual instance as the narrower alternative. Treat recurrence on a new axis of the same invariant as a signal that the invariant is incomplete: widen it to cover the new axis rather than assuming the latest fix failed.

Append any fix whose remedy you deliberately narrowed to the ledger as you make it, naming what the remedy covered and what it left, so Step 7 carries it forward without reconstructing the decision later.

When a fix ships with a regression test, confirm the test fails with the fix reverted, then restore the fix. When that test's outcome depends on the order of concurrent events, also run it many times over with the fix in place. Find what caused a failure on any of those runs, typically an ordering defect in the code or a missing synchronization point in the test, and fix it, then repeat both checks before this step closes.

Stage the fix immediately before mutating it (`git add <file>`), so `git checkout -- <file>` restores it exactly from the index. A file staged in an earlier step has an index copy older than the current edits, and restoring reverts them. Stage only the files about to be mutated: a broader restore point sweeps in working-tree changes the project may require stay uncommitted. When one also carries unrelated changes, write `git diff <file>` to a patch file, back the unrelated changes out of it (delete their `+` lines and turn their `-` lines into context lines), and stage it with `git apply --cached --recount <patch>`. Its index copy then lacks those changes, so copy that file aside before mutating it and restore it from the copy instead of the index. Each mutation edits the shared working tree in place, so hold anything that reads or builds that tree until the mutation is restored.

Before running the tests against a mutation, confirm it landed: `git diff -- <file>` shows the intended change against the index for each mutated file. An edit whose match pattern missed leaves the file untouched. Count a mutation as caught only when the test run reports a failing test, not when the mutation command or a step chained before the tests exited nonzero. When the mutation checks a particular test, count it only when that test is among those reported failing. When the suite crashes or hangs before that test reports, re-run the mutation against the narrowest test selection that includes that test: that run settles only whether that test catches the mutation, and a mutation it does not report on either stays uncounted.

When the fixed code combines several signals, also apply the plausible rewrites a maintainer might reach for — reordering the signals, substituting a fallback chain for a conjunction, dropping a term that looks redundant — and confirm each fails at least one test, then restore the fixed code. A rewrite that passes every test while changing behavior on some input means the tests pin the examples rather than the invariant; add the test that distinguishes it. When the fix guards against an unbounded loop or wait, bound the test itself so that reverting the fix fails rather than hangs: cap the iteration count for a loop; enforce a deadline for a wait. A deadline inside the test can depend on the test cooperating, so also run each such mutation under a timeout enforced from outside the test process.

When the fix changes when, whether, or how often a mechanism runs, mutate the changed line and run the whole affected suite, not only the test written for this fix: a fix can disarm tests that already existed, and those keep passing. Concentrate on the tests whose pass condition is an absence, and establish for each one that still passes whether it passes for the reason it did before. Those tests cannot distinguish a guard that rejected the work from a mechanism that never ran.

A test whose pass condition is an absence needs an assertion establishing the mechanism was reachable. Place that arming assertion before anything that can consume the state it reads. Placed after, the assertion holds whether or not the guard exists, and the test looks rigorous while pinning nothing.

A test that asserts only the direction of a numeric change passes on any movement of the right sign, including rounding noise or drift the fix did not cause. Assert the expected size of the change instead.

**When the test still passes with the fix reverted**, suspect the mutation before the test: confirm it reaches the branch under test and reproduces the original behavior rather than a third one. Name the branch under test and the original behavior it reproduces before running the mutation, then re-read the mutated lines. A mutation that lands a statement away from that branch also changes paths the fix never touched, and the resulting failure is indistinguishable from a caught mutation.

**When the mutation is faithful and the test still passes**, the test cannot observe the defect. Determine which of four shapes applies before reworking the test's setup:

- The assertion inspects output that is identical whether or not the defect is present. Assert on the mechanism itself rather than on the output it produces: teardown, cancellation, deduplication, and ran-only-once fixes leave no trace there.
- The inputs the test drives land the same way under the fixed value and the mutated one. When the fix seeds an initial value, drive an input on the far side of that seed; a test that only advances past it never observes the seed.
- An earlier guard against the same condition catches first, leaving the guard under test unreachable. Construct the ordering that reaches the later guard specifically. A defense-in-depth guard is reachable only through the window its predecessor does not cover, and an end-to-end exercise of the operation misses it systematically.
- The entry surface the test drives is itself closed for the window the guard covers, so no input the test can send reaches the guard. Where the earlier shape puts a predecessor in the code path, this one puts the block ahead of it: when the fix guards a repeat invocation, a busy or pending state on that affordance refuses the repeat before the guard sees it, and the test passes for the wrong reason. Drive an entry point that carries no such state instead.

A test that genuinely cannot be made to fail does not pin the behavior; say so rather than counting it as coverage.

After every mutation in this step, re-run whatever that mutation was checked against and confirm it passes again and the test command itself exits 0, not a filter piped after it, before reporting the result. A clean `git status` looks identical whether the fix was restored or deleted. A run that a mutation made fail can leave behind what a passing run cleans up, such as temporary files and spawned processes. Before that re-run, clear what the failed run left, identified by what the run itself started or named. Leave anything whose origin that does not establish, and name it when reporting the result.

A project command run to verify a fix writes to the shared tree the same way a mutation does. Establish whether it writes tracked files before running it, and read `git status --short` afterward: revert what it wrote, so files it regenerated are not swept into the changeset by the staging below.

Stage all changes made in this step before continuing.

## Step 6: Run `$smoke-test` Skill

Capture `git status --short`, `git diff --cached | git hash-object --stdin`, `git diff | git hash-object --stdin`, and `git symbolic-ref --short -q HEAD` before spawning.

When the ledger records a `Smoke-tested baseline`, compare it against the first three outputs and `git rev-parse HEAD`. When all four match, report the result recorded with that baseline as carried forward and close this step, running neither the `$smoke-test` skill nor a test run. On any difference, or with no such entry, continue.

Run the `$smoke-test` skill to produce the smoke test plan.

Record all four captured outputs in the ledger as `Pending smoke-test baseline`, replacing any entry already there.

Spawn a Codex sub-agent with inherited model defaults to execute the test plan. Pass the plan and the diff command (`git diff --cached`) into the sub-agent's context, and instruct it to read and follow `$test-run-rules` from the installed skill directory before executing the plan. State in its context that the writes the plan's Setup contract authorizes are already approved, and that any write outside that enumeration leaves its scenario blocked.

**Verify the tree:** re-run all four commands when the sub-agent returns, including when it terminates early or reports incomplete results. Compare against `Pending smoke-test baseline`. Delete what the sub-agent created, revert what it modified or staged, and return HEAD to the captured branch, leaving everything that baseline already showed untouched. Clear the entry once the tree matches.

If any test fails, or the sub-agent reports a defect in the staged changes outside the plan's scenarios and the code confirms it, fix the issues and stage the fixes. When every planned test passed, this step made no fix, and the verification above found nothing to delete or revert, record the `Smoke-tested baseline` in the ledger, replacing any entry already there: the first three captured outputs, `git rev-parse HEAD`, and the result the run reported.

## Step 7: Re-run `$polish-code` Skill if Changed

Check whether any file was edited during Steps 5-6: `git diff --name-only <tree> --cached` lists them, where `<tree>` is the ledger's `Review tree`. Any edit counts.

Iteration 1 is the initial run; iteration 2 is the first auto-re-run; and so on. The loop is not capped; it terminates on its own: when a run makes no changes, when a round makes only in-place edits, or when you judge a further re-run pointless.

**If changes were made**, classify what Steps 5-6 edited:

- **Structural edits** (fixed bugs, new or removed functions, changed function signatures, moved code between files, changed control flow, added or removed dependencies, corrected a stale or wrong comment that was itself a documentation bug) — run `$polish-code` again as a fresh skill invocation. Scope the diff command to what changed since this iteration's review: use `git diff <tree> --cached` as the diff command for `$review-code`. Smoke test scope remains unchanged (full feature scope, not narrowed to that diff). If the round contains both structural and in-place edits, treat it as structural and re-run automatically.
- **In-place edits only** (renamed local variables without changing behavior, reformatted, adjusted whitespace, edited neutral comments) — the loop has converged. Output a summary of what changed and stop; do not re-run.

**If changes were made but you judge a re-run unnecessary**, output a summary of what changed, where this round's defects lived (in the product, or in the build, CI, and gate scaffolding around it), and your reasoning for stopping, then stop instead of re-running.

Judge convergence by the trend across iterations: when rounds have stopped surfacing defects (wrong behavior, security exposures, broken contracts) and keep surfacing improvements of kinds earlier rounds already applied, a further re-run is pointless even though the edits were structural. A round that surfaces no defects is the termination signal; never add a confirmation round, an extra reviewer, or review steps beyond this skill's own.

Treat reversal as the stronger signal: when a round's accepted findings undo an earlier round's accepted findings on the same lines, the reviewers are trading equally defensible positions rather than converging on one answer. A further re-run is pointless there even though such edits classify as structural. Keep the current round's version of the reversed code, which is as likely to be the better answer as the one it replaced.

Weigh where a round's defects live alongside whether it found any. When the change the run set out to make has been stable for two or more rounds and every new defect sits in verification scaffolding an earlier round added — a probe, a gate, a check, or the documentation describing them — the loop is generating its own work rather than converging on the change. A further re-run is pointless there even though the round surfaced defects.

Before judging a further re-run pointless, weigh the files Steps 5-6 changed that this run's review did not read: every run reviews the diff as it stood before its own fixes, so those files have had no review pass. Let them argue for one more run whose `$review-code` diff command is `git diff <tree> --cached`. The reversal and defect-location signals outrank that, so a round tripping either one stops even with files left unread. Files a later round's review reads stop counting toward this.

Every stop this step reaches with changes pending names those unread files, by path, or by cluster with a count when there are many. State alongside them that stopping leaves those files covered by the Step 6 smoke run and by Step 5's per-fix verification, and not by `$review-code` or by the Step 2 check gate, which ran before they existed. Name separately any file a Step 6 fix edited: the smoke run and Step 5's verification preceded that fix as well.

The re-invocation is a full, fresh run of this skill. Every step (1-7) executes with its own task tracking and skill invocations, apart from a smoke result Step 6 carries forward. The narrowed diff command only affects what `$review-code` reads. It does not affect which steps run or whether skills are invoked. When the classification above sends the run into another iteration, supply that iteration with every rejected and escalated verdict the ledger records, and every application the ledger records as narrowed, across this run and earlier iterations, as the already-adjudicated list for `$review-code`, one line each: the finding, its verdict, and the recorded reason. A narrowed application carries what the remedy covered and what it left, so the untouched remainder reads as settled rather than as an unaddressed gap. A finding that re-proposes a remedy an earlier round narrowed stays in scope regardless of the list: the remainder having since caused a defect is evidence the earlier reason did not account for, and it is the signal Step 5's recurring-class rule depends on. Source it from the ledger rather than from in-context state, which compaction drops.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

## Rules

- Every step must run in every iteration. `$review-code` covers correctness, security, consistency, API usage, coverage, and simplicity across parallel internal reviewers plus peer review. `$evaluate-findings` is a judgment gate that must run before `$apply-findings`.
- Each step must invoke its designated skill by reading and following that installed skill's instructions, not by substituting inline reasoning.
- Re-invocations from Step 7 are full runs with fresh task tracking and complete skill invocations.
- Step 6 carrying a smoke result forward on a matching baseline is the one exception to the rules above.
