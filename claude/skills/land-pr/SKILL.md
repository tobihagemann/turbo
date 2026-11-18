---
name: land-pr
description: "Follow a PR to merge: wait for AI reviewers and checks, resolve their feedback, then offer to merge and clean up. Use when the user asks to \"land the PR\", \"follow up on the PR\", or \"merge when ready\"."
---

# Land PR

## Task Tracking

At the start of every invocation, including the re-run from Step 6, use `TaskCreate` to create a task for each step:

1. Identify the pull request
2. Request a human review
3. Wait for reviewers and checks
4. Check context
5. Run `/resolve-pr-feedback` skill
6. Re-run `/land-pr` skill if fixes were pushed
7. Offer the merge
8. Clean up

## Step 1: Identify the Pull Request

Take the pull request from the number or URL provided, otherwise from the current branch: `gh pr view [number] --json number,url,state,headRefName,headRefOid,baseRefName,headRepository,headRepositoryOwner`. Take the owner and repository from its URL, and the head repository's owner and name from `headRepositoryOwner.login` and `headRepository.name`. Take the round from the invocation, `1` when none was provided, and any cases left unverified that were passed along with the pull request.

When TaskList shows a pending task of a `/resolve-pr-feedback` run, that run is already working through the pull request's feedback: mark this invocation's tasks completed, then use the TaskList tool and proceed to any remaining task.

Otherwise mark completed every task an earlier `/land-pr` invocation for this pull request left pending or in progress. Note the checkout root (`git rev-parse --show-toplevel`), the current branch, and whether the checkout is a linked worktree, where `git rev-parse --git-dir` differs from `--git-common-dir`. Use `TaskUpdate` to write the pull request's URL, the round, and the cases left unverified into Step 6's task description; after a compaction, read them back from that task.

- **No pull request, or a closed one that was not merged** — present this message: "No open pull request found for `<branch, number, or URL>`; nothing to land." Mark this invocation's remaining tasks completed, then use the TaskList tool and proceed to any remaining task.
- **Open, but the current branch is not its head branch** — present this message: "PR #`<number>` is on `<headRefName>`; run `/turbo:land-pr` from that branch's checkout." Mark this invocation's remaining tasks completed, then use the TaskList tool and proceed to any remaining task.
- **Merged** — mark Steps 2 through 7 completed and continue with Step 8.
- **Open on the current branch** — continue with Step 2.

## Step 2: Request a Human Review

This skill reads the pull request's state with:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/fetch-pr-status.sh <owner> <repo> <number>
```

Output shape:

```jsonc
{
  "meta":              { "isDraft", "author", "viewer", "headRefOid", "headCommittedDate",
                         "mergeable", "mergeStateStatus", "reviewDecision" },
  "reviewRequests":    [ { "reviewer", "type" } ],  // type: Bot, User, Team, Mannequin, or Unknown
  "reviews":           [ { "author", "authorType", "submittedAt", "hasBody" } ],
  "unresolvedThreads": [ { "author", "lastAuthor", "path" } ],  // author of the first and of the latest comment
  "issueComments":     [ { "author", "createdAt" } ],
  "checks":            [ { "name", "app", "state", "title" } ]  // state: failing, pending, or passing
}
```

`meta.viewer` is the account this session posts as. A review request of `type` `Unknown` names a reviewer this account cannot read, and counts as a human one.

In round 2 and later, skip the rest of this step. In round 1, run the script, and skip the rest of this step when a review request of `type` `User`, `Team`, or `Unknown` is pending, or when `reviews` holds one whose `authorType` is `User`.

Otherwise list the candidates:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/fetch-reviewer-candidates.sh <owner> <repo> <number>
```

It emits `[ { "login", "source", "prs" } ]`: GitHub's suggested reviewers first, then the people who reviewed the repository's recently merged pull requests, most such pull requests first. Skip the rest of this step when it lists no one.

Use `AskUserQuestion` to offer up to the first three candidates, each requesting that person's review, plus **No human review**. Name each candidate's source and pull request count in its description. Mark the first candidate recommended when `reviewDecision` is `REVIEW_REQUIRED`. For the candidate chosen, or each login a freeform answer names, run `gh pr edit <number> --add-reviewer <login>`.

## Step 3: Wait for Reviewers and Checks

Use the Monitor tool with an until-loop that runs the status script every 30 seconds and ends once no check has the `state` `pending` and no review request of `type` `Bot` is pending, or after 20 minutes. When this session pushed the head commit less than 3 minutes before the loop starts, start its first run 3 minutes after that push. Pipe the script's output into `jq` directly or through `printf '%s'`, never `echo`. Treat only a false result as not ready, and end the loop reporting the error when `jq` cannot parse the output or the script fails on three runs in a row.

Then run the script once more and list as text the feedback to resolve:

- Every unresolved review thread whose `lastAuthor` is not `meta.viewer`
- Every check with the `state` `failing`
- Every review with a body, from someone other than `meta.author` and `meta.viewer`, submitted after `meta.headCommittedDate`
- Every conversation comment from someone other than `meta.author` and `meta.viewer`, created after `meta.headCommittedDate`

Leave out a review body or conversation comment that holds no observation, counting any nested inside collapsed blocks, such as a summary reporting no open issues, an acknowledgement of a review command, or a notice that a review was skipped. Read the bodies with `gh pr view <number> --json reviews,comments` to decide.

Also list each check and review request still pending when the loop ended. The step is done once that list, or a statement that nothing awaits resolution, is output.

## Step 4: Check Context

Skip this step when Step 3 listed no feedback to resolve and the user has not asked to compact since the session last compacted.

Call the `mcp__turbo__context-level` tool: a reading of 50% or less remaining is a context signal. A request from the user to compact, arriving since the session last compacted, is the other. When the reading is 50% or less and the user has not asked to compact, use `AskUserQuestion` to ask whether to compact before resolving the feedback: "Handoff, then compact", marked recommended, or keep going in this session.

On "Handoff, then compact", or when the user asked to compact, run the `/handoff` skill, or, when this session already wrote a handoff, edit that file. Point its next step at running `/land-pr` for the pull request's URL, at this round, with the cases left unverified, from the checkout root. Use `TaskUpdate` to set this step's task description to that same next step and leave the task in progress. Then call the `mcp__turbo__compact-and-continue` tool with the handoff's path. End the turn in place of continuing to Step 5, telling the user that the session compacts and continues on its own, and that if it does not, they should run `/compact` and then reply "continue".

## Step 5: Run `/resolve-pr-feedback` Skill

Skip this step when Step 3 listed no feedback to resolve.

Note `meta.headRefOid`. Then run the `/resolve-pr-feedback` skill for the pull request.

## Step 6: Re-run `/land-pr` Skill if Fixes Were Pushed

Read the head commit with `gh pr view <number> --json headRefOid`. When Step 5 was skipped or the head commit is the one Step 5 noted, continue with Step 7. Otherwise:

- **Round 1 or 2** — run the `/land-pr` skill again for the pull request, at the next round, with the cases left unverified.
- **Round 3 or later** — output a summary of what this round fixed and what the reviewers raised. Then use `AskUserQuestion` to offer another round or stopping here. Mark another round recommended when this round's fixes corrected defects, such as wrong behavior, a security exposure, or a failing check, and stopping when they only applied style or wording suggestions.
  - **Another round** — run the `/land-pr` skill again for the pull request, at the next round, with the cases left unverified.
  - **Stop here** — present this message: "Stopped following PR #`<number>` after round `<round>`. The reviewers' response to the latest push is not handled yet; the branch and checkout stay. Run `/turbo:land-pr` from `<checkout root>` to pick up again." Mark this step and Steps 7 and 8 completed, then use the TaskList tool and proceed to any remaining task.

## Step 7: Offer the Merge

Run the status script again. When `mergeable` or `mergeStateStatus` is `UNKNOWN`, use the Monitor tool with an until-loop that runs `gh pr view <number> --json mergeable,mergeStateStatus` every 10 seconds and ends once neither is `UNKNOWN`, or after 1 minute.

Hand the pull request back without merging when any of these holds:

- `isDraft` is true
- A check has the `state` `failing` or `pending`
- `reviewDecision` is `CHANGES_REQUESTED` or `REVIEW_REQUIRED`, or a review request of `type` `User`, `Team`, or `Unknown` is pending
- `mergeable` is `CONFLICTING` or `UNKNOWN`, or `mergeStateStatus` is `BEHIND`, `DIRTY`, `BLOCKED`, or `UNKNOWN`
- The local branch's tip (`git rev-parse HEAD`) is not `headRefOid`, or `git status --porcelain --untracked-files=no` lists changes

To hand it back, present this message: "PR #`<number>` is not ready to merge: `<each reason that holds>`. The branch and checkout stay. Run `/turbo:land-pr` from `<checkout root>` once that clears." Mark this step and Step 8 completed, then use the TaskList tool and proceed to any remaining task.

Otherwise, output the state as text:

- The checks that passed
- The reviewers who reviewed the head commit
- Each `Bot` reviewer whose check, the one whose `app` or `name` matches its login, reports in its `title` that it skipped the head commit, as on a rate limit
- Each review request of `type` `Bot` still pending
- Each unresolved thread, with its author and path
- Each case left unverified

Resolve the merge methods the repository allows with `gh repo view --json squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed`. Run `git fetch origin <baseRefName>` and sample the base branch's history with `git log --first-parent origin/<baseRefName> -n 30 --pretty=%s`: `(#N)`-suffixed subjects point to squash, and merge-PR commits to a merge commit.

Use `AskUserQuestion` to offer one option per allowed method, each merging the pull request and deleting its branch along with any worktree it is checked out in, plus **Don't merge yet**. List first, labeled `(Recommended)`, the allowed method the history points to, or, when it points to none that is allowed, the first allowed one of squash, merge commit, and rebase.

On a merge method, run `gh pr merge <number> --<squash|merge|rebase> --match-head-commit <headRefOid>`, then read the state with `gh pr view <number> --json state`. When it is not `MERGED`, because a merge queue or auto-merge took the pull request or the command failed, hand the pull request back as above with what `gh` reported.

On **Don't merge yet**, hand the pull request back as above, with the user's choice as the reason.

## Step 8: Clean Up

Read the head branch's tip on GitHub with `gh api repos/<head owner>/<head repository>/git/ref/heads/<headRefName> --jq .object.sha`. When it is the pull request's `headRefOid`, delete the branch with `gh api -X DELETE repos/<head owner>/<head repository>/git/refs/heads/<headRefName>`. When the read finds no branch, skip the deletion. When its tip differs, keep it and report that it moved past the merged head. Then run `git fetch --prune`.

Then take the case that matches where Step 1 found this session:

- **On another branch** — leave the checkout as it is.
- **In a linked worktree on the head branch** — leave with the ExitWorktree tool (`action: "keep"`). When it reports that no worktree session is active, present the worktree's path and the commands that finish the cleanup from the main checkout: fast-forward the main checkout's local `<baseRefName>` to `origin/<baseRefName>`, run `git worktree remove <path>`, and run `git branch -D <headRefName>` when the local branch's tip is `headRefOid`. Skip the local branch deletion below. Otherwise:
  1. Fast-forward the main checkout's local `<baseRefName>` branch to `origin/<baseRefName>` without switching the branch the main checkout has checked out. When the fast-forward fails, report it and leave that branch as it is.
  2. Remove the worktree with `git worktree remove <path>`. When git refuses over files this session copied in from the main checkout, delete those copies and remove it again. Otherwise keep the worktree, without `--force`.
  3. Run the `/backlog` skill for each entry `/backlog` could not persist from the worktree.
- **In the main checkout on the head branch** — when `git status --porcelain --untracked-files=no` lists changes, report them, keep the branch checked out, and skip the local branch deletion below. Otherwise run `git switch <baseRefName>` and `git merge --ff-only origin/<baseRefName>`.

When the local branch exists and its tip is the pull request's `headRefOid`, delete it with `git branch -D <headRefName>`, keeping it when git refuses. When its tip differs, keep it and report the commits it holds beyond the merged head (`git log --oneline <headRefOid>..<headRefName>`).

Report what was merged, removed, and kept.

Then use the TaskList tool and proceed to any remaining task.
