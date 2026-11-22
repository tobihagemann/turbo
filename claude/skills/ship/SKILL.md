---
name: ship
description: "Group the changes for review and ship them together or, with approval, separately. Use when the user asks to \"ship\", \"ship it\", \"ship changes\", \"commit push and PR\", or \"ship this\"."
---

# Ship

## Task Tracking

At the start, use `TaskCreate` to create a task for each step:

1. Choose how to group the changes
2. Prepare an approved split
3. Run the selected shipping skill

## Step 1: Choose How to Group the Changes

Read `git status --short` and `git diff --cached`. Include relevant unstaged edits and untracked files in the analysis, inspecting their contents so the groups cover what will actually ship. Respect any scope the user set, including a request to ship only staged changes. If the scope is empty, report that there is nothing to ship, close this run’s tasks, then use the TaskList tool and proceed to any remaining task.

Group changes by what someone can understand, test, and revert together. A feature and its tests can form one unit across several directories.

For one cohesive unit, briefly identify it and select `/ship-together`. Honor an explicit choice to ship together or an already approved split.

For several units, propose an ordered list with each group's purpose, files, any shared-file hunks, and dependencies. Use `AskUserQuestion` to offer **Split up** and **Ship together**, putting the recommended choice first. When the grouping is uncertain or costly to reverse, also offer **Get a second opinion**. On that choice, run the `/consult-codex` skill on the proposed grouping, then settle the choice with the user. Leave the route pending until the user chooses.

## Step 2: Prepare an Approved Split

For a split only, compare the full staged diff with the approved groups, including hunks in shared files. If unrelated edits are already staged, leave the index intact and pause for the user to resolve the mismatch. Run the `/stage` skill for only the approved paths and hunks still missing. Verify the full staged diff again. Correct any over-staging from this step while preserving pre-existing staged edits and working-tree content. Proceed only when the index contains exactly the approved changes.

## Step 3: Run the Selected Shipping Skill

- **Ship together** — run the `/ship-together` skill with the identified scope.
- **Split up** — run the `/split-and-ship` skill with the approved, ordered group list.

The selected skill owns the commit, push, branch, and PR decisions. Carry its outcome forward, including any pending PR or unshipped group.

Then use the TaskList tool and proceed to any remaining task.
