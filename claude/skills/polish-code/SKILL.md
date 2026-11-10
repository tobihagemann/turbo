---
name: polish-code
description: "Stage, format, lint, test, review, smoke test, and re-run until stable. Use when the user asks to \"polish code\", \"refine code\", \"iterate on code quality\", \"review loop\", or \"run the polish loop\"."
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

## Loop State

Loop state lives in a ledger at `.turbo/loops/polish-code-<label>-<tag>.md`. The label is the governing plan's slug when one is in context, otherwise the current branch name with non-alphanumerics replaced by hyphens. The tag is the output of `head -c 4 /dev/urandom | xxd -p`, minted once when the loop starts. The ledger records `Branch:` (the unmodified branch name, or `(detached)`), `Plan:` when a plan governs, a one-line purpose, and per iteration an `Iteration <N>: <state>` line, its verdicts, and Step 7's classification. A ledger that exists belongs to an active loop.

At the start of every invocation, before `/stage` runs in Step 1, resolve the ledger:

- **Carried path:** this invocation was passed a ledger path, by the re-run Step 7 starts or by a handoff. Continue that ledger. A carried path whose file no longer exists falls through to discovery. Take a carried path only from those two sources, never from a task another invocation left behind.
- **Discovery:** with nothing carried, list the untracked ledgers in `.turbo/loops/` whose name starts with `polish-code-` and whose `Branch:` is the current branch. Also list every untracked `polish-code-` ledger there that holds a `Pending smoke-test baseline`, on any branch. Output each one's purpose, last iteration and its state, and file modification time as text. For a pending baseline, add its differing paths, found by items 1-3 of the pending-baseline reconciliation. When any are listed, use `AskUserQuestion` to offer resuming a ledger, discarding a ledger, or starting fresh, naming the ledger in each resume and discard option; when more ledgers are listed than options fit, first ask which ledger to act on, offering the most recently modified ones and leaving the rest to the free-text answer. Starting fresh mints a new path and deletes nothing. Delete a ledger named for discarding once any pending baseline in it is reconciled, then run discovery again. Reconciling a pending baseline right after discovery reuses the capture and differences discovery produced.
- **Fresh:** mint a new path and write the ledger with `Iteration 1: open`.

Once the ledger resolves, use `TaskUpdate` to write its path into this invocation's Step 7 task description. After a compaction, this invocation reads its ledger path back from that task.

**Iteration state.** The current iteration's state line reads `open` until Step 7 reaches a gate, `awaiting <gate>` while Step 7 waits on the user at one (the in-place round, the skip permission, the hard cap, or the context-signal question, recorded with the gate it wraps), and `classified` once Step 7 has settled whether another iteration runs. On a continued ledger, read the last iteration's state:

- `classified`: carry out the decision recorded with the classification. On another iteration, this invocation is the next one: append `Iteration <N+1>: open`. On an escalation to `/consult-oracle`, resume that escalation, and once the oracle answers, record the decision its answer leads to (another iteration, or a stop that deletes the ledger) in place of the escalation.
- `awaiting <gate>`: the interrupted iteration already ran Steps 1-6, so mark this invocation's Step 1-6 tasks completed. Ask that gate again before anything else; for the context-signal question, ask only the gate it wraps, since this session starts with fresh context. When it wrapped an automatic re-run, offer run another iteration, marked recommended, or stop iterating; when it wrapped a run that edited nothing, the loop has ended, so delete the ledger. Then proceed by the answer as Step 7 does.
- `open`: the iteration was interrupted. Rerun it under its own number from Step 1. The verdicts it already recorded stand: Step 4 keeps them rather than recording them again.

A compaction in flight is not a resume: this invocation continues its own iteration. A continued ledger supplies the most recent `/review-code` diff command it records, when it records one, in place of Step 3's default.

**Pending smoke-test baseline.** This entry means an iteration was interrupted between delegating the smoke test and verifying the tree. Reconcile it before Step 1 whenever a resumed or discarded ledger holds one, so Step 1 does not stage what the interrupted subagent left behind. The entry holds a state from `${CLAUDE_SKILL_DIR}/scripts/checkout-snapshot.sh`:

1. Run `checkout-snapshot.sh check` with that state. When it prints `LOST`, `git gc` has pruned the snapshot; when it prints `INVALID`, the state names a HEAD ref outside the local branches or paths git never checks out. Either way, report it, write nothing, and clear the entry once the report is out.
2. Run `checkout-snapshot.sh capture` for the current state.
3. List what differs between the two: the paths `git diff --name-only --no-renames` reports between their index trees and between their raw trees, and any difference in REF or COMMIT.
4. When nothing differs, clear the entry and continue.
5. Otherwise output the differences as text, then use `AskUserQuestion` to offer restoring the pending baseline or keeping the current state. Restoring runs `checkout-snapshot.sh restore` with the pending state; record the `UNDO` line and any `MOVED` lines it prints in the ledger as `Post-run state`, as Step 6 does. Then run `verify` and handle its result as Step 6's tree verification does. Keeping clears the entry.

**Recording.** Have the ledger path in context when Steps 3 and 4 run, so recorded verdicts are honored. Append each Skip, Escalate, and Apply verdict with its reason under the current iteration as Steps 4-6 reach it, along with the user's resolution of an Escalate. For an Escalate the user resolved, the reason attributes to the user only what they decided; the details you picked while implementing it stay open to review.

**Closing the loop.** Delete the ledger at a convergence stop, at a stop the user chooses at a Step 7 gate, and at a stop granted at the skip gate. Keep it when escalating to `/consult-oracle`, since the oracle's answer decides what follows, when the user stops the loop at Step 6 to repair the checkout by hand, and when halting on an unresolved failure.

## Step 1: Run `/stage` Skill

Resolve the ledger as Loop State describes, then run the `/stage` skill.

## Step 2: Run `/run-checks` Skill

Run the `/run-checks` skill.

Stage all changes made in this step before continuing.

## Step 3: Run `/review-code` Skill

Run the `/review-code` skill on the staged changes. The diff command is `git diff --cached`. When a plan governs the work, supply the ledger's `Plan:` path as the governing document. Supply every Skip and Escalate verdict and every narrowed Apply the ledger records, across all iterations, as the already-adjudicated list, one line each: the finding, its verdict, and the recorded reason. An Escalate the user resolved carries their resolution. A narrowed Apply carries what the remedy covered and what it left, so the untouched remainder reads as settled rather than as an unaddressed gap. A finding that re-proposes a remedy an earlier round narrowed stays in scope regardless of the list: the remainder having since caused a defect is evidence the earlier reason did not account for, and it is the signal Step 5's recurring-class rule depends on.

## Step 4: Run `/evaluate-findings` Skill

Run the `/evaluate-findings` skill on the results from Step 3.

## Step 5: Run `/apply-findings` Skill

Record the staged tree with `git write-tree` before applying anything, and write the tree ID it prints to the ledger as `Review tree`, replacing any entry already there.

Run the `/apply-findings` skill on the evaluated results.

**When a defect this run fixes, in this step or in Step 6, is a further instance of a class of defect an earlier iteration already fixed**, stop patching the individual instance and instead encode the root-cause invariant structurally — a shared guard or type, or a regression test that pins the class against the worked failures it must prevent. For a finding, make that the fix `/apply-findings` applies for it, so that skill's checks run on it. Recognize a class by its failure and what triggers it, so a further instance in another function or file counts as the class recurring. Count a defect that swings to the opposite failure after its fix, such as a check found too strict in one round and too lax in the next, as the same class recurring. In the same pass, audit the existing code against the newly encoded invariant and fix every instance it catches, including code written before it existed. When the recurring instance sits in code outside the changeset and so reaches the user as an escalated finding, make the invariant and that audit the remedy offered for it, with a fix to the individual instance as the narrower alternative. Treat recurrence on a new axis of the same invariant as a signal that the invariant is incomplete: widen it to cover the new axis rather than assuming the latest fix failed.

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

## Step 6: Run `/smoke-test` Skill

Run `bash ${CLAUDE_SKILL_DIR}/scripts/checkout-snapshot.sh capture` before spawning. It prints the checkout's state as five values, `REF COMMIT IDX RAW HID`: HEAD's full ref (`-` when detached), its commit (`unborn` when there is none), the index tree, a tree of every working-tree file outside gitignored paths and `.turbo/`, hashed byte for byte, and a list of the paths on disk it leaves out, which restore never deletes. It reports on stderr, as `SKIPPED`, each gitlink, embedded repository, tracked path now holding a directory, and path whose name contains a newline or carriage return. These stay outside what it restores. When `capture` fails, it names the cause, such as an unmerged index: resolve that before spawning.

When the ledger records a `Smoke-tested baseline`, compare its state against the capture. When COMMIT, IDX, and RAW all match, report the result recorded with that baseline as carried forward and close this step, running neither the `/smoke-test` skill nor a test run. A partial match also carries the result forward the same way when all four of these hold. COMMIT matches. The unstaged changes are the same: `git diff --raw --no-renames <baseline IDX> <baseline RAW>` equals `git diff --raw --no-renames <IDX> <RAW>`. The recorded run ran no integration test suite. Every file `git diff --name-only --no-renames <baseline IDX> <IDX>` lists lies in test sources, test fixtures, or documentation that the app's build and runtime never load. Name those files when carrying the result forward. On any other difference, or with no such entry, continue.

Run the `/smoke-test` skill to produce the smoke test plan.

Record the captured state in the ledger as `Pending smoke-test baseline`, replacing any entry already there.

Delegate test execution to an Agent tool call (`model: "opus"`, no `name`). Wait for it to report before continuing; do not relaunch it if it has not yet reported. Pass the plan and the diff command (`git diff --cached`) to the subagent, and instruct it to invoke `/test-run-rules` via the Skill tool before executing the plan. State in its prompt that the writes the plan's Setup contract authorizes are already approved, and that any write outside that enumeration leaves its scenario blocked.

**Verify the tree** when the subagent returns, including when it terminates early or reports incomplete results: run `checkout-snapshot.sh verify` with the pending state. When it exits 0, the subagent left the checkout as it found it. Otherwise run `checkout-snapshot.sh restore` with the pending state, then `verify` again. Before writing anything, `restore` prints the state it found as an `UNDO` line: record that and any `MOVED` lines in the ledger as `Post-run state`, replacing any entry already there, so running `restore` with it undoes the restore apart from the `MOVED` branches.

Report the `RESTORED` and `INDEX` paths, the `UNDO` state, and each `MOVED` branch with the commit it held (`none` when restore created the branch). Also report each path printed as `LEFT` or `SKIPPED`, which stayed as the subagent left it, and each path printed as `FAILED`, whose write failed and whose prior content survives only in the `UNDO` state. Name any change you see in gitignored paths or `.turbo/` as outside what the snapshot restores. Judge the result by `verify` alone: after a restore, `git status` can report modifications the bytes do not contain.

When `verify` passes, on the first run or after the restore, clear the `Pending smoke-test baseline` entry. When `restore` prints `LOST` or `INVALID`, or `verify` still fails, keep the entry. Output what still differs from the pending state as text, including the `LEFT` and `FAILED` paths, then use `AskUserQuestion` to offer keeping the current state, which clears the entry so later steps stage the checkout as it stands, or stopping the loop so the checkout can be repaired by hand, which keeps the ledger.

If any test fails, or the subagent reports a defect in the staged changes outside the plan's scenarios and the code confirms it, fix the issues and stage the fixes. When every planned test passed, this step made no fix, and the first `verify` exited 0, record the `Smoke-tested baseline` in the ledger, replacing any entry already there: the captured state and the result the run reported, including whether it ran an integration test suite.

## Step 7: Re-run `/polish-code` Skill if Changed

Check whether any file was edited during Steps 5-6: `git diff --name-only <tree> --cached` lists them, where `<tree>` is the ledger's `Review tree`. Any edit counts.

The iteration number below is the ledger's number for the `/polish-code` run currently executing Step 7. It is not the iteration number of a prospective re-run. Iteration 1 is the initial run; iteration 2 is the first auto-re-run; iteration 3 is the second auto-re-run; iteration 4 and beyond exist only when the user opts in at the hard-cap ask. Iterations 1 and 2 always follow the classification gate (they never trigger the hard cap at their own Step 7, even when the auto-re-run they spawn would be iteration 3). The hard cap fires at the end of iteration 3 and every iteration thereafter.

**Iterations 1 and 2, if changes were made**, classify what Steps 5-6 edited:

- **Structural edits** (fixed bugs, new or removed functions, changed function signatures, moved code between files, changed control flow, added or removed dependencies, corrected a stale or wrong comment that was itself a documentation bug) — run `/polish-code` again using the Skill tool, passing the ledger path. Scope the diff command to what changed since this iteration's review: use `git diff <tree> --cached` as the diff command for `/review-code`. Smoke test scope remains unchanged (full feature scope, not narrowed to that diff). If the round contains both structural and in-place edits, treat it as structural and re-run automatically.
- **In-place edits only** (renamed local variables without changing behavior, reformatted, adjusted whitespace, edited neutral comments) — output a summary of what changed, then use `AskUserQuestion` to ask whether to run one more round or stop here. Do not silently continue or silently stop.

**Iterations 1 and 2, if changes were made but you believe re-running is unnecessary**, use `AskUserQuestion` to ask for skip permission. Do not skip silently.

Judge whether another round is worthwhile by the trend across iterations: when rounds have stopped surfacing defects (wrong behavior, security exposures, broken contracts) and keep surfacing improvements of kinds earlier rounds already applied, the loop has converged even though the edits were structural — recommend stopping. A round that surfaces no defects is the termination signal; never add a confirmation round, an extra reviewer, or review steps beyond this skill's own.

Treat reversal as the stronger signal: when a round's accepted findings undo an earlier round's accepted findings on the same lines, the reviewers are trading equally defensible positions rather than converging on one answer. Recommend stopping there even though such edits classify as structural. Keep the current round's version of the reversed code, which is as likely to be the better answer as the one it replaced.

Weigh where a round's defects live alongside whether it found any. When the change the run set out to make has been stable for two or more rounds and every new defect sits in verification scaffolding an earlier round added — a probe, a gate, a check, or the documentation describing them — the loop is generating its own work rather than converging on the change. Recommend stopping there even though the round surfaced defects.

Wherever this step asks or recommends stopping rather than re-running automatically, weigh the files Steps 5-6 changed that this iteration's review did not read: every iteration reviews the diff as it stood before its own fixes, so those files have had no review pass. Let them argue for one more round whose `/review-code` diff command is `git diff <tree> --cached`. The reversal and defect-location signals outrank that, so a round tripping either one stops even with files left unread. Files a later round's review reads stop counting toward this.

Every stop this step reaches with changes pending names those unread files, by path, or by cluster with a count when there are many. State alongside them that stopping leaves those files covered by the Step 6 smoke run and by Step 5's per-fix verification, and not by `/review-code` or by the Step 2 check gate, which ran before they existed. When Step 6 carried its result forward, name only Step 5's per-fix verification and state that no smoke run followed those edits. Name separately any file a Step 6 fix edited: the smoke run and Step 5's verification preceded that fix as well.

**Iteration 3 or later, if Steps 5-6 of this run made changes**, the hard cap is reached. This replaces the classification gate above for iteration 3 and every iteration after it. Output a summary of what is still changing, whether it is structural or in-place, and where this round's defects lived (in the product, or in the build, CI, and gate scaffolding around it). Then use `AskUserQuestion` to offer three options: run another iteration, whose review scope includes the unread files named above; stop iterating, accepting the current state so the workflow moves on; or escalate to `/consult-oracle` for a different perspective on the remaining issues.

Before each `AskUserQuestion` call this step makes, mark the current iteration `awaiting <gate>` in the ledger, naming the gate, and for the context-signal question the gate it wraps. Once this step has settled what follows, by a gate's answer or by an automatic re-run, mark the iteration `classified`, and append the classification, the decision (another iteration, a stop, or an escalation to `/consult-oracle`), and, when another iteration runs, its `/review-code` diff command with the tree ID filled in. Write these before starting the re-run or the escalation, writing a handoff, or deleting the ledger. When an escalation's answer settles what follows, record that decision in place of the escalation before acting on it.

**Before acting on any gate above, check for a context signal.** Call the `mcp__turbo__context-level` tool: a reading of 25% or less remaining is one. A request from the user to compact, arriving since the session last compacted, is the other. When either is present, turn whatever this step reached, including an automatic re-run and a run that edited nothing, into one `AskUserQuestion` call. Its first question asks whether to compact before what comes next: "Handoff, then compact", marked recommended, or keep going in this session, which acts on the gate's answer here. Leave it out when the user asked to compact. Its second question offers the choices of the gate this step reached, with the recommendation that gate would make; in place of an automatic re-run, it offers run another iteration, marked recommended, or stop iterating. Leave it out when no file was edited in Steps 5-6. Make no `AskUserQuestion` call when both are left out. When no file was edited and TaskList shows no pending task that no `/polish-code` iteration created, nothing remains to resume: ignore the signal and let the loop end.

**On "Handoff, then compact", or when the user asked to compact**, check first whether the gate's answer is stop iterating while TaskList shows no pending task that no `/polish-code` iteration created. Then nothing remains to resume: tell the user so and close this step without a handoff. Otherwise run the `/handoff` skill, or, when this session already wrote a handoff, edit that file. Point its next step at what the gate's answer leads to, and once the handoff is written, update this step's task as that branch says:

- **Run another iteration** — the re-run. The handoff names the ledger path and the re-run's `/review-code` diff command; the iteration number, the already-adjudicated list, and the smoke baseline stay in the ledger. Use `TaskUpdate` to set this step's task description to the re-run: run `/polish-code` with ledger `<path>` and that diff command. Leave the task in progress.
- **Escalate to `/consult-oracle`** — the escalation. The handoff carries the summary above and names the ledger path, which the escalation keeps. Use `TaskUpdate` to set this step's task description to that escalation, reading the summary from the handoff at its path. Leave the task in progress.
- **Stop iterating, or no file was edited** — the first pending task that no `/polish-code` iteration created. The handoff carries the unread files this stop leaves, and the message ending the turn names them as every stop does. Mark this step's task completed, along with every Step 7 task earlier iterations left in progress.

Then call the `mcp__turbo__compact-and-continue` tool with the handoff's path. End the turn in place of the TaskList call that closes this step, telling the user that the session compacts and continues on its own, and that if it does not, they should run `/compact` and then reply "continue".

The re-invocation is a full, fresh run of this skill. Every step (1-7) executes with its own task tracking and skill invocations, apart from a smoke result Step 6 carries forward. The narrowed diff command only affects what `/review-code` reads. It does not affect which steps run or whether skills are invoked. Whichever gate above sends the run into another iteration, pass that iteration the ledger path.

Then use the TaskList tool and proceed to any remaining task.

## Rules

- Every step must run in every iteration. `/review-code` runs every review type it activates across parallel internal reviewers plus peer review. `/evaluate-findings` is a judgment gate that must run before `/apply-findings`.
- Each step must invoke its designated skill via the Skill tool, not be replaced by inline reasoning or agent calls.
- Re-invocations from Step 7 are full runs with fresh task tracking and complete skill invocations.
- Two exceptions apply to the rules above: Step 6 carrying a smoke result forward on a matching baseline, or after a run with no integration test suite on one that differs only in test or documentation files the app never loads; and an invocation resuming a ledger whose last iteration is `awaiting <gate>`, which starts at that gate.
