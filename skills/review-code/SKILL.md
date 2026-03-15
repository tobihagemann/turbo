---
name: review-code
description: "Full code review pipeline: launches `/code-review`, `/security-review`, and `/peer-review` in parallel, evaluates findings, applies fixes, simplifies, and verifies with tests. Use when the user asks to \"review and fix my code\", \"full code review\", \"review my changes\", or wants an end-to-end review with fixes applied."
---

# Review Code

Run AI code review, evaluate findings, apply fixes, and verify.

## Step 1: Determine the Diff Target

Determine what to review based on context:

- **Uncommitted changes**: `--uncommitted`
- **Against a base branch**: `--base <branch>`
- **Specific commit**: `--commit <sha>`

Default to reviewing against the repository's default branch (detect via `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`). If the caller specifies a different target, use that.

## Step 2: Run Three Reviews in Parallel

The diff target from Step 1 determines what each reviewer analyzes.

### Review A: Code Review

Launch a background agent (`model: "opus"`, `run_in_background: true`) that runs the `/code-review` skill with the diff target from Step 1.

### Review B: Security Review

Launch a background agent (`model: "opus"`, `run_in_background: true`) that runs the `/security-review` skill with the diff target from Step 1.

### Review C: Peer Review

Run the `/peer-review` skill directly (via the Skill tool) with the same diff target. This runs in the main thread while Reviews A and B work in the background.

## Step 3: Evaluate Findings

Combine findings from all three reviewers and run the `/evaluate-findings` skill on the merged set.

If there are additional findings to include (e.g., PR comments passed in by the caller), combine them before evaluation.

If zero actionable findings survive evaluation, report that the code looks clean and stop.

## Step 4: Apply Fixes

Run the diff command to get the current changes, then apply each actionable finding directly, skipping false positives. Only edit files — do not stage, build, or test.

## Step 5: Simplify Fixes

Run the `/simplify-code` skill. The diff command is `git diff` (the fixes are unstaged).

## Step 6: Test and Lint

1. Run the test suite to confirm nothing broke
2. If tests fail, run the `/investigate` skill to diagnose the root cause, apply the suggested fix, and re-run tests. If investigation cannot identify a root cause, stop and report with investigation findings.
3. Run the project's linter/formatter to ensure clean output

## Rules

- If any reviewer is unavailable or returns malformed output, proceed with findings from the remaining reviewers.
- Process findings in file order to minimize context switching.
