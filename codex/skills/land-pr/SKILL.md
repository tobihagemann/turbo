---
name: land-pr
description: "Follow a PR to merge: wait for AI reviewers and checks, resolve their feedback, then offer to merge and clean up. Use when the user asks to \"land the PR\", \"follow up on the PR\", or \"merge when ready\"."
---

# Land PR

## Task Tracking

At the start of every invocation, including the re-run from Step 5, use `update_plan` to track each step, restating any remaining steps of a parent workflow alongside them and leaving out the steps an earlier `$land-pr` invocation for this pull request left, which this invocation replaces:

1. Identify the pull request
2. Request a human review
3. Wait for reviewers and checks
4. Run `$resolve-pr-feedback` skill
5. Re-run `$land-pr` skill if fixes were pushed (round `<round>`, `<pull request URL>`)
6. Offer the merge
7. Clean up

Fill in Step 5's label once Step 1 resolves the pull request. A workflow file that mirrors this plan carries the round and the pull request through a compaction.

## Step 1: Identify the Pull Request

Take the pull request from the number or URL provided, otherwise from the current branch: `gh pr view [number] --json number,url,state,headRefName,headRefOid,baseRefName,headRepository,headRepositoryOwner`. Take the owner and repository from its URL, and the head repository's owner and name from `headRepositoryOwner.login` and `headRepository.name`. Take the round from the invocation, `1` when none was provided, and any cases left unverified that were passed along with the pull request. Resolve the absolute path of this skill's directory, the directory of the `SKILL.md` loaded for this run, and use it as `<this skill's directory>` below.

When the active plan holds a pending step of a `$resolve-pr-feedback` run, that run is already working through the pull request's feedback: call `update_plan` to mark this invocation's steps completed and continue with the next step of the active workflow.

Otherwise note the checkout root (`git rev-parse --show-toplevel`), the current branch, and whether the checkout is a linked worktree, where `git rev-parse --git-dir` differs from `--git-common-dir`.

- **No pull request, or a closed one that was not merged** — present this message: "No open pull request found for `<branch, number, or URL>`; nothing to land." Then call `update_plan` to mark this invocation's steps completed and continue with the next step of the active workflow.
- **Open, but the current branch is not its head branch** — present this message: "PR #`<number>` is on `<headRefName>`; run `$turbo:land-pr` from that branch's checkout." Then call `update_plan` to mark this invocation's steps completed and continue with the next step of the active workflow.
- **Merged** — mark Steps 2 through 6 completed and continue with Step 7.
- **Open on the current branch** — continue with Step 2.

## Step 2: Request a Human Review

This skill reads the pull request's state with:

```bash
bash <this skill's directory>/scripts/fetch-pr-status.sh <owner> <repo> <number>
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
bash <this skill's directory>/scripts/fetch-reviewer-candidates.sh <owner> <repo> <number>
```

It emits `[ { "login", "source", "prs" } ]`: GitHub's suggested reviewers first, then the people who reviewed the repository's recently merged pull requests, most such pull requests first. Skip the rest of this step when it lists no one.

Use `request_user_input` to offer up to the first two candidates, each requesting that person's review, plus **No human review**. Name each candidate's source and pull request count in its description, and name any further candidates in the question as available through a freeform answer. Mark the first candidate recommended when `reviewDecision` is `REVIEW_REQUIRED`. For the candidate chosen, or each login a freeform answer names, run `gh pr edit <number> --add-reviewer <login>`.

## Step 3: Wait for Reviewers and Checks

Run the status script every 30 seconds in a shell loop that ends once no check has the `state` `pending` and no review request of `type` `Bot` is pending, or after 20 minutes. When this session pushed the head commit less than 3 minutes before the loop starts, start its first run 3 minutes after that push. Pipe the script's output into `jq` directly or through `printf '%s'`, never `echo`. Treat only a false result as not ready, and end the loop reporting the error when `jq` cannot parse the output or the script fails on three runs in a row.

Then run the script once more and list as text the feedback to resolve:

- Every unresolved review thread whose `lastAuthor` is not `meta.viewer`
- Every check with the `state` `failing`
- Every review with a body, from someone other than `meta.author` and `meta.viewer`, submitted after `meta.headCommittedDate`
- Every conversation comment from someone other than `meta.author` and `meta.viewer`, created after `meta.headCommittedDate`

Leave out a review body or conversation comment that holds no observation, counting any nested inside collapsed blocks, such as a summary reporting no open issues, an acknowledgement of a review command, or a notice that a review was skipped. Read the bodies with `gh pr view <number> --json reviews,comments` to decide.

Also list each check and review request still pending when the loop ended. The step is done once that list, or a statement that nothing awaits resolution, is output.

## Step 4: Run `$resolve-pr-feedback` Skill

Skip this step when Step 3 listed no feedback to resolve.

Note `meta.headRefOid`. Then run the `$resolve-pr-feedback` skill for the pull request.

## Step 5: Re-run `$land-pr` Skill if Fixes Were Pushed

Read the head commit with `gh pr view <number> --json headRefOid`. When Step 4 was skipped or the head commit is the one Step 4 noted, continue with Step 6. Otherwise:

- **Round 1 or 2** — run the `$land-pr` skill again for the pull request, at the next round, with the cases left unverified.
- **Round 3 or later** — output a summary of what this round fixed and what the reviewers raised. Then use `request_user_input` to offer another round or stopping here. Mark another round recommended when this round's fixes corrected defects, such as wrong behavior, a security exposure, or a failing check, and stopping when they only applied style or wording suggestions.
  - **Another round** — run the `$land-pr` skill again for the pull request, at the next round, with the cases left unverified.
  - **Stop here** — present this message: "Stopped following PR #`<number>` after round `<round>`. The reviewers' response to the latest push is not handled yet; the branch and checkout stay. Run `$turbo:land-pr` from `<checkout root>` to pick up again." Then call `update_plan` to mark this step and Steps 6 and 7 completed and continue with the next step of the active workflow.

## Step 6: Offer the Merge

Run the status script again. When `mergeable` or `mergeStateStatus` is `UNKNOWN`, run `gh pr view <number> --json mergeable,mergeStateStatus` every 10 seconds in a shell loop that ends once neither is `UNKNOWN`, or after 1 minute.

Hand the pull request back without merging when any of these holds:

- `isDraft` is true
- A check has the `state` `failing` or `pending`
- `reviewDecision` is `CHANGES_REQUESTED` or `REVIEW_REQUIRED`, or a review request of `type` `User`, `Team`, or `Unknown` is pending
- `mergeable` is `CONFLICTING` or `UNKNOWN`, or `mergeStateStatus` is `BEHIND`, `DIRTY`, `BLOCKED`, or `UNKNOWN`
- The local branch's tip (`git rev-parse HEAD`) is not `headRefOid`, or `git status --porcelain --untracked-files=no` lists changes

To hand it back, present this message: "PR #`<number>` is not ready to merge: `<each reason that holds>`. The branch and checkout stay. Run `$turbo:land-pr` from `<checkout root>` once that clears." Then call `update_plan` to mark this step and Step 7 completed and continue with the next step of the active workflow.

Otherwise, output the state as text:

- The checks that passed
- The reviewers who reviewed the head commit
- Each `Bot` reviewer whose check, the one whose `app` or `name` matches its login, reports in its `title` that it skipped the head commit, as on a rate limit
- Each review request of `type` `Bot` still pending
- Each unresolved thread, with its author and path
- Each case left unverified

Resolve the merge methods the repository allows with `gh repo view --json squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed`. Run `git fetch origin <baseRefName>` and sample the base branch's history with `git log --first-parent origin/<baseRefName> -n 30 --pretty=%s`: `(#N)`-suffixed subjects point to squash, and merge-PR commits to a merge commit.

Use `request_user_input` to offer up to two allowed methods and **Don't merge yet**. Each method merges the pull request and deletes its branch. List first, labeled `(Recommended)`, the allowed method the history points to, or, when it points to none that is allowed, the first allowed one of squash, merge commit, and rebase. When the repository allows a third method, name it in the question as available through a freeform answer, and take a freeform answer naming an allowed method as that method.

On a merge method, run `gh pr merge <number> --<squash|merge|rebase> --match-head-commit <headRefOid>`, then read the state with `gh pr view <number> --json state`. When it is not `MERGED`, because a merge queue or auto-merge took the pull request or the command failed, hand the pull request back as above with what `gh` reported.

On **Don't merge yet**, hand the pull request back as above, with the user's choice as the reason.

## Step 7: Clean Up

Read the head branch's tip on GitHub with `gh api repos/<head owner>/<head repository>/git/ref/heads/<headRefName> --jq .object.sha`. When it is the pull request's `headRefOid`, delete the branch with `gh api -X DELETE repos/<head owner>/<head repository>/git/refs/heads/<headRefName>`. When the read finds no branch, skip the deletion. When its tip differs, keep it and report that it moved past the merged head. Then run `git fetch --prune`.

Then take the case that matches where Step 1 found this session:

- **On another branch** — leave the checkout as it is.
- **In a linked worktree on the head branch** — present the worktree's path and the commands that finish the cleanup from the main checkout: fast-forward the main checkout's local `<baseRefName>` to `origin/<baseRefName>`, run `git worktree remove <path>`, and run `git branch -D <headRefName>` when the local branch's tip is `headRefOid`. Skip the local branch deletion below.
- **In the main checkout on the head branch** — when `git status --porcelain --untracked-files=no` lists changes, report them, keep the branch checked out, and skip the local branch deletion below. Otherwise run `git switch <baseRefName>` and `git merge --ff-only origin/<baseRefName>`.

When the local branch exists and its tip is the pull request's `headRefOid`, delete it with `git branch -D <headRefName>`, keeping it when git refuses. When its tip differs, keep it and report the commits it holds beyond the merged head (`git log --oneline <headRefOid>..<headRefName>`).

Report what was merged, removed, and kept.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.
