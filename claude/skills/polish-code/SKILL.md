---
name: polish-code
description: "Stage, format, lint, test, review, smoke test, and re-run itself until stable. Use when the user asks to \"polish code\", \"refine code\", \"iterate on code quality\", \"review loop\", \"clean up, test, and review loop\", or \"run the polish loop\"."
---

# Polish Code

## Task Tracking

At the start of every invocation (including re-runs from Step 7), use `TaskCreate` to create a task for each step:

1. Run `/stage` skill
2. Deterministic cleanup
3. Run `/review-code` skill
4. Run `/evaluate-findings` skill
5. Run `/apply-findings` skill
6. Run `/smoke-test` skill
7. Re-run `/polish-code` skill if changed

## Step 1: Run `/stage` Skill

Run the `/stage` skill.

## Step 2: Deterministic Cleanup

Run the project's full verification gate: every check it defines as a pass/fail condition. The goal is that passing this step means the project's own checks (and CI, where it exists) pass. Build the gate by combining every source below that the project declares (sources 1-3); run the baseline (source 4) only when the project declares none of them:

1. **CI config** — where present, it is the authoritative gate; run the checks it enforces.
2. **Check scripts** — package-manager scripts (`check`, `verify`, `lint`, `typecheck`), Makefile or Taskfile targets, or a combined format+lint script.
3. **Configured tools** — any tool with a config committed to the repo, such as a dead-code or unused-dependency gate. A committed config means the project treats the tool as a gate; run it even when no script or CI invokes it. Do not run such a tool when the project has not configured it; unconfigured runs are discovery, which belongs to `/find-dead-code`.
4. **Baseline** — when the project declares nothing more, run the formatter, then the linter, then the test suite.

Run the formatter first so later checks see formatted code, then the rest. Fix any failure the tools do not auto-resolve. For test failures, run the `/investigate` skill to diagnose the root cause, apply the suggested fix, and re-run; if investigation finds no root cause, stop and report with its findings.

Stage all changes made in this step before continuing.

## Step 3: Run `/review-code` Skill

Run the `/review-code` skill on the staged changes. The diff command is `git diff --cached`.

## Step 4: Run `/evaluate-findings` Skill

Run the `/evaluate-findings` skill on the results from Step 3.

## Step 5: Run `/apply-findings` Skill

Run the `/apply-findings` skill on the evaluated results.

Stage all changes made in this step before continuing.

## Step 6: Run `/smoke-test` Skill

Run the `/smoke-test` skill to produce the smoke test plan. Delegate test execution to a subagent using the Agent tool in the foreground (`model: "opus"`, no `name`). Pass the plan and the diff command (`git diff --cached`) to the subagent.

If any test fails, fix the issues and stage the fixes.

## Step 7: Re-run `/polish-code` Skill if Changed

Check whether any file was edited during Steps 5-6. Any edit counts.

The iteration number below refers to the `/polish-code` run currently executing Step 7. It is not the iteration number of a prospective re-run. Iteration 1 is the initial run; iteration 2 is the first auto-re-run; iteration 3 is the second auto-re-run; iteration 4 and beyond exist only when the user opts in at the hard-cap ask. Iterations 1 and 2 always follow the classification gate (they never trigger the hard cap at their own Step 7, even when the auto-re-run they spawn would be iteration 3). The hard cap fires at the end of iteration 3 and every iteration thereafter.

**Iterations 1 and 2, if changes were made**, classify what Steps 5-6 edited:

- **Structural edits** (fixed bugs, new or removed functions, changed function signatures, moved code between files, changed control flow, added or removed dependencies, corrected a stale or wrong comment that was itself a documentation bug) — run `/polish-code` again using the Skill tool. Scope the diff command to only the files modified in Steps 5-6: use `git diff --cached -- <file1> <file2> ...` as the diff command for `/review-code`. Smoke test scope remains unchanged (full feature scope, not file-narrowed). If the round contains both structural and in-place edits, treat it as structural and re-run automatically.
- **In-place edits only** (renamed local variables without changing behavior, reformatted, adjusted whitespace, edited neutral comments) — output a summary of what changed, then use `AskUserQuestion` to ask whether to run one more round or stop here. Do not silently continue or silently stop.

**Iterations 1 and 2, if changes were made but you believe re-running is unnecessary**, use `AskUserQuestion` to ask for skip permission. Do not skip silently.

Judge whether another round is worthwhile by the trend across iterations: when rounds have stopped surfacing defects (wrong behavior, security exposures, broken contracts) and keep surfacing improvements of kinds earlier rounds already applied, the loop has converged even though the edits were structural — recommend stopping. A round that surfaces no defects is the termination signal; never add a confirmation round, an extra reviewer, or review steps beyond this skill's own.

**Iteration 3 or later, if Steps 5-6 of this run made changes**, the hard cap is reached. This replaces the classification gate above for iteration 3 and every iteration after it. Output a summary of what is still changing and whether it is structural or in-place. Then use `AskUserQuestion` to offer three options: continue for another iteration, stop here and accept the current state, or escalate to `/consult-oracle` for a different perspective on the remaining issues.

**When the same class of defect recurs across iterations**, stop patching the individual instance and instead encode the root-cause invariant structurally — a shared guard or type, or a regression test that pins the class against the worked failures it must prevent. In the same pass, audit the existing code against the newly encoded invariant and fix every instance it catches, including code written before it existed. Treat recurrence on a new axis of the same invariant as a signal that the invariant is incomplete: widen it to cover the new axis rather than assuming the latest fix failed.

The re-invocation is a full, fresh run of this skill. Every step (1-7) executes with its own task tracking and skill invocations. "Scoped to modified files" only affects the diff command passed to `/review-code`. It does not affect which steps run or whether skills are invoked.

Then use the TaskList tool and proceed to any remaining task.

## Rules

- Every step must run in every iteration. `/review-code` covers correctness, security, consistency, API usage, coverage, and simplicity across parallel internal reviewers plus peer review. `/evaluate-findings` is a judgment gate that must run before `/apply-findings`.
- Each step must invoke its designated skill via the Skill tool, not be replaced by inline reasoning or agent calls.
- Re-invocations from Step 7 are full runs with fresh task tracking and complete skill invocations.
