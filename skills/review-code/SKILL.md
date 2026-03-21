---
name: review-code
description: "Full code review pipeline: launches `/code-review`, `/peer-review`, `/security-review`, and `/api-usage-review` in parallel, evaluates findings, and returns actionable results. Use when the user asks to \"review my code\", \"full code review\", \"review my changes\", or wants a comprehensive code review."
---

# Review Code

Run AI code review and evaluate findings.

## Step 1: Determine the Diff

Determine the appropriate diff command (e.g. `git diff --cached`, `git diff main...HEAD`) based on the current git state. If a specific diff command was provided, use that. Otherwise, default to diffing against the repository's default branch (detect via `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`).

## Step 2: Run Four Reviews in Parallel

Launch all four reviews in a single message so they run concurrently. The diff command from Step 1 determines what each reviewer analyzes.

### Review A: Code Review

Launch an agent (`model: "opus"`, do not set `run_in_background`) that runs the `/code-review` skill with the diff command from Step 1.

### Review B: Peer Review

Launch an agent (`model: "opus"`, do not set `run_in_background`) that runs the `/peer-review` skill with the diff command from Step 1.

### Review C: Security Review

Launch an agent (`model: "opus"`, do not set `run_in_background`) that runs the `/security-review` skill with the diff command from Step 1.

### Review D: API Usage Review

Launch an agent (`model: "opus"`, do not set `run_in_background`) that runs the `/api-usage-review` skill with the diff command from Step 1.

## Step 3: Evaluate Findings

Run the `/evaluate-findings` skill.

If zero actionable findings survive evaluation, report that the code looks clean and stop.

## Rules

- If any reviewer is unavailable or returns malformed output, proceed with findings from the remaining reviewers.
- Present findings in file order to minimize context switching.
