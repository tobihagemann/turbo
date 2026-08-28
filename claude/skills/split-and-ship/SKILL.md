---
name: split-and-ship
description: "Execute an approved split plan, shipping each change group separately as its own branch and PR or as sequential commits on the current branch. Use when the user asks to \"split and ship\", \"ship the split plan\", \"create separate PRs\", or \"split changes into branches\"."
---

# Split and Ship

Ship an approved split plan so each change group becomes its own reviewable unit, either as a separate branch and PR or as a sequential commit on the current branch.

## Context

A split plan must exist in the conversation. The plan specifies an ordered list of groups, each with a name, file list, and any dependencies on earlier groups.

## Task Tracking

At the start, use `TaskCreate` to create a task for each phase:

1. Choose realization path
2. Ship the groups
3. Summarize

## Step 1: Choose Realization Path

Detect the repository state:

- Default branch: `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`
- Current branch name, and whether it tracks an upstream
- Whether a PR already exists for the current branch (`gh pr view`)

Sample the prevailing workflow from recent default-branch history (`git log --first-parent origin/<default-branch> -n 30 --pretty=%s`): judge whether changes mostly land through pull requests (merge-PR commits or `(#N)`-suffixed squash commits) or are committed directly to the default branch.

Output a one-line summary of the detected state as text. Then use `AskUserQuestion` to choose how to ship the groups:

- **Separate branches and PRs** — one branch and PR per group (Step 2)
- **Commit each group and push** — one commit per group on the current branch, then push (Step 3)
- **Commit each group only** — one commit per group on the current branch, no push (Step 3)

Recommend the option that fits this repo by listing it first and labeling it `(Recommended)`: a PR-based history recommends separate branches and PRs; a direct-commit history recommends committing each group on the current branch.

If the user declines (chooses the free-form "Other" option or asks to abort), leave the changes staged and do not commit.

## Step 2: Ship as Separate Branches and PRs

Take this step only when the user chose separate branches and PRs.

### Prepare the working tree

1. Save all staged changes, then unstage everything (`git reset`)
2. Stash all changes including untracked files (`git stash --include-untracked`) so files can be selectively restored per group

Verify `git stash list` shows the saved changes before proceeding.

### Ship each group

Use `TaskCreate` to create a task for each group. Process groups in order.

For each group:

1. **Determine branch**: If the current branch already has a PR and this group's changes align with the PR's purpose, stay on the current branch. Otherwise, use `AskUserQuestion` to confirm the proposed branch name and create it from the appropriate base:
   - Group that builds on an earlier group: branch from that group's branch (stacked)
   - Group with no dependencies: branch from the default branch (independent)
2. **Restore and stage** this group's files from the stash (`git checkout stash -- <files>` restores and stages in one operation). For files with hunks belonging to different groups, restore the file, then use Edit to remove the unwanted hunks before staging: for an independent group, remove every other group's hunks; for a stacked group, remove only later groups' hunks (earlier groups' hunks are already in its base). After committing, reset the working tree (`git checkout -- .`) to clean up before the next group.
3. **Commit and push**: run the `/commit-rules` skill to load commit message rules, commit the staged changes following them, then `git push`
4. **Create or update PR**:
   - Staying on existing branch with a PR: run the `/update-pr` skill
   - New branch: run the `/create-pr` skill targeting the appropriate base (default branch for independent groups, previous group's branch for stacked groups)

### Clean up and summarize

1. Drop the stash
2. Check out the last created branch
3. Output a summary table: group name, branch, PR URL, and base branch. For a group whose PR was not posted, print the handed-over body file path in place of the URL.

Then use the TaskList tool and proceed to any remaining task.

## Step 3: Ship as Commits on the Current Branch

Take this step only when the user chose to commit each group. This path stays on the current branch and creates no branches or PRs.

### Prepare the working tree

1. Save all staged changes, then unstage everything (`git reset`)
2. Stash all changes including untracked files (`git stash --include-untracked`) so files can be selectively restored per group

Verify `git stash list` shows the saved changes before proceeding.

### Commit each group

Run the `/commit-rules` skill to load commit message rules. Use `TaskCreate` to create a task for each group. Process groups in order.

For each group:

1. **Restore and stage** this group's files from the stash (`git checkout stash -- <files>` restores and stages in one operation). For files with hunks belonging to different groups, restore the file, then use Edit to remove the hunks that belong to later groups before staging.
2. **Commit** the staged changes with a message following the loaded rules. If a commit hook modifies files, re-stage them before retrying.
3. Reset the working tree (`git checkout -- .`) to clean up before the next group.

### Push and summarize

1. If the chosen option includes pushing, push the current branch's remote (`git push`)
2. Drop the stash
3. Output a summary table: group name and commit subject

Then use the TaskList tool and proceed to any remaining task.

## Rules

- Run the `/commit-rules` skill before every commit; do not commit without loading it first.
- Never lose uncommitted work. Both paths stash all changes before shipping. Before dropping the stash, restore and report any stashed file that no group shipped, rather than discarding it. If any step fails (commit hook, push, PR creation), stop and report the failure, which groups have been shipped, and that the stash still contains all changes for recovery. A group whose PR was handed over for editing rather than posted is not a failure; record it in the summary and continue.
- Stacked PRs target the previous group's branch. Independent PRs target the default branch.
- For stacked groups, the PR description should note the dependency chain.
- Don't reference `.turbo/` content (filenames, acceptance criteria, step numbers, headings) in branch names. `.turbo/` is gitignored, so these references would be opaque to anyone reading without local copies.
