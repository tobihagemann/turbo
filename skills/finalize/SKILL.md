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
5. Commit and PR

## Phase 1: Stage and Test

### Step 1: Stage Implementation Changes

Run the `/stage` skill.

### Step 2: Write Missing Tests

Run the `/write-tests` skill for staged changes (`git diff --cached`).

### Step 3: Stage Test Files

Stage any new test files created in Step 2.

## Phase 2: Simplify Code

Run the `/simplify-code` skill. The diff command for this phase is `git diff --cached`.

Reviews and fixes code style and structure: reuse opportunities, quality patterns, efficiency, and clarity. Uses multiple Claude agents scanning the diff in parallel. Does not catch correctness or logic bugs.

Stage any changes made by the simplifier.

## Phase 3: Code Review

Run the `/review-code` skill to review uncommitted changes.

Reviews and fixes correctness and logic bugs: missing guards, security issues, incorrect conditions, unhandled edge cases. Uses a different reviewer than Phase 2 and catches different problems. Always run this phase even if Phase 2 found nothing.

Stage any changes made by the reviewer.

## Phase 4: Self-Improve

Run the `/self-improve` skill.

## Phase 5: Commit and PR

### Step 1: Determine Intent

Detect the repository's default branch via `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`. Check the current branch name and whether a PR already exists for it using `gh pr view`.

Use `AskUserQuestion` to ask the user how to proceed. Present the options based on the current state:

- **On a feature branch with an existing PR** — commit and push; or commit, push, and update the PR; or commit only
- **On a feature branch without a PR** — commit and push; or commit, push, and create a PR; or commit only
- **On the default branch** — commit and push; or create a feature branch, commit, push, and create a PR; or commit only
- **Abort** — leave changes staged, do not commit

### Step 2: Branch (if Needed)

If the user wants a PR and the current branch is the default branch:

1. Suggest a branch name based on the changes and use `AskUserQuestion` to confirm or adjust
2. Create and switch to the new branch: `git checkout -b <branch-name>`

### Step 3: Commit

Run the `/commit-staged` skill.

### Step 4: Push and Create or Update PR (if Requested)

- **Push only** — push (do not create or update a PR)
- **Create PR** — push with `-u` and run the `/create-pr` skill
- **Update PR** — push and run the `/update-pr` skill
- **Skip** — end the workflow (do not push)

### Step 5: Resolve PR Comments

Use `AskUserQuestion` to ask if the user wants to wait for automated reviewers to finish and resolve comments.

- **Skip** — end the workflow
- **Resolve comments** — run the `/resolve-pr-comments` skill

## Rules

- Never stage or commit files containing secrets (`.env`, credentials, API keys). Warn if detected.
- Do not present diffs to the user — the user reviews diffs in an external git client. Use `git diff` internally as needed.
- If a non-test step fails (simplifier, review), stop and report the failure. Do not skip ahead.
