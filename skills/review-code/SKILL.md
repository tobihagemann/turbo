---
name: review-code
description: Run AI code review, evaluate findings, apply fixes, and verify. Delegates to `/peer-review` for the review and `/evaluate-findings` for triage. Use when the user asks to "review code", "code review", "review my changes", or wants a reviewed and evaluated set of findings.
---

# Review Code

Run AI code review, evaluate findings, apply fixes, and verify.

## Step 1: Peer Review

Run the `/peer-review` skill. Pass the appropriate context:

- **Uncommitted changes**: `--uncommitted`
- **Against a base branch**: `--base <branch>`
- **Specific commit**: `--commit <sha>`

Default to reviewing against the repository's default branch (detect via `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`). If the caller specifies a different base, use that.

Capture the full review output.

## Step 2: Evaluate Findings

Run the `/evaluate-findings` skill on the review output.

If there are additional findings to include (e.g., PR comments passed in by the caller), combine them with the review output before evaluation.

If zero actionable findings survive evaluation, report that the code looks clean and stop.

## Step 3: Apply Fixes

Launch a single opus agent with the full diff to apply each actionable finding.

## Step 4: Simplify Fixes

Run the `/simplify-code` skill. The diff command is `git diff` (the fix agent's changes are unstaged).

## Step 5: Test and Lint

1. Run the test suite to confirm nothing broke
2. If tests fail, run the `/investigate` skill to diagnose the root cause, apply the suggested fix, and re-run tests. If investigation cannot identify a root cause, stop and report with investigation findings.
3. Run the project's linter/formatter to ensure clean output

## Rules

- If the peer review tool is not available or returns malformed output, report the error and stop.
- Process findings in file order to minimize context switching.
