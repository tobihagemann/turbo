---
name: reply-to-pr-threads
description: "Draft, confirm, and post replies to GitHub PR review threads. Handles per-category reply formatting, re-fetches thread resolution state so auto-resolved threads are skipped, posts via GraphQL, and resolves threads whose entry carries a resolution reason. Use when the user asks to \"reply to PR threads\", \"post PR thread replies\", or \"draft PR reply messages\"."
---

# Reply to PR Threads

Draft replies for a processed review-thread list, confirm with the user, post the surviving drafts, and resolve threads whose entry carries a resolution reason.

## Step 1: Re-fetch Thread State

Auto-detect owner, repo, and PR number from the current branch if not provided, then query the current resolution state:

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100) {
        nodes { id isResolved }
      }
    }
  }
}' -f owner='{owner}' -f repo='{repo}' -F pr={pr_number}
```

Drop threads whose `isResolved` is now true. Reviewers or bots such as CodeRabbit may resolve threads after the original fetch, and drafting replies for them is wasted work.

## Step 2: Run `$github-voice` Skill

Run the `$github-voice` skill to load voice rules and the insider-vs-outsider detection.

## Step 3: Draft Replies

Use the processed-thread list from conversation context. Each entry has: thread id, file path, line, category (`fix`, `skip`, `answer`, `clarify`, or `resolve-only`), and per-category payload. An entry may also carry a resolution reason: `ADDRESSED`, `WONT_FIX`, or `INVALID`.

Keep every reply to one or two sentences. No bullet-point reasoning. No bolded labels.

**fix**: payload is a commit SHA, optionally with a divergence note.

```
Fixed in <commit-sha>.
```

Only add a brief sentence after the SHA when the fix meaningfully diverges from what the reviewer suggested. Otherwise the SHA alone is enough.

**skip**: payload is the skip reasoning. State the reasoning directly. Do not apologize.

**answer**: payload is the raw answer text. Tighten to one or two sentences and apply `$github-voice` rules. Do not cite session history or mention Codex. The reply reads as the implementer's own explanation.

**clarify**: payload is a user-directed question. Draft it as directed.

**resolve-only**: payload is the commit SHA that already addressed the thread. Draft no reply.

## Step 4: Present Drafts and Confirm

Output all drafts as text, grouped by file:

```
### <file-path>

**Thread <id>** (<category>, line <line>)
Reviewer: <original comment, truncated if long>
Reply: <drafted reply>
Resolve: <resolution reason>
```

Show the Reply line only for entries with a drafted reply, and the Resolve line only for entries that carry a resolution reason.

Then use `request_user_input` to ask whether to post. Offer:

- **Post** — post all drafts as shown, and resolve the threads that show a Resolve line
- **Cancel** — skip posting

## Step 5: Post Replies

For each approved draft, write the drafted reply to `.turbo/pr/thread-<thread-id>.md` with `apply_patch`, then post via the reply mutation:

```bash
gh api graphql -f query='
mutation($threadId: ID!, $body: String!) {
  addPullRequestReviewThreadReply(input: {pullRequestReviewThreadId: $threadId, body: $body}) {
    comment { id }
  }
}' -f threadId='<thread-id>' -F body=@.turbo/pr/thread-<thread-id>.md
```

Substitute `<thread-id>` with the thread's id for each post.

After posting the reply of an entry that carries a resolution reason, and for each resolve-only entry, resolve its thread:

```bash
gh api graphql -f query='
mutation($threadId: ID!, $reason: PullRequestReviewThreadResolutionReason) {
  resolveReviewThread(input: {threadId: $threadId, resolutionReason: $reason}) {
    thread { isResolved }
  }
}' -f threadId='<thread-id>' -f reason='<reason>'
```

Count a thread as resolved only when the response shows `isResolved: true`.

Report the outcome as a table, one row per thread, keeping every cell to a single line:

| Thread | Category | Outcome |
|--------|----------|---------|

Where Outcome is one of:

- **Posted** — the reply was posted
- **Posted and resolved** — the reply was posted and the thread resolved; name the reason
- **Posted, not resolved** — the reply was posted but the resolve failed; name the error
- **Resolved** — a resolve-only thread was resolved; name the reason
- **Not resolved** — a resolve-only thread's resolve failed; name the error
- **Skipped** — name the reason, such as auto-resolution between the re-fetch and the post

Keep the report to the table. When the table would be empty, report one line stating that no replies were posted or threads resolved, and why, instead.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

## Rules

- Resolve only the threads whose entry carries a resolution reason, and dismiss no review. Leave every other thread for its reviewer to resolve.
- If a post mutation fails because the thread is already resolved, log the skip and continue with the rest.
