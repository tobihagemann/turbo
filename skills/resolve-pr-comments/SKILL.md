---
name: resolve-pr-comments
description: Evaluate, fix, and reply to GitHub pull request review comments. Use when the user asks to "resolve PR comments", "fix review comments", "address PR feedback", "handle review comments", or "address review feedback".
---

# Resolve PR Review Comments

Fetch unresolved review comments from a GitHub PR, critically evaluate each one, fix or skip based on confidence, and reply to each thread.

## Step 1: Fetch Unresolved Threads

Fetch all review threads from the PR:

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      title url
      reviewThreads(first: 100) {
        nodes {
          id isResolved isOutdated
          comments(first: 50) {
            nodes { author { login } body path position line }
          }
        }
      }
    }
  }
}' -f owner='{owner}' -f repo='{repo}' -F pr={pr_number}
```

Auto-detect owner, repo, and PR number from current branch if not provided. Filter to unresolved threads only.

## Step 2: Evaluate and Fix

Run the `/evaluate-findings` skill on the unresolved threads to assess each comment. Proceed with the evaluation results — apply high/medium confidence fixes and skip low confidence suggestions.

## Step 3: Distill Session

Run the `/distill-session` skill.

## Step 4: Stage and Commit

If any fixes were applied, use `AskUserQuestion` to ask if the user wants to stage and commit the changes now.

- **Yes** — run the `/stage-commit` skill
- **No** — leave changes unstaged, proceed to replies

## Step 5: Wait for Push

Use `AskUserQuestion` to ask if the user has already pushed. Wait for confirmation before proceeding to replies.

## Step 6: Reply to Each Thread

Reply to every processed thread using:

```bash
gh api graphql -f query='
mutation($threadId: ID!, $body: String!) {
  addPullRequestReviewThreadReply(input: {pullRequestReviewThreadId: $threadId, body: $body}) {
    comment { id }
  }
}' -f threadId="THREAD_ID" -f body="REPLY_BODY"
```

**Reply format for fixes:**
```
Fixed in <commit-sha>.
```

Only add a brief description after the SHA if the fix meaningfully diverges from what the reviewer suggested. Otherwise, the commit SHA alone is enough.

**Reply format for skips:** Just state the reasoning for not changing it.

Keep replies to one or two sentences. Do not over-explain. Do not use em dashes. Write in a natural, human tone. Avoid stiff/formal phrasing, bullet-point reasoning, or bolded labels.

## Step 7: Summary

After processing all threads, present a summary table:

- Total unresolved threads found
- Number fixed (high + medium confidence)
- Number skipped (low confidence)
- List of files modified

## Rules

- Never resolve or dismiss a review thread — only reply. Let the reviewer resolve.
- Process comments in file order to minimize context switching.
- Stale references and default-to-skip policy are handled by the `/evaluate-findings` skill.
- When a thread has multiple comments (discussion), read the full thread before deciding.
- The first comment in each thread is the original review comment; subsequent comments are replies.
- CodeRabbit may auto-resolve its own review comments after a push. Skip any threads that were resolved between fetching and replying.
