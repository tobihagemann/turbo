---
name: resolve-pr-comments
description: "Evaluate, fix, answer, and reply to GitHub pull request review comments and conversation comments. Handles both change requests (fix or skip) and reviewer questions (explain using the rationale recalled from past Claude Code transcripts). Use when the user asks to \"resolve PR comments\", \"fix review comments\", \"address PR feedback\", \"handle review comments\", \"address review feedback\", \"respond to PR comments\", \"answer review questions\", or \"address code review\"."
---

# Resolve PR Review Comments

Fetch unresolved review comments from a GitHub PR (inline threads, review-body observations, and issue-comment observations from the PR conversation), evaluate each one, fix or skip based on confidence, answer reviewer questions using the recalled rationale behind the change, and reply. Inline threads are answered with thread replies; issue-comment findings from people are answered with new PR conversation comments. Review-body findings and AI-reviewer issue comments flow through the same evaluate-and-fix pipeline; their outcomes land only in the summary.

## Task Tracking

At the start, use `TaskCreate` to create a task for each step:

1. Fetch comments
2. Triage already-addressed feedback
3. Run `/interpret-feedback` skill
4. Split questions and change requests
5. Run `/evaluate-findings` skill
6. Resolve ambiguities
7. Run `/resolve-findings` skill
8. Verify fixes
9. Answer reviewer questions
10. Wait for AI re-reviews
11. Run `/reply-to-pr-threads` skill
12. Run `/reply-to-pr-conversation` skill
13. Summary

## Step 1: Fetch Comments

Auto-detect owner, repo, and PR number from current branch if not provided. Then run `scripts/fetch-pr-data.sh`, which handles full pagination (reviews, review threads, inner comment pages for long threads, issue comments, commits) and emits a single merged JSON document:

```bash
bash <skill-dir>/scripts/fetch-pr-data.sh <owner> <repo> <pr_number>
```

Output shape:

```jsonc
{
  "meta":          { "title", "url", "headRefName", "baseRefName", "body" },
  "reviewThreads": [ { "id", "isResolved", "isOutdated", "comments": { "nodes": [ { "author", "body", "path", "line", "originalLine", "diffHunk" } ] } } ],
  "reviews":       [ { "author", "body", "state", "submittedAt" } ],
  "issueComments": [ { "author", "body", "createdAt", "url" } ],
  "commits":       [ { "commit": { "oid", "abbreviatedOid", "message", "committedDate" } } ]
}
```

Filter review threads to unresolved only. Filter reviews to those with a non-empty body, excluding `PENDING` state (unsubmitted drafts). Filter issue comments to those with a non-empty body.

## Step 2: Triage Already-Addressed Feedback

Review bodies and PR conversation comments (issue comments) often pack multiple distinct concerns into one comment. Split each non-empty, non-PENDING review body and each non-empty issue comment into atomic observations, one per paragraph or bullet, so each can be evaluated on its own merits.

For every observation, check whether a subsequent commit already addresses it. Compare the source timestamp (`submittedAt` for review bodies, `createdAt` for issue comments) against each commit's `committedDate`; only commits after the source was posted can address it. Start with commit messages; read `git show <oid>` only when the message is ambiguous. A commit addresses an observation when its changes clearly resolve that specific concern. Touching the same area is not enough for an observation.

When an observation asserts a requirement or an intended behavior, compare that assertion against `meta.body`. The PR description is the author's own current statement of intent, so a description stating the opposite leaves a premise for Step 5 to settle. Record the contradiction against the observation and carry it forward, so Step 5 settles that premise once instead of re-deriving it for every finding the premise produced.

Classify each observation:
- **Addressed**: A subsequent commit resolves it. Record the commit SHA for the Step 13 summary.
- **Unaddressed**: No subsequent commit resolves it. Carry into Step 3, tagged with its `source` (`review-body` or `issue-comment`), the author, the observation text, any recorded contradiction with the PR description, and (for review bodies) the review state.

Review-body and issue-comment findings have no `diffHunk`, file path, or line reference. The downstream pipeline handles findings without a code location.

Triage inline threads on their replies. Look for a later reply that claims the concern is fixed and names the commit that fixed it. Verify two things about that commit. First, it is on the branch: it appears in `commits`, or `git branch --contains <sha>` reports the head branch. Second, it changed or deleted the thread's path. When both hold, classify the thread **Addressed** with that SHA and skip Steps 3 through 8 for it. Classify the rest **Unaddressed** and carry them into Step 3.

## Step 3: Run `/interpret-feedback` Skill

Run the `/interpret-feedback` skill on the union of:
- Unaddressed inline threads from Step 2
- Unaddressed review-body findings from Step 2
- Unaddressed issue-comment findings from Step 2

Skip AI-reviewer accounts — match by known login (e.g., `coderabbitai`, `copilot-pull-request-reviewer`, `github-advanced-security`), not the `[bot]` suffix alone. Their structured feedback routes directly to `/evaluate-findings`.

If that leaves no items to interpret, skip the skill invocation.

For inline threads, include the `diffHunk` so the interpreters can see the code the reviewer was looking at. For outdated comments where `line` is null, use `originalLine`. For review-body and issue-comment findings, provide the observation text and the PR's changed-file list as context.

Tag each item with its `source` (`inline-thread`, `review-body`, or `issue-comment`) so later steps can route replies correctly.

## Step 4: Split Questions and Change Requests

Classify each interpreted item as either a **question** or a **change request** based on the reconciled intent from Step 3.

- **Question** — the reviewer is asking for an explanation or wondering whether something is intentional. No code change requested. Examples: "Why this approach?", "Is this intentional?", "What is the benefit here?".
- **Change request** — the reviewer suggests a code change, flags a bug, or proposes an alternative. This includes soft-phrased suggestions ("could we ...", "consider ...") and rhetorical questions that imply a change ("Shouldn't this ...?", "Is there a reason this isn't ...?").

When in doubt, treat the item as a change request. The verdict from `/evaluate-findings` in Step 5 will catch genuine non-issues.

Produce two lists. Each entry retains the `source` tag, identifier (thread id for inline threads; a generated id for review-body and issue-comment findings), file path and line (use `originalLine` when `line` is null; omit for review-body and issue-comment findings), the reviewer's original text, any recorded contradiction with the PR description, and the reconciled intent from Step 3. Questions skip Step 5 and feed Step 9. Change requests feed Step 5.

## Step 5: Run `/evaluate-findings` Skill

If Step 4 produced no change requests and Step 3 routed no AI-reviewer items here, skip the skill invocation.

Run the `/evaluate-findings` skill on the change requests from Step 4 and the AI-reviewer items Step 3 routed here, to triage each one. Questions are not evaluated here.

Review-body and issue-comment findings have no file or line reference. Scope their assessment to the PR's changed files as a whole, and do not treat the absent code location as a "code has diverged" early exit.

## Step 6: Resolve Ambiguities

Collect items assigned an Escalate verdict by `/evaluate-findings`. If there are none, skip to Step 7.

Output all escalated items as a numbered list. For each item, show:

- The reviewer's original comment
- The competing interpretations or the reason for escalation
- The file and line reference, when available

Then use `AskUserQuestion` to ask how to handle them. State each question as the decision the user owns: what the code should do. Leave the reviewer's wording and code location to the numbered list above. Per item, the options are:

- **Direct answer**: "Do X" — assign an Accept verdict with the user's clarified intent. Step 7 picks it up as an accepted finding.
- **Ask the reviewer**: "Ask them Y" — queue a clarification question to be drafted in Step 11 (inline threads) or Step 12 (issue comments). Offer it only for an item one of those steps replies to.
- **Skip**: Remove from processing

Whenever the item is costly to reverse (its resolution establishes a pattern others will follow, defines an interface, commits to a data shape, or imports a pattern the codebase has not used), and whenever you cannot recommend one of the others with conviction, add a **Get a second opinion** option. It runs the `/consult-codex` skill for the soundest resolution on technical merit alone, independent of the changeset's original scope, naming any scope cost with the answer. On an item that turns on product intent, run it for what each resolution commits to, what reversing it costs, and what the prevailing convention is. Then resolve the item with that answer in hand, re-asking when the choice stays the user's.

## Step 7: Run `/resolve-findings` Skill

If there are no accepted findings to implement, skip to Step 9.

Run the `/resolve-findings` skill on the accepted findings from Step 5, including any items reclassified in Step 6. It commits and pushes before returning; Steps 11 and 12 replies reference that commit SHA.

## Step 8: Verify Fixes

For each finding that was fixed in Step 7, verify the fix actually addresses the reviewer's concern:

1. Read the current code. For inline threads, use the thread's file and line. For review-body and issue-comment findings, read the files touched during the fix.
2. Compare against the reviewer's comment (and `diffHunk` when available).
3. Confirm the specific concern is resolved.

If the fix did not address the concern (wrong location, incomplete change, or the issue is still present), downgrade the item to Skip. Record the reason (the attempted fix did not resolve the reviewer's concern, with a brief explanation of what remains) so Step 11 (for inline threads), Step 12 (for the issue-comment findings it replies to), and Step 13 (for the rest) report it correctly.

## Step 9: Answer Reviewer Questions

For each question item whose source is `inline-thread`, run the `/recall-rationale` skill with `<path>:<line>` and compose a one-or-two-sentence answer from the rationale it returns, quoting or paraphrasing the implementer's own words where they explain the decision. When it returns no transcript, compose the answer from the current code and record that grounding for Step 13. Leave out any mention of Claude, transcripts, or recalled rationale, and leave voice rules and reply formatting to Step 11.

Issue-comment questions are composed during Step 12's assembly and posted by `/reply-to-pr-conversation`. They have no file and line to ground with `/recall-rationale`, so the composition draws on the reconciled intent and the PR's changed code. Review-body questions have no destination to post to and are listed for manual follow-up in Step 13.

If there are no inline-thread questions, skip this step.

## Step 10: Wait for AI Re-reviews

Skip this step when Step 7 pushed no commit, or when no inline thread whose first comment is from an AI-reviewer account as matched in Step 3 came out of Steps 5 through 8 fixed or skipped.

For each AI reviewer with such a thread, check whether it is re-reviewing the pushed head commit: a pending review request for it, or a queued or in-progress check or workflow run from it on that commit. Leave `github-advanced-security` out of this check. When none is, skip the rest of this step.

Otherwise use the Monitor tool with an until-loop that polls the PR's reviews (`reviews(last: 20) { nodes { author { login } commit { oid } } }`) and ends once each reviewer found re-reviewing has submitted a review whose commit is the pushed head, or after 15 minutes. Then run `scripts/fetch-pr-data.sh` again. Drop from processing every inline thread that is now resolved, and leave threads and review bodies that arrived since Step 1 for a later run; record both for the Step 13 summary.

## Step 11: Run `/reply-to-pr-threads` Skill

Assemble the processed-thread list from inline-thread items only:

- **fix** — inline threads with Apply verdicts whose fix was verified in Step 8. Payload: the commit SHA from Step 7.
- **skip** — inline threads with Skip verdicts from `/evaluate-findings`, plus any downgraded in Step 8. Payload: the skip reasoning.
- **answer** — inline-thread questions with answers composed in Step 9. Payload: the raw answer text.
- **clarify** — inline threads reclassified as clarification questions in Step 6. Payload: the user-directed clarification question.
- **resolve-only** — still-unresolved Addressed inline threads from Step 2 whose first comment is from an AI-reviewer account, matched as in Step 3. Before including one, read the current code at the thread's path and confirm the specific concern is fixed; when it is not, leave the thread out and record what remains for Step 13. Payload: the addressing commit SHA.

Give each fix and skip entry whose first comment is from an AI-reviewer account as matched in Step 3 a resolution reason: `ADDRESSED` for a fix, `INVALID` for a skip that refuted the finding as incorrect, and `WONT_FIX` for a skip that declined a valid one. Give every resolve-only entry `ADDRESSED`. Give none to a thread downgraded in Step 8, to a skip that neither refuted nor declined the finding, or to any other thread, leaving it for its reviewer to resolve.

A thread whose first comment is from `github-advanced-security` carries a code-scanning alert. Give each such skip entry that carries a resolution reason the alert number from the comment's `/security/code-scanning/<n>` link and a dismissal reason: `used in tests` when the flagged code runs only in tests, otherwise `false positive` for `INVALID` and `won't fix` for `WONT_FIX`.

Issue-comment findings go to Step 12. Review-body findings have no destination to post to, Addressed inline threads outside the resolve-only entries already carry the reply naming the commit, and threads Step 10 dropped were resolved during the wait; all three surface only in Step 13.

If there are no inline-thread items to reply to or resolve, skip the skill invocation.

Run the `/reply-to-pr-threads` skill with the assembled list.

## Step 12: Run `/reply-to-pr-conversation` Skill

Assemble the processed-item list from issue-comment items only. Each entry includes the generated id, the author, the original comment body (for quoting), the category, and the per-category payload:

- **fix** — issue-comment findings with Apply verdicts whose fix was verified in Step 8. Payload: the commit SHA from Step 7.
- **skip** — issue-comment findings with Skip verdicts from `/evaluate-findings`, plus any downgraded in Step 8. Payload: the skip reasoning.
- **answer** — issue-comment questions. Compose a one-or-two-sentence answer from the reconciled intent from Step 3 and the PR's changed code. Payload: the composed answer.
- **clarify** — issue-comment items reclassified as clarification questions in Step 6. Payload: the user-directed clarification question.

Review-body findings have no destination to post to, and issue comments from AI-reviewer accounts, matched as in Step 3, get no conversation reply. Exclude both from this list; their triage status is reported in Step 13.

If there are no issue-comment items to reply to, skip the skill invocation.

Run the `/reply-to-pr-conversation` skill with the assembled list.

## Step 13: Summary

After processing all items, present a summary grouped by source.

**Inline threads:**
- Total unresolved threads found
- Already addressed by commits (list file path, one-line summary, addressing commit SHA)
- Fixed (change requests with accepted verdicts; list file path and addressing commit SHA)
- Skipped (false positives or disproportionate changes)
- Resolved during Step 10's wait (list file path)
- Resolved by this run (list file path, resolution reason, and any dismissed alert number)
- Addressed AI-reviewer threads left unresolved (list file path and what remains)
- Arrived during Step 10's wait, left for a later run (list file path or review author)
- Questions answered (split into: answered from recalled transcript, answered from current code)
- Clarification questions posted

**Review-body findings:**
- Already addressed by commits (list author, state, one-line summary, addressing commit SHA)
- Fixed in this session (list observation, addressing commit SHA)
- Skipped (list observation, skip reasoning)
- Questions for manual follow-up (list observation; no thread to reply to)

**Issue-comment findings:**
- Already addressed by commits (list author, one-line summary, addressing commit SHA)
- Fixed in this session (list observation, addressing commit SHA)
- Skipped (list observation, skip reasoning)
- Questions answered (list observation)
- Clarification questions asked
- Reply URL (the posted issue comment, if any)

**Overall:** list of files modified.

## Rules

- Process inline threads in file order to minimize context switching. Handle review-body and issue-comment findings after inline threads.
- When a thread has multiple comments (discussion), read the full thread before deciding.
- The first comment in each thread is the original review comment; subsequent comments are replies.
