---
name: review-code
description: Run AI code review, evaluate findings, apply fixes, and verify. Launches a review subagent and `/peer-review` in parallel, then evaluates and applies actionable findings. Use when the user asks to "review code", "code review", "review my changes", "find bugs in my changes", or wants a reviewed and evaluated set of findings.
---

# Review Code

Run AI code review, evaluate findings, apply fixes, and verify.

## Step 1: Determine the Diff Target

Determine what to review based on context:

- **Uncommitted changes**: `--uncommitted`
- **Against a base branch**: `--base <branch>`
- **Specific commit**: `--commit <sha>`

Default to reviewing against the repository's default branch (detect via `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`). If the caller specifies a different target, use that.

## Step 2: Launch Two Reviews in Parallel

Use the Agent tool to launch both reviews concurrently in a single message. Every Agent tool call must set `model: "opus"`. The diff target from Step 1 determines what each reviewer analyzes.

### Review A: Review Subagent

Instruct the agent to:

1. Run the appropriate diff command itself to obtain the changes
2. Read [references/review-prompt.md](references/review-prompt.md) for review guidelines
3. For each changed file, read enough surrounding context to understand the change
4. Return findings following the format in the review prompt

### Review B: Peer Review

Launch an agent that runs the `/peer-review` skill with the same diff target and captures the full review output.

## Step 3: Evaluate Findings

Combine findings from both reviewers and run the `/evaluate-findings` skill on the merged set.

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

- If either reviewer is unavailable or returns malformed output, proceed with findings from the other reviewer alone.
- Process findings in file order to minimize context switching.
