---
name: polish-code
description: "Stage, format, lint, test, review, smoke test, and re-run itself until stable. Use when the user asks to \"polish code\", \"refine code\", \"iterate on code quality\", \"review loop\", \"clean up, test, and review loop\", or \"run the polish loop\"."
---

# Polish Code

## Task Tracking

At the start of every invocation (including re-runs from Step 7), use `TaskCreate` to create a task for each step:

1. Run `/stage` skill
2. Run `/run-checks` skill
3. Run `/review-code` skill
4. Run `/evaluate-findings` skill
5. Run `/apply-findings` skill
6. Run `/smoke-test` skill
7. Re-run `/polish-code` skill if changed

## Step 1: Run `/stage` Skill

Run the `/stage` skill.

## Step 2: Run `/run-checks` Skill

Run the `/run-checks` skill.

Stage all changes made in this step before continuing.

## Step 3: Run `/review-code` Skill

Run the `/review-code` skill on the staged changes. The diff command is `git diff --cached`.

## Step 4: Run `/evaluate-findings` Skill

Run the `/evaluate-findings` skill on the results from Step 3.

## Step 5: Run `/apply-findings` Skill

Run the `/apply-findings` skill on the evaluated results.

Record any fix whose remedy you deliberately narrowed as you make it, naming what the remedy covered and what it left, so Step 7 carries it forward without reconstructing the decision later.

When a fix ships with a regression test, confirm the test fails with the fix reverted, then restore the fix.

Stage the fix immediately before mutating it (`git add <file>`), so `git checkout -- <file>` restores it exactly from the index. A file staged in an earlier step has an index copy older than the current edits, and restoring reverts them. Stage only the files about to be mutated, and reach for `git add -p <file>` when one also carries unrelated changes: a broader restore point sweeps in working-tree changes the project may require stay uncommitted. Each mutation edits the shared working tree in place, so hold anything that reads or builds that tree until the mutation is restored.

Before running the tests against a mutation, confirm it landed: `git diff -- <file>` shows the intended change against the index for each mutated file. An edit whose match pattern missed leaves the file untouched. Count a mutation as caught only when the test run reports a failing test, not when the mutation command or a step chained before the tests exited nonzero.

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

After every mutation in this step, re-run whatever that mutation was checked against and confirm it passes again before reporting the result. A clean `git status` looks identical whether the fix was restored or deleted.

A project command run to verify a fix writes to the shared tree the same way a mutation does. Establish whether it writes tracked files before running it, and read `git status --short` afterward: revert what it wrote, so files it regenerated are not swept into the changeset by the staging below.

Stage all changes made in this step before continuing.

## Step 6: Run `/smoke-test` Skill

Run the `/smoke-test` skill to produce the smoke test plan.

Capture `git status --short`, `git diff HEAD | git hash-object --stdin`, and `git symbolic-ref --short -q HEAD` before spawning.

Delegate test execution to a subagent using the Agent tool (`model: "opus"`, no `name`). Wait for it to report before continuing; do not relaunch it if it has not yet reported. Pass the plan and the diff command (`git diff --cached`) to the subagent.

**Verify the tree:** re-run all three commands when the subagent returns, including when it terminates early or reports incomplete results. Delete what the subagent created, revert what it modified or staged, and return HEAD to the captured branch, leaving everything the pre-spawn capture already showed untouched.

If any test fails, fix the issues and stage the fixes.

## Step 7: Re-run `/polish-code` Skill if Changed

Check whether any file was edited during Steps 5-6. Any edit counts.

The iteration number below refers to the `/polish-code` run currently executing Step 7. It is not the iteration number of a prospective re-run. Iteration 1 is the initial run; iteration 2 is the first auto-re-run; iteration 3 is the second auto-re-run; iteration 4 and beyond exist only when the user opts in at the hard-cap ask. Iterations 1 and 2 always follow the classification gate (they never trigger the hard cap at their own Step 7, even when the auto-re-run they spawn would be iteration 3). The hard cap fires at the end of iteration 3 and every iteration thereafter.

**Iterations 1 and 2, if changes were made**, classify what Steps 5-6 edited:

- **Structural edits** (fixed bugs, new or removed functions, changed function signatures, moved code between files, changed control flow, added or removed dependencies, corrected a stale or wrong comment that was itself a documentation bug) — run `/polish-code` again using the Skill tool. Scope the diff command to only the files modified in Steps 5-6: use `git diff --cached -- <file1> <file2> ...` as the diff command for `/review-code`. Smoke test scope remains unchanged (full feature scope, not file-narrowed). If the round contains both structural and in-place edits, treat it as structural and re-run automatically.
- **In-place edits only** (renamed local variables without changing behavior, reformatted, adjusted whitespace, edited neutral comments) — output a summary of what changed, then use `AskUserQuestion` to ask whether to run one more round or stop here. Do not silently continue or silently stop.

**Iterations 1 and 2, if changes were made but you believe re-running is unnecessary**, use `AskUserQuestion` to ask for skip permission. Do not skip silently.

Judge whether another round is worthwhile by the trend across iterations: when rounds have stopped surfacing defects (wrong behavior, security exposures, broken contracts) and keep surfacing improvements of kinds earlier rounds already applied, the loop has converged even though the edits were structural — recommend stopping. A round that surfaces no defects is the termination signal; never add a confirmation round, an extra reviewer, or review steps beyond this skill's own.

Treat reversal as the stronger signal: when a round's accepted findings undo an earlier round's accepted findings on the same lines, the reviewers are trading equally defensible positions rather than converging on one answer. Recommend stopping there even though such edits classify as structural. Keep the current round's version of the reversed code, which is as likely to be the better answer as the one it replaced.

Weigh where a round's defects live alongside whether it found any. When the change the run set out to make has been stable for two or more rounds and every new defect sits in verification scaffolding an earlier round added — a probe, a gate, a check, or the documentation describing them — the loop is generating its own work rather than converging on the change. Recommend stopping there even though the round surfaced defects.

Wherever this step asks or recommends stopping rather than re-running automatically, weigh the files Steps 5-6 changed that this iteration's review did not read: every iteration reviews the diff as it stood before its own fixes, so those files have had no review pass. Let them argue for one more round whose `/review-code` diff command lists exactly them. The reversal and defect-location signals outrank that, so a round tripping either one stops even with files left unread. Files a later round's review reads stop counting toward this.

Every stop this step reaches with changes pending names those unread files, by path, or by cluster with a count when there are many. State alongside them that stopping leaves those files covered by the Step 6 smoke run and by Step 5's per-fix verification, and not by `/review-code` or by the Step 2 check gate, which ran before they existed.

**Iteration 3 or later, if Steps 5-6 of this run made changes**, the hard cap is reached. This replaces the classification gate above for iteration 3 and every iteration after it. Output a summary of what is still changing, whether it is structural or in-place, and where this round's defects lived (in the product, or in the build, CI, and gate scaffolding around it). Then use `AskUserQuestion` to offer three options: run another iteration, whose review scope includes the unread files named above; stop iterating, accepting the current state so the workflow moves on; or escalate to `/consult-oracle` for a different perspective on the remaining issues.

**Before acting on any gate above, check for a context signal** arriving since the session last compacted: a notice that the context window is running low, or a request from the user to compact. When one has arrived, turn whatever this step reached, including an automatic re-run and a run that edited nothing, into one `AskUserQuestion` call. Its first question asks whether to compact before what comes next: "Handoff, then compact", marked recommended, or keep going in this session, which acts on the gate's answer here. Leave it out when the user asked to compact. Its second question offers the choices of the gate this step reached, with the recommendation that gate would make; in place of an automatic re-run, it offers run another iteration, marked recommended, or stop iterating. Leave it out when no file was edited in Steps 5-6. Make no call when both are left out. When no file was edited and TaskList shows no pending task that no `/polish-code` iteration created, nothing remains to resume: ignore the signal and let the loop end.

**On "Handoff, then compact", or when the user asked to compact**, check first whether the gate's answer is stop iterating while TaskList shows no pending task that no `/polish-code` iteration created. Then nothing remains to resume: tell the user so and close this step without a handoff. Otherwise run the `/create-handoff` skill, or, when this session already wrote a handoff, edit that file. Point its next step at what the gate's answer leads to, and once the handoff is written, update this step's task as that branch says:

- **Run another iteration** — the re-run. The handoff carries the number of the iteration about to run, the already-adjudicated list this step supplies to it, and its `/review-code` diff command. Use `TaskUpdate` to set this step's task description to the re-run: run `/polish-code` as that iteration with that diff command, reading the already-adjudicated list from the handoff at its path. Leave the task in progress.
- **Escalate to `/consult-oracle`** — the escalation. The handoff carries the summary above and the same state as on another iteration. Use `TaskUpdate` to set this step's task description to that escalation, reading that state from the handoff at its path. Leave the task in progress.
- **Stop iterating, or no file was edited** — the first pending task that no `/polish-code` iteration created. The handoff carries the unread files this stop leaves, and the message ending the turn names them as every stop does. Mark this step's task completed, along with every Step 7 task earlier iterations left in progress.

Then end the turn in place of the TaskList call that closes this step, telling the user to run `/compact` and then reply "continue".

**When the same class of defect recurs across iterations**, stop patching the individual instance and instead encode the root-cause invariant structurally — a shared guard or type, or a regression test that pins the class against the worked failures it must prevent. In the same pass, audit the existing code against the newly encoded invariant and fix every instance it catches, including code written before it existed. Treat recurrence on a new axis of the same invariant as a signal that the invariant is incomplete: widen it to cover the new axis rather than assuming the latest fix failed.

The re-invocation is a full, fresh run of this skill. Every step (1-7) executes with its own task tracking and skill invocations. "Scoped to modified files" only affects the diff command passed to `/review-code`. It does not affect which steps run or whether skills are invoked. Whichever gate above sends the run into another iteration, supply that iteration with every Skip and Escalate verdict recorded so far, and every Apply whose remedy Step 5 recorded as narrowed, across this run and earlier iterations, as the already-adjudicated list for `/review-code`, one line each: the finding, its verdict, and the recorded reason. For an Escalate the user resolved, the reason attributes to the user only what they decided; the details you picked while implementing it stay open to review. A narrowed Apply carries what the remedy covered and what it left, so the untouched remainder reads as settled rather than as an unaddressed gap. Fresh task tracking leaves that list intact. A finding that re-proposes a remedy an earlier round narrowed stays in scope regardless of the list: the remainder having since caused a defect is evidence the earlier reason did not account for, and it is the signal the rule above depends on.

Then use the TaskList tool and proceed to any remaining task.

## Rules

- Every step must run in every iteration. `/review-code` covers correctness, security, consistency, API usage, coverage, and simplicity across parallel internal reviewers plus peer review. `/evaluate-findings` is a judgment gate that must run before `/apply-findings`.
- Each step must invoke its designated skill via the Skill tool, not be replaced by inline reasoning or agent calls.
- Re-invocations from Step 7 are full runs with fresh task tracking and complete skill invocations.
