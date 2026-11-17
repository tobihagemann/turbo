---
name: ship
description: "Commit, push, and optionally create or update a PR for the current staged changes. Use when the user asks to \"ship\", \"ship it\", \"ship changes\", \"commit push and PR\", or \"ship this\"."
---

# Ship

Commit, push, and optionally create or update a PR for the current staged changes.

## Task Tracking

At the start, use `TaskCreate` to create a task for each phase:

1. Determine intent
2. Branch (if needed)
3. Stage unstaged changes
4. Run `/commit-rules` skill
5. Commit
6. Update PR (if requested)
7. Push (if requested)
8. Create PR (if requested)
9. Link changelog entries to the PR (if needed)

## Step 1: Determine Intent

Detect the repository state:

- Default branch: `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`
- Current branch name, and whether it tracks an upstream
- Whether an open PR exists for the current branch (`gh pr view --json state`); a closed or merged one counts as none

Sample the prevailing workflow from recent default-branch history (`git log --first-parent origin/<default-branch> -n 30 --pretty=%s`): judge whether changes mostly land through pull requests (merge-PR commits or `(#N)`-suffixed squash commits) or are committed directly to the default branch.

Output a one-line summary of the detected state as text. Then use `AskUserQuestion` to choose how to proceed, offering these options:

- **Commit, push, and create/update the PR** — say "create a PR" when no open PR exists for the current branch and "update the PR" when one does; on the default branch, Step 2 creates a feature branch first
- **Commit and push** — commit, then push to the current branch's remote
- **Commit only** — commit the staged changes, do not push

Inside a linked worktree (where `git rev-parse --git-dir` differs from `--git-common-dir`), on a branch with no upstream and in a direct-commit history, offer **Commit and push to `<default-branch>`** in place of **Commit and push**: commit, rebase onto `origin/<default-branch>`, and push to `<default-branch>`.

Recommend the option that fits this repo by listing it first and labeling it `(Recommended)`: when the current branch already has an open PR, recommend updating it; otherwise follow the prevailing workflow — recommend the PR path for a PR-based history, or commit and push for a direct-commit history.

If the user declines (chooses the free-form "Other" option or asks to abort), leave the changes staged and do not commit.

## Step 2: Branch (if Needed)

If the chosen option creates a PR and the current branch is the default branch:

1. Suggest a branch name based on the changes and use `AskUserQuestion` to confirm or adjust
2. Create and switch to the new branch: `git checkout -b <branch-name>`

## Step 3: Check for Unstaged Changes

Run `git status` to check for unstaged changes. Stage by path the files that belong to the current changeset; this catches files modified by auto-formatters that were not re-staged. When one also carries unrelated changes, write `git diff <file>` to a patch file, back the unrelated changes out of it (delete their `+` lines and turn their `-` lines into context lines), and stage it with `git apply --cached --recount <patch>`.

## Step 4: Run `/commit-rules` Skill

Run the `/commit-rules` skill to load commit message rules and technical constraints.

## Step 5: Commit

Commit the already-staged changes (do not stage additional files) with a message following the loaded rules. Keep the branch Step 2 left in place and commit on it, including when that is the default branch.

If the commit fails due to a pre-commit hook (formatter, linter), fix the issues — or run the project's format/lint script to auto-fix — then **re-stage by path the files the hook modified** before retrying. Fix them in the code and leave the hook's checks as strict as they were: disabling or downgrading a rule, widening an exclude list, or bypassing the hook fixes nothing. When a hook's check is wrong for the code, stop and report it with the evidence. Pre-commit hooks may modify files in the working tree without updating the staging area.

## Step 6: Update PR (if Requested)

If the chosen option updates the PR, run the `/pr` skill.

## Step 7: Push (if Requested)

If the chosen option is **Commit and push to `<default-branch>`**, run `git fetch origin <default-branch>`, then `git rebase --autostash origin/<default-branch>`. When the rebase stops on a conflict, leave it stopped and use `AskUserQuestion` to offer resolving the conflict and continuing with `git rebase --continue`, or aborting with `git rebase --abort` and keeping the commits on the branch unpushed. When `git status --short` lists unmerged paths after the rebase, restoring the autostash conflicted: report those paths and the stash entry that holds the changes, and leave the commits unpushed. Otherwise push with `git push origin HEAD:<default-branch>`. When the push is rejected because the default branch moved, repeat the fetch, rebase, and push, at most twice, then report the rejection and keep the commits unpushed.

Otherwise, if the chosen option includes pushing, push to the current branch's remote:

```bash
git push
```

For a branch with no upstream, push with `git push -u origin <branch>`. When git reports that it could not write the upstream branch configuration, confirm the push landed with `git rev-parse --verify --quiet refs/remotes/origin/<branch>`, then run `git branch --set-upstream-to=origin/<branch>` via the Bash tool (`dangerouslyDisableSandbox: true`).

## Step 8: Create PR (if Requested)

If the chosen option creates a PR, run the `/pr` skill.

When `/pr` hands the body file over for editing instead of posting, report that path and that no PR was opened yet, and leave Step 9 pending until the PR is posted or cancelled.

## Step 9: Link Changelog Entries to the PR (if Needed)

When Step 8 opened a PR, including one posted after the user edited its body, and this branch added Unreleased changelog entries that carry no PR reference while the changelog's earlier entries carry one, run the `/changelog-rules` skill and add to each of those entries the references it calls for with the new PR. Stage the changelog by path and commit it with a message following the commit rules Step 4 loaded, handling a pre-commit hook as Step 5 does, then push to the current branch's remote.

Then use the TaskList tool and proceed to any remaining task.

## Rules

- Run the `/commit-rules` skill before every commit; do not commit without loading it first.
- Never stage or commit files containing secrets (`.env`, credentials, API keys). Warn if detected.
- Don't reference `.turbo/` content (filenames, acceptance criteria, step numbers, headings) in branch names. `.turbo/` is gitignored, so these references would be opaque to anyone reading without local copies.
