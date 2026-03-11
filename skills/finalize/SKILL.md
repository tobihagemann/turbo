---
name: finalize
description: Run the post-implementation quality assurance workflow including tests, code simplification, review, and commit. Use when the user asks to "finalize implementation", "finalize changes", "wrap up implementation", "finish up", "ready to commit", "run QA workflow", or "ship it".
---

# Finalize Implementation

Post-implementation QA workflow: staging, tests, code simplification, AI review, commit, and self-improvement.

## Task Tracking

At the start, use `TaskCreate` to create a task for each phase:

1. Stage and test
2. Simplify code
3. Code review
4. Self-improve
5. Commit
6. Pull request

## Phase 1: Stage and Test

### Step 1: Stage implementation changes

Stage only the files changed during this implementation:

```bash
git add <file1> <file2> ...
```

Do not use `git add -A` or `git add .`. If a file contains both implementation changes and unrelated changes, use `git add -p <file>` to stage only the relevant hunks. Use `git status` and `git diff --cached` to verify the staging area contains exactly the intended changes.

### Step 2: Write missing tests

Determine whether new tests are needed:

1. Run `git diff --cached --name-only` to identify staged files
2. Skip this step if changes are non-testable (config, documentation, CI files, SKILL.md files, markdown) or adequate tests already cover the modified code
3. Search for existing test files covering the modified code using Glob and Grep

If tests are needed:

1. Identify the project's test framework and conventions by reading existing test files
2. Write focused unit or integration tests for the new or changed behavior
3. Run the test suite to confirm all tests pass
4. If tests fail, run the `/investigate` skill to diagnose the root cause, then apply the suggested fix and re-run tests. If investigation cannot identify a root cause after its full cycle, stop and report with investigation findings.
5. Stage the new test files

## Phase 2: Simplify Code

Run the `/simplify-plus` skill. The diff command for this phase is `git diff --cached`.

## Phase 3: Code Review

### Step 1: Run code review

Run the `/code-review` skill to review uncommitted changes. Apply any actionable findings — launch a single opus agent with the full diff to apply each fix.

### Step 2: Simplify review fixes

Run the `/simplify-plus` skill. The diff command for this phase is `git diff` (NOT `git diff --cached` — the fix agent's changes are unstaged).

### Step 3: Test and lint

1. Run the test suite to confirm nothing broke
2. If tests fail, run the `/investigate` skill to diagnose the root cause, apply the suggested fix, and re-run tests. If investigation cannot identify a root cause, stop and report with investigation findings.
3. Run the project's linter/formatter to ensure clean output

## Phase 4: Self-Improve

Run the `/self-improve` skill.

## Phase 5: Commit

Use `AskUserQuestion` to confirm readiness to commit.

- **Approve** — run the `/commit-staged` skill (it handles commit message formulation)
- **Abort** — leave changes staged, do not commit

## Phase 6: Pull Request

### Step 1: Push and create or update PR

Check if a PR exists for the current branch using `gh pr view`.

- **PR exists** — push new commits and run the `/update-pr` skill
- **No PR exists** — use `AskUserQuestion` to ask if a PR should be created
  - **Yes** — push the branch and run the `/create-pr` skill
  - **No** — push the branch and end the workflow

### Step 2: Resolve PR comments

Use `AskUserQuestion` to ask if the user wants to wait for automated reviewers to finish and resolve comments.

- **Skip** — end the workflow
- **Resolve comments** — run the `/resolve-pr-comments` skill

## Rules

- Never stage or commit files containing secrets (`.env`, credentials, API keys). Warn if detected.
- Do not present diffs to the user — the user reviews diffs in an external git client. Use `git diff` internally as needed.
- If a non-test step fails (simplifier, review), stop and report the failure. Do not skip ahead.
