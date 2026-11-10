---
name: polish-code
description: "Stage, format, lint, test, review, smoke test, and re-run until stable. Use when the user asks to \"polish code\", \"refine code\", \"iterate on code quality\", \"review loop\", or \"run the polish loop\"."
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

Resolve the absolute path of this skill's directory, the directory of the `SKILL.md` loaded for this run, and use it as `<this skill's directory>` below.

Loop state lives in a ledger at `.turbo/loops/polish-code-<label>-<tag>.md`. The label is the governing plan's slug when one is in context, otherwise the current branch name with non-alphanumerics replaced by hyphens. The tag is the output of `head -c 4 /dev/urandom | xxd -p`, minted once when the loop starts. The ledger records `Branch:` (the unmodified branch name, or `(detached)`), `Plan:` when a plan governs, a one-line purpose, and per iteration its verdicts and Step 7's classification. A ledger that exists belongs to an active loop.

At the start of every invocation, before `$stage` runs in Step 1, resolve the ledger:

- **Carried path:** this invocation was handed a ledger path, by the re-run Step 7 starts, by the goal objective, or by a `Loop ledger:` line for this loop in the workflow file an inherited goal names. Continue that ledger. A carried path whose file no longer exists falls through to discovery.
- **Discovery:** with nothing carried, list the untracked ledgers in `.turbo/loops/` whose name starts with `polish-code-` and whose `Branch:` is the current branch. Also list every untracked `polish-code-` ledger there that holds a `Pending smoke-test baseline`, on any branch. Show each one's purpose, last classified iteration, and file modification time. For a pending baseline, add its differing paths, found by items 1-3 of the pending-baseline reconciliation. When any are listed, use `request_user_input` to offer resuming a ledger, discarding a ledger, or starting fresh, naming the ledger in each resume and discard option; when more ledgers are listed than options fit, first ask which ledger to act on, offering the most recently modified ones and leaving the rest to the free-text answer. Starting fresh mints a new path and deletes nothing. Delete a ledger named for discarding once any pending baseline in it is reconciled, then run discovery again. Reconciling a pending baseline right after discovery reuses the capture and differences discovery produced. When `request_user_input` cannot reach the user, start fresh and delete nothing; when a listed ledger holds a pending baseline, halt instead and report its differing paths, so Step 1 does not stage what the interrupted sub-agent left behind.
- **Fresh:** mint a new path and write the ledger.

When no unfinished goal exists, attempt `create_goal` with the objective, filling in the ledger path: "Run the `$polish-code` loop on <scope> until converged: a run with no changes, an in-place-only round, or remaining findings that do not justify another re-run. Loop state: <ledger path>; re-read it after any context compaction and do not re-adjudicate findings it records as rejected, escalated, or applied with a narrowed remedy. Mark this goal complete when the loop converges." When an unfinished goal already exists, an outer workflow owns it: when its objective names a workflow file, make sure that file holds a `Loop ledger: <ledger path>` line for this ledger. When `create_goal` fails, or the inherited objective names no workflow file, the path lives in context only, and discovery recovers it after a compaction.

A continuing ledger makes this invocation the iteration after the last one the ledger classifies, whether a Step 7 re-run or a resumption after an interruption. Continue from the recorded state, using the most recent `$review-code` diff command the ledger records, when it records one, in place of Step 3's default.

**Pending smoke-test baseline.** This entry means an iteration was interrupted between delegating the smoke test and verifying the tree. Reconcile it before Step 1 whenever a resumed or discarded ledger holds one, so Step 1 does not stage what the interrupted sub-agent left behind. The entry holds a state from `<this skill's directory>/scripts/checkout-snapshot.sh`:

1. Run `checkout-snapshot.sh check` with that state. When it prints `LOST`, `git gc` has pruned the snapshot; when it prints `INVALID`, the state names a HEAD ref outside the local branches or paths git never checks out. Either way, report it, write nothing, and clear the entry.
2. Run `checkout-snapshot.sh capture` for the current state.
3. List what differs between the two: the paths `git diff --name-only --no-renames` reports between their index trees and between their raw trees, and any difference in REF or COMMIT.
4. When nothing differs, clear the entry and continue.
5. Otherwise output the differences, then use `request_user_input` to offer restoring the pending baseline or keeping the current state. Restoring runs `checkout-snapshot.sh restore` with the pending state; record the `UNDO` line and any `MOVED` lines it prints in the ledger as `Post-run state`, as Step 6 does. Then run `verify` and handle its result as Step 6's tree verification does. Keeping clears the entry. When the user cannot be reached, halt with the ledger in place and report the differing paths.

**During each iteration:** have the ledger path in context when Steps 3 and 4 run so recorded verdicts are honored. Append each applied, rejected, and escalated verdict with its reason to the ledger under the iteration number as Steps 4-6 reach it, along with the user's resolution of an escalated one. After Step 7's classification, append the classification and, when the run goes into another iteration, that iteration's `$review-code` diff command with the tree ID filled in. For an escalated verdict the user resolved, the reason attributes to the user only what they decided; the details you picked while implementing it stay open to review.

**Convergence stop** (a run with no changes, an in-place-only round, or a further re-run judged pointless): delete the ledger and any `Loop ledger:` line for it in the workflow file, then, if this loop created the goal, mark it complete with `update_goal`. An inherited goal stays active for the outer workflow. A halt on an unresolved failure leaves the ledger and the goal untouched, so the next invocation resumes the recorded state.

## Step 1: Run `$stage` Skill

Resolve the ledger as Loop State describes, then run the `$stage` skill.

## Step 2: Run `$run-checks` Skill

Run the `$run-checks` skill.

Stage all changes made in this step before continuing.

## Step 3: Run `$review-code` Skill

Run the `$review-code` skill on the staged changes. The diff command is `git diff --cached`. When a plan governs the work, supply the ledger's `Plan:` path as the governing document. Supply every rejected and escalated verdict and every narrowed application the ledger records, across all iterations, as the already-adjudicated list, one line each: the finding, its verdict, and the recorded reason. An escalated verdict the user resolved carries their resolution. A narrowed application carries what the remedy covered and what it left, so the untouched remainder reads as settled rather than as an unaddressed gap. A finding that re-proposes a remedy an earlier round narrowed stays in scope regardless of the list: the remainder having since caused a defect is evidence the earlier reason did not account for, and it is the signal Step 5's recurring-class rule depends on.

## Step 4: Run `$evaluate-findings` Skill

Run the `$evaluate-findings` skill on the results from Step 3.

## Step 5: Run `$apply-findings` Skill

Record the staged tree with `git write-tree` before applying anything, and write the tree ID it prints to the ledger as `Review tree`, replacing any entry already there.

Run the `$apply-findings` skill on the evaluated results.

**When a defect this run fixes, in this step or in Step 6, is a further instance of a class of defect an earlier iteration already fixed**, stop patching the individual instance and instead encode the root-cause invariant structurally — a shared guard or type, or a regression test that pins the class against the worked failures it must prevent. For a finding, make that the fix `$apply-findings` applies for it, so that skill's checks run on it. Recognize a class by its failure and what triggers it, so a further instance in another function or file counts as the class recurring. Count a defect that swings to the opposite failure after its fix, such as a check found too strict in one round and too lax in the next, as the same class recurring. In the same pass, audit the existing code against the newly encoded invariant and fix every instance it catches, including code written before it existed. When the recurring instance sits in code outside the changeset and so reaches the user as an escalated finding, make the invariant and that audit the remedy offered for it, with a fix to the individual instance as the narrower alternative. Treat recurrence on a new axis of the same invariant as a signal that the invariant is incomplete: widen it to cover the new axis rather than assuming the latest fix failed.

Append any fix whose remedy you deliberately narrowed to the ledger as you make it, naming what the remedy covered and what it left, so Step 7 carries it forward without reconstructing the decision later.

When a fix ships with a regression test, confirm the test fails with the fix reverted, then restore the fix. When that test's outcome depends on the order of concurrent events, also run it many times over with the fix in place. Find what caused a failure on any of those runs, typically an ordering defect in the code or a missing synchronization point in the test, and fix it, then repeat both checks before this step closes. When the fix consists only of new tests for existing code, mutate the branch each new test or case targets and confirm that test or case is among those reported failing. When the runner does not report that case on its own, run it alone against the mutation.

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

Run `bash <this skill's directory>/scripts/checkout-snapshot.sh capture` before spawning. It prints the checkout's state as five values, `REF COMMIT IDX RAW HID`: HEAD's full ref (`-` when detached), its commit (`unborn` when there is none), the index tree, a tree of every working-tree file outside gitignored paths and `.turbo/`, hashed byte for byte, and a list of the paths on disk it leaves out, which restore never deletes. It reports on stderr, as `SKIPPED`, each gitlink, embedded repository, tracked path now holding a directory, and path whose name contains a newline or carriage return. These stay outside what it restores. When `capture` fails, it names the cause, such as an unmerged index: resolve that before spawning.

When the ledger records a `Smoke-tested baseline`, compare its state against the capture. When COMMIT, IDX, and RAW all match, report the result recorded with that baseline as carried forward and close this step, running neither the `$smoke-test` skill nor a test run. A partial match also carries the result forward the same way when all four of these hold. COMMIT matches. The unstaged changes are the same: `git diff --raw --no-renames <baseline IDX> <baseline RAW>` equals `git diff --raw --no-renames <IDX> <RAW>`. The recorded run ran no integration test suite. Every file `git diff --name-only --no-renames <baseline IDX> <IDX>` lists lies in test sources, test fixtures, or documentation that the app's build and runtime never load. Name those files when carrying the result forward. On any other difference, or with no such entry, continue.

Run the `$smoke-test` skill to produce the smoke test plan.

Record the captured state in the ledger as `Pending smoke-test baseline`, replacing any entry already there.

Spawn a Codex sub-agent with inherited model defaults to execute the test plan. Pass the plan and the diff command (`git diff --cached`) into the sub-agent's context, and instruct it to read and follow `$test-run-rules` from the installed skill directory before executing the plan. State in its context that the writes the plan's Setup contract authorizes are already approved, and that any write outside that enumeration leaves its scenario blocked.

**Verify the tree** when the sub-agent returns, including when it terminates early or reports incomplete results: run `checkout-snapshot.sh verify` with the pending state. When it exits 0, the sub-agent left the checkout as it found it. Otherwise run `checkout-snapshot.sh restore` with the pending state, then `verify` again. Before writing anything, `restore` prints the state it found as an `UNDO` line: record that and any `MOVED` lines in the ledger as `Post-run state`, replacing any entry already there, so running `restore` with it undoes the restore apart from the `MOVED` branches.

Report the `RESTORED` and `INDEX` paths, the `UNDO` state, and each `MOVED` branch with the commit it held (`none` when restore created the branch). Also report each path printed as `LEFT` or `SKIPPED`, which stayed as the sub-agent left it, and each path printed as `FAILED`, whose write failed and whose prior content survives only in the `UNDO` state. Name any change you see in gitignored paths or `.turbo/` as outside what the snapshot restores. Judge the result by `verify` alone: after a restore, `git status` can report modifications the bytes do not contain.

When `verify` passes, on the first run or after the restore, clear the `Pending smoke-test baseline` entry. When `restore` prints `LOST` or `INVALID`, or `verify` still fails, keep the entry. Output what still differs from the pending state, including the `LEFT` and `FAILED` paths, then use `request_user_input` to offer keeping the current state, which clears the entry so later steps stage the checkout as it stands, or stopping the loop so the checkout can be repaired by hand, which keeps the ledger. When the user cannot be reached, halt with the ledger in place and report what still differs.

If any test fails, or the sub-agent reports a defect in the staged changes outside the plan's scenarios and the code confirms it, fix the issues and stage the fixes. When every planned test passed, this step made no fix, and the first `verify` exited 0, record the `Smoke-tested baseline` in the ledger, replacing any entry already there: the captured state and the result the run reported, including whether it ran an integration test suite.

## Step 7: Re-run `$polish-code` Skill if Changed

Check whether any file was edited during Steps 5-6: `git diff --name-only <tree> --cached` lists them, where `<tree>` is the ledger's `Review tree`. Any edit counts.

Iteration 1 is the initial run; iteration 2 is the first auto-re-run; and so on. The loop is not capped; it terminates on its own: when a run makes no changes, when a round makes only in-place edits, or when you judge a further re-run pointless.

**If changes were made**, classify what Steps 5-6 edited:

- **Structural edits** (fixed bugs, new or removed functions, changed function signatures, moved code between files, changed control flow, added or removed dependencies, corrected a stale or wrong comment that was itself a documentation bug) — run `$polish-code` again as a fresh skill invocation, passing the ledger path. Scope the diff command to what changed since this iteration's review: use `git diff <tree> --cached` as the diff command for `$review-code`. Smoke test scope remains unchanged (full feature scope, not narrowed to that diff). If the round contains both structural and in-place edits, treat it as structural and re-run automatically.
- **In-place edits only** (renamed local variables without changing behavior, reformatted, adjusted whitespace, edited neutral comments) — the loop has converged. Output a summary of what changed and stop; do not re-run.

**If changes were made but you judge a re-run unnecessary**, output a summary of what changed, where this round's defects lived (in the product, or in the build, CI, and gate scaffolding around it), and your reasoning for stopping, then stop instead of re-running.

Judge convergence by the trend across iterations: when rounds have stopped surfacing defects (wrong behavior, security exposures, broken contracts) and keep surfacing improvements of kinds earlier rounds already applied, a further re-run is pointless even though the edits were structural. A round that surfaces no defects is the termination signal; never add a confirmation round, an extra reviewer, or review steps beyond this skill's own.

Treat reversal as the stronger signal: when a round's accepted findings undo an earlier round's accepted findings on the same lines, the reviewers are trading equally defensible positions rather than converging on one answer. A further re-run is pointless there even though such edits classify as structural. Keep the current round's version of the reversed code, which is as likely to be the better answer as the one it replaced.

Weigh where a round's defects live alongside whether it found any. When the change the run set out to make has been stable for two or more rounds and every new defect sits in verification scaffolding an earlier round added — a probe, a gate, a check, or the documentation describing them — the loop is generating its own work rather than converging on the change. A further re-run is pointless there even though the round surfaced defects.

Before judging a further re-run pointless, weigh the files Steps 5-6 changed that this run's review did not read: every run reviews the diff as it stood before its own fixes, so those files have had no review pass. Let them argue for one more run whose `$review-code` diff command is `git diff <tree> --cached`. The reversal and defect-location signals outrank that, so a round tripping either one stops even with files left unread. Files a later round's review reads stop counting toward this.

Every stop this step reaches with changes pending names those unread files, by path, or by cluster with a count when there are many. State alongside them that stopping leaves those files covered by the Step 6 smoke run and by Step 5's per-fix verification, and not by `$review-code` or by the Step 2 check gate, which ran before they existed. When Step 6 carried its result forward, name only Step 5's per-fix verification and state that no smoke run followed those edits. Name separately any file a Step 6 fix edited: the smoke run and Step 5's verification preceded that fix as well.

The re-invocation is a full, fresh run of this skill. Every step (1-7) executes with its own task tracking and skill invocations, apart from a smoke result Step 6 carries forward. The narrowed diff command only affects what `$review-code` reads. It does not affect which steps run or whether skills are invoked. When the classification above sends the run into another iteration, pass that iteration the ledger path.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

## Rules

- Every step must run in every iteration. `$review-code` runs every review type it activates across parallel internal reviewers plus peer review. `$evaluate-findings` is a judgment gate that must run before `$apply-findings`.
- Each step must invoke its designated skill by reading and following that installed skill's instructions, not by substituting inline reasoning.
- Re-invocations from Step 7 are full runs with fresh task tracking and complete skill invocations.
- Step 6 carrying a smoke result forward on a matching baseline, or after a run with no integration test suite on one that differs only in test or documentation files the app never loads, is the one exception to the rules above.
