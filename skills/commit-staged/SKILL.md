---
name: commit-staged
description: "Commit already-staged changes with a message matching existing commit style, including validation that changes are actually staged. Use when the user asks to \"commit staged changes\", \"commit what's staged\", \"commit the staged files\", \"make a commit\", or \"commit this\"."
---

# Commit Staged Changes

## Step 1: Validate Staged Changes

Run `git diff --cached --stat` to confirm changes are staged. If nothing is staged, inform the user and stop — do not create an empty commit.

## Step 2: Commit Rules

Run `/commit-rules` to load commit message rules and technical constraints.

## Step 3: Compose and Execute Commit

- Do not stage any additional files — only commit what is already staged
- Review the staged diff to write an accurate commit message
- If the commit fails due to a pre-commit hook, read the hook output, fix the issue, re-stage, and retry
- If commit signing fails, use `AskUserQuestion` to let the user resolve it

## Step 4: Verify

Run `git log -1 --oneline` to confirm the commit was created successfully.
