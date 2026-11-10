---
name: review-pr
description: "Review a pull request: run a full code review of its diff, evaluate findings, and implement them. Use when the user asks to \"review PR\", \"review this PR\", or \"check PR before merging\"."
---

# Review PR

Run a comprehensive code review of the PR's diff, evaluate findings, and dispatch accepted findings to implementation.

## Task Tracking

At the start, use `update_plan` to track each step, restating any remaining steps of a parent workflow alongside them:

1. Resolve base branch
2. Run `$review-code` skill
3. Run `$evaluate-findings` skill
4. Run `$implement-findings` skill

## Step 1: Resolve Base Branch

Detect the PR's base branch and the issues it closes via `gh pr view --json baseRefName,closingIssuesReferences`, then run `git fetch origin <base-branch>` to bring the remote ref up to date.

## Step 2: Run `$review-code` Skill

When the PR closes issues, fetch each by its URL with `gh issue view <url> --json title,body,comments`, issuing the calls together. Together, their text is the governing document.

Run the `$review-code` skill. The diff command is `git diff origin/<base-branch>...HEAD`. Take the base from `origin/`: a local branch of the same name can sit behind the remote, which puts the merge base before an already-merged pull request and pulls merged work into the review as if it were new. Supply the governing document when there is one.

## Step 3: Run `$evaluate-findings` Skill

Run the `$evaluate-findings` skill on the results from Step 2.

## Step 4: Run `$implement-findings` Skill

If zero actionable findings survive evaluation, report that the code looks clean and stop.

Otherwise, run the `$implement-findings` skill on the accepted findings from Step 3.
