---
name: resolve-pr-comments
description: "Evaluate, fix, answer, and reply to GitHub pull request review comments. Handles both change requests (fix or skip) and reviewer questions (explain using reasoning recalled from past Claude Code transcripts). Use when the user asks to \"resolve PR comments\", \"fix review comments\", \"address PR feedback\", \"handle review comments\", \"address review feedback\", \"respond to PR comments\", \"answer review questions\", or \"address code review\"."
---

# Resolve PR Review Comments

Fetch unresolved review comments from a GitHub PR, critically evaluate each one, fix or skip based on confidence, answer reviewer questions using recalled implementation reasoning, and reply to each thread.

## Task Tracking

At the start, use `TaskCreate` to create a task for each step:

1. Fetch comments
2. Triage review body comments
3. Run `/interpret-feedback` skill
4. Split questions and change requests
5. Run `/evaluate-findings` skill
6. Resolve ambiguities
7. Choose implementation path
8. Implement and finalize
9. Verify fixes
10. Run `/answer-reviewer-questions` skill
11. Run `/reply-to-pr-threads` skill
12. Summary

## Step 1: Fetch Comments

Fetch review threads, top-level review body comments, and PR commits from the PR:

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
            nodes { author { login } body path line originalLine diffHunk }
          }
        }
      }
      reviews(first: 50) {
        nodes {
          author { login }
          body state submittedAt
        }
      }
      commits(last: 50) {
        nodes {
          commit {
            oid abbreviatedOid message committedDate
          }
        }
      }
    }
  }
}' -f owner='{owner}' -f repo='{repo}' -F pr={pr_number}
```

Auto-detect owner, repo, and PR number from current branch if not provided. Filter review threads to unresolved only. Filter reviews to those with a non-empty body, excluding `PENDING` state (unsubmitted drafts).

## Step 2: Triage Review Body Comments

For each review body comment (non-empty body, non-PENDING), check whether a commit in the PR already addresses it. Compare the review's `submittedAt` timestamp against each commit's `committedDate`. Only commits **after** the review was submitted can address it.

To determine if a commit addresses a review body comment, start with commit messages. Only read the full diff (`git show <oid>`) when the message alone is ambiguous. A commit addresses a comment when its changes clearly resolve the specific issue described. Touching the same area is not enough.

Classify each review body comment as:
- **Addressed**: A subsequent commit clearly resolves the concern. Record the commit SHA.
- **Unaddressed**: No subsequent commit resolves the concern. Requires manual attention.

## Step 3: Run `/interpret-feedback` Skill

Run the `/interpret-feedback` skill on unresolved inline threads authored by humans. Skip threads from bot accounts (logins ending in `[bot]`, e.g., CodeRabbit, Copilot). AI reviewer feedback is structured and explicit enough for `/evaluate-findings` to handle directly.

Include each thread's `diffHunk` so the interpreters can see the code context the reviewer commented on. For outdated comments where `line` is null, use `originalLine` as the line reference.

## Step 4: Split Questions and Change Requests

Classify each interpreted thread as either a **question** or a **change request** based on the reconciled intent from Step 3.

- **Question** — the reviewer is asking for an explanation or wondering whether something is intentional. The thread does not request any code change. Examples: "Why this approach?", "Is this intentional?", "What is the benefit here?".
- **Change request** — the reviewer suggests a code change, flags a bug, or proposes an alternative implementation. This includes soft-phrased suggestions ("could we ...", "consider ...") and rhetorical questions that imply a change ("Shouldn't this ...?", "Is there a reason this isn't ...?").

When in doubt, treat a thread as a change request. The verdict from `/evaluate-findings` in Step 5 will catch genuine non-issues.

Produce two lists. Each entry retains the thread ID, file path, line (use `originalLine` when `line` is null), the reviewer's original comment text, and the reconciled intent from Step 3. Questions skip Step 5 and feed into Step 10. Change requests feed into Step 5.

## Step 5: Run `/evaluate-findings` Skill

Run the `/evaluate-findings` skill on the change requests from Step 4 to triage each one. Questions are not evaluated here.

## Step 6: Resolve Ambiguities

Collect items assigned an Escalate verdict by `/evaluate-findings`. If there are none, skip to Step 7.

Output all escalated items as a numbered list. For each item, show:

- The reviewer's original comment
- The competing interpretations or the reason for escalation
- The file and line reference

Then use `AskUserQuestion` to ask how to handle them. Per item, the options are:

- **Direct answer**: "Do X" — assign an Accept verdict with the user's clarified intent, and pass it to `/apply-findings`
- **Ask the reviewer**: "Ask them Y" — queue a clarification question to be drafted in Step 11
- **Skip**: Remove from processing

## Step 7: Choose Implementation Path

Present a summary of accepted findings: count by complexity (mechanical fixes vs. architectural or design changes). Then use `AskUserQuestion` to let the user choose:

- **Full** — Run `/turboplan` for drafting, refinement, approval, implementation, and finalize
- **Lightweight** — Apply directly via `/apply-findings`, then `/finalize`

Suggest Full when findings include complex or architectural changes. Suggest Lightweight when all findings are mechanical fixes.

If there are no accepted findings to implement, skip to Step 10.

## Step 8: Implement and Finalize

**Full path:**

Run the `/turboplan` skill with the accepted findings (including any items reclassified in Step 6) as the task description. Turboplan handles drafting, refinement, user confirmation, implementation, and finalize. The commit SHA from finalize is needed for reply messages.

**Lightweight path:**

1. Run the `/apply-findings` skill on the evaluated results, including any items reclassified in Step 6.
2. If changes were made, run the `/finalize` skill. The commit SHA from finalize is needed for reply messages.
3. If no changes were made, skip to Step 10.

## Step 9: Verify Fixes

For each finding that was fixed in Step 8, verify the fix actually addresses the reviewer's concern:

1. Read the current code at the relevant file and location
2. Compare against the reviewer's comment and `diffHunk` (the code the reviewer was looking at)
3. Confirm the specific concern is resolved

If the fix did not address the concern (wrong location, incomplete change, or the issue is still present), downgrade the thread to Skip. Record the reason — the attempted fix did not resolve the reviewer's concern, with a brief explanation of what remains — so Step 11 can feed it as the skip payload.

## Step 10: Run `/answer-reviewer-questions` Skill

Run the `/answer-reviewer-questions` skill on the question threads from Step 4. It produces raw answer text per thread.

If there are no question threads, skip this step.

## Step 11: Run `/reply-to-pr-threads` Skill

Assemble the processed-thread list from prior steps:

- **fix** — threads with Apply verdicts whose fix was verified in Step 9. Payload: the commit SHA from Step 8.
- **skip** — threads with Skip verdicts from `/evaluate-findings`, plus any threads downgraded in Step 9. Payload: the skip reasoning.
- **answer** — question threads with answers composed in Step 10. Payload: the raw answer text.
- **clarify** — threads reclassified as clarification questions in Step 6. Payload: the user-directed clarification question.

**Review body comments** (top-level review comments with non-empty body) are not threads and cannot be replied to. Exclude them from the list. Report their triage status in the summary.

Run the `/reply-to-pr-threads` skill with the assembled list.

## Step 12: Summary

After processing all threads, present a summary table:

- Total unresolved inline threads found
- Number fixed (change requests with accepted verdicts)
- Number skipped (false positives or disproportionate changes)
- Number of questions answered (split into: answered from recalled transcript, answered from current code)
- Number of clarification questions posted
- Review body comments already addressed by commits (list author, state, one-line summary, and the addressing commit SHA)
- Review body comments requiring manual attention (list author, state, and a one-line summary of each)
- List of files modified

## Rules

- Process comments in file order to minimize context switching.
- Stale references and default-to-skip policy are handled by the `/evaluate-findings` skill.
- When a thread has multiple comments (discussion), read the full thread before deciding.
- The first comment in each thread is the original review comment; subsequent comments are replies.
