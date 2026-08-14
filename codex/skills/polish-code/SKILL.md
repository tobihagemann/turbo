---
name: polish-code
description: "Stage, format, lint, test, review, smoke test, and re-run itself until stable. Use when the user asks to \"polish code\", \"refine code\", \"iterate on code quality\", \"review loop\", \"clean up, test, and review loop\", or \"run the polish loop\"."
---

# Polish Code

## Task Tracking

At the start of every invocation (including re-runs from Step 7), use `update_plan` to track each step, restating any remaining steps of a parent workflow alongside them:

1. Run `$stage` skill
2. Deterministic cleanup
3. Run `$review-code` skill
4. Run `$evaluate-findings` skill
5. Run `$apply-findings` skill
6. Run `$smoke-test` skill
7. Re-run `$polish-code` skill if changed

## Loop State

Loop state lives at `.turbo/loops/<slug>.md` — slug from the governing plan when one is in context, otherwise the current branch name with non-alphanumerics replaced by hyphens. At the start of every invocation, read the ledger if it exists.

- **Fresh loop** (no ledger, or its `Status:` line is `closed`): write a fresh ledger with `Status: active`, then attempt `create_goal` with the objective: "Run the `$polish-code` loop on <scope> until converged: a run with no changes, an in-place-only round, or remaining findings that do not justify another re-run. Loop state: `.turbo/loops/<slug>.md`; re-read it after any context compaction and do not re-adjudicate findings it records as rejected. Mark this goal complete when the loop converges." If an unfinished goal already exists, an outer workflow owns it; continue without creating one.
- **Continuing loop** (`Status: active`): this invocation is the iteration after the last one the ledger records, whether a Step 7 re-run or a resumption after an interruption. Continue from the recorded state. A `Pending smoke-test baseline` entry means a previous iteration was interrupted between delegating the smoke test and verifying the tree: reconcile the tree against that entry and clear it before Step 1, so Step 1 does not stage what the interrupted sub-agent left behind. If no unfinished goal exists, attempt `create_goal` with the same objective as a fresh loop.
- **During each iteration:** have the ledger path in context when Step 4 runs so recorded verdicts are honored. After Step 7's classification, append the iteration number, the round's applied and rejected verdicts with reasons, and the classification.
- **Convergence stop** (a run with no changes, an in-place-only round, or a further re-run judged pointless): set `Status: closed`; if this loop created the goal, mark it complete with `update_goal`. An inherited goal stays active for the outer workflow. A halt on an unresolved failure leaves `Status: active` and the goal untouched, so the next invocation resumes the recorded state.

## Step 1: Run `$stage` Skill

Run the `$stage` skill.

## Step 2: Deterministic Cleanup

Run the project's full verification gate: every check it defines as a pass/fail condition. The goal is that passing this step means the project's own checks (and CI, where it exists) pass. Build the gate by combining every source below that the project declares (sources 1-3); run the baseline (source 4) only when the project declares none of them:

1. **CI config** — where present, it is the authoritative gate; run the checks it enforces.
2. **Check scripts** — package-manager scripts (`check`, `verify`, `lint`, `typecheck`), Makefile or Taskfile targets, or a combined format+lint script.
3. **Configured tools** — any tool with a config committed to the repo, such as a dead-code or unused-dependency gate. A committed config means the project treats the tool as a gate; run it even when no script or CI invokes it. Do not run such a tool when the project has not configured it; unconfigured runs are discovery, which belongs to `$find-dead-code`.
4. **Baseline** — when the project declares nothing more, run the formatter, then the linter, then the test suite.

Run the formatter first so later checks see formatted code, then the rest. Fix any failure the tools do not auto-resolve. For test failures, run the `$investigate` skill to diagnose the root cause, apply the suggested fix, and re-run; if investigation finds no root cause, stop and report with its findings.

Stage all changes made in this step before continuing.

## Step 3: Run `$review-code` Skill

Run the `$review-code` skill on the staged changes. The diff command is `git diff --cached`.

## Step 4: Run `$evaluate-findings` Skill

Run the `$evaluate-findings` skill on the results from Step 3.

## Step 5: Run `$apply-findings` Skill

Run the `$apply-findings` skill on the evaluated results.

When a fix ships with a regression test, confirm the test fails with the fix reverted, then restore the fix. Stage the fix before mutating it; `git checkout -- <file>` then restores it exactly from the index. A test that cannot be made to fail does not pin the behavior; say so rather than counting it as coverage. When the fixed code combines several signals, also apply the plausible rewrites a maintainer might reach for — reordering the signals, substituting a fallback chain for a conjunction, dropping a term that looks redundant — and confirm each fails at least one test, then restore the fixed code. A rewrite that passes every test while changing behavior on some input means the tests pin the examples rather than the invariant; add the test that distinguishes it. When the fix guards against an unbounded loop or wait, bound the test itself so that reverting the fix fails rather than hangs: cap the iteration count for a loop; enforce a deadline for a wait.

After every mutation in this step, re-run the test and confirm it passes again before reporting the result. A clean `git status` looks identical whether the fix was restored or deleted.

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

**When the same class of defect recurs across iterations**, stop patching the individual instance and instead encode the root-cause invariant structurally — a shared guard or type, or a regression test that pins the class against the worked failures it must prevent. In the same pass, audit the existing code against the newly encoded invariant and fix every instance it catches, including code written before it existed. Treat recurrence on a new axis of the same invariant as a signal that the invariant is incomplete: widen it to cover the new axis rather than assuming the latest fix failed.

The re-invocation is a full, fresh run of this skill. Every step (1-7) executes with its own task tracking and skill invocations. "Scoped to modified files" only affects the diff command passed to `$review-code`. It does not affect which steps run or whether skills are invoked.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

## Rules

- Every step must run in every iteration. `$review-code` covers correctness, security, consistency, API usage, coverage, and simplicity across parallel internal reviewers plus peer review. `$evaluate-findings` is a judgment gate that must run before `$apply-findings`.
- Each step must invoke its designated skill by reading and following that installed skill's instructions, not by substituting inline reasoning.
- Re-invocations from Step 7 are full runs with fresh task tracking and complete skill invocations.
