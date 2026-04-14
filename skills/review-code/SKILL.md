---
name: review-code
description: "Review code for bugs, security vulnerabilities, quality issues, API misuse, or test coverage gaps. Single-concern with a type argument, or full review with no argument. Use when the user asks to \"review my code\", \"full code review\", \"review my changes\", \"check for bugs\", \"scan for bugs\", \"review correctness\", \"security audit\", \"find vulnerabilities\", \"review security\", \"check for duplication\", \"review quality\", \"check API usage\", \"verify against docs\", \"find untested code\", or \"review test coverage\"."
---

# Review Code

Review code against type-specific criteria. With a type argument, runs a single-concern review. With no type argument, runs all five types in parallel.

**Types:** `correctness`, `security`, `quality`, `api-usage`, `coverage`

## Step 1: Determine the Scope

Determine what to review:

- If a specific **diff command** was provided (e.g., `git diff --cached`, `git diff main...HEAD`), use that.
- If a **file list or directory** was provided, review those files directly (read the full files, not a diff).
- If **neither** was provided, default to diffing against the repository's default branch (detect via `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`). If there are no changes against the default branch, use `AskUserQuestion` to ask what to review.

## Step 2: Review

Read the reference file for the specified type (or all five for full review):

- **Correctness** — [references/correctness-review.md](references/correctness-review.md)
- **Security** — [references/security-review.md](references/security-review.md)
- **Quality** — [references/quality-review.md](references/quality-review.md)
- **API usage** — [references/api-usage-review.md](references/api-usage-review.md)
- **Coverage** — [references/coverage-review.md](references/coverage-review.md)

Launch Agent tool calls (`model: "opus"`, do not set `run_in_background`). Each agent receives the scope from Step 1 and one reference file's content. For each file in scope, read enough surrounding context to understand the code.

- **Single-concern** (type specified) — one agent.
- **Full review** (no type) — five agents in a single message so they run concurrently.

Return findings in the output format below. Aggregate findings with attribution (reviewer type, file path, description).

Check your task list for remaining tasks and proceed.

## Output Format

Return findings as a numbered list. For each finding:

```
### [P<N>] <title (imperative, ≤80 chars)>

**File:** `<file path>` (lines <start>-<end>)

<one paragraph explaining the issue and its impact>
```

The reference file may specify additional metadata fields (e.g., `**Category:**`, `**Library:**`, `**Docs:**`). Include them between the `**File:**` line and the paragraph.

After all findings, add a verdict using the label from the reference file:

```
## Overall Verdict

**<Verdict Label>:** <status>

<1-3 sentence assessment>
```

If there are no qualifying findings, state so and explain briefly.

## Rules

- Present findings grouped by priority.
- In full code review mode, present findings in file order to minimize context switching.
