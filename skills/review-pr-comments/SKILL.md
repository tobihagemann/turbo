---
name: review-pr-comments
description: This skill should be used when the user asks to "review PR comments", "show PR comments", "check PR for unresolved comments", "list review comments", "what comments are on the PR", "show unresolved threads", "summarize PR feedback", or wants to see a summary of unresolved GitHub PR review comments without making changes.
---

# Review PR Comments

Fetch unresolved review comments from a GitHub PR and present them in a readable summary. This is a read-only skill -- it does not evaluate, fix, or reply to any comments.

## Process

### Step 1: Fetch Unresolved Threads

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

### Step 2: Present Results

Display a summary header followed by comments grouped by file.

**Summary header:**

- PR title and link
- Branch: `head` -> `base`
- Total threads / unresolved threads

**Comments grouped by file:**

For each file with unresolved threads, show:

```
## `path/to/file.ts`

### Line 42 (by @reviewer)
> Comment body here

### Lines 10-15 (by @another-reviewer) [outdated]
> First comment body
>
> **@reply-author:** Reply body
```

**Formatting rules:**
- Group threads by file path, in the order they appear
- Within each file, order threads by line number
- Show all comments in a thread (the first is the original review comment; subsequent ones are replies)
- Mark outdated threads with `[outdated]`
- Use blockquotes for comment bodies
- For threads with multiple comments, show each comment with its author
- If there are zero unresolved threads, say so and stop

## Rules

- If the user wants to fix or reply to comments, direct them to use `/resolve-pr-comments`.
