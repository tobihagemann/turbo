---
name: review-code
description: "Review code for bugs, security vulnerabilities, API misuse, consistency issues, simplicity problems, or test coverage gaps by running internal reviews and a peer review in parallel and returning combined findings. Single-concern with a type argument, or full review with no argument. Use when the user asks to \"review my code\", \"full code review\", \"review my changes\", \"check for bugs\", \"scan for bugs\", \"review correctness\", \"security audit\", \"find vulnerabilities\", \"review security\", \"check API usage\", \"verify against docs\", \"check for cross-file duplication\", \"review consistency\", \"check for code reuse\", \"review simplicity\", \"find untested code\", or \"review test coverage\"."
---

# Review Code

Review code against type-specific criteria. Runs internal reviews and `/peer-review` in parallel by default. Returns combined structured findings.

**Types:** `correctness`, `security`, `api-usage`, `consistency`, `simplicity`, `coverage`

With a type argument, runs a single-concern internal review plus the peer review. With no type argument, runs all six internal reviews plus the peer review.

## Step 1: Determine the Scope

Determine what to review:

- If a specific **diff command** was provided (e.g., `git diff --cached`, `git diff main...HEAD`), use that.
- If a **file list or directory** was provided, review those files directly (read the full files, not a diff).
- If **neither** was provided, default to diffing against the repository's default branch (detect via `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`). If there are no changes against the default branch, stop and state that there is nothing to review.

## Step 2: Run Reviews in Parallel

Each active type maps to a criteria reference file:

- **Correctness** — [references/correctness-review.md](references/correctness-review.md)
- **Security** — [references/security-review.md](references/security-review.md)
- **API usage** — [references/api-usage-review.md](references/api-usage-review.md)
- **Consistency** — [references/consistency-review.md](references/consistency-review.md)
- **Simplicity** — [references/simplicity-review.md](references/simplicity-review.md)
- **Coverage** — [references/coverage-review.md](references/coverage-review.md)

Full review activates all six types; a single-concern argument activates one. Skip peer review when instructed (e.g., "without peer review", "no peer", "internal only").

Use the Agent tool to launch all agents below in a single assistant message so they run concurrently in the foreground. Each Agent call uses `model: "opus"` and sets `run_in_background: false` explicitly; omitting it backgrounds the agent. For full review that is seven Agent tool calls (six internal + one peer); for single-concern it is two (one internal + one peer). Every agent's prompt must direct it to treat the shared working tree and its git index as read-only and to assess findings by reading and reasoning. For a check that genuinely requires mutating code (such as testing whether a finding holds), the agent works in an isolated `git worktree` it discards afterward.

- **Internal Agent (one per active type):** Launch a separate Agent tool call for each active type. The subagent's prompt must include the scope, the path to the type's reference file (`~/.claude/skills/review-code/references/<type>-review.md`), the output format below, and this directive: read that reference file directly, apply its determination criteria as the bar for a real finding, then report every finding that clears that bar tagged with its priority. Coverage is the goal at this stage, so surface everything that qualifies and let the priority tags convey severity. The subagent must also return the Overall Verdict block for its type, using the verdict label from the reference file it read.
- **Peer review Agent (unless skipping):** Launch an Agent tool call whose prompt instructs the subagent to invoke `/peer-review` via the Skill tool with a request describing: (a) the scope to review; (b) each active type as a separate review dimension so they are reviewed independently; (c) for each dimension, the criteria live in `~/.claude/skills/review-code/references/<type>-review.md` — the reviewer should read that file directly, use its priority scale and verdict label, and include any extra metadata fields it specifies (e.g., `**Category:**`, `**Library:**`, `**Docs:**`) between the `**Reviewer:**` line and the paragraph. The prompt must also state explicitly that the subagent's final assistant message must contain the verbatim findings text `/peer-review` produced.

Aggregate the findings and per-type verdicts the subagents return, with attribution (reviewer: "internal" or "peer"; type; file path). Present them in the output format below.

Then use the TaskList tool and proceed to any remaining task.

## Output Format

Return findings as a numbered list. For each finding:

```
### [P<N>] <title (imperative, ≤80 chars)>

**File:** `<file path>` (lines <start>-<end>)
**Reviewer:** <internal | peer> (<type>)

<one paragraph explaining the issue and its impact>
```

The reference file may specify additional metadata fields (e.g., `**Category:**`, `**Library:**`, `**Docs:**`). Include them between the `**Reviewer:**` line and the paragraph.

After all findings, place the Overall Verdict block each internal subagent returned for its type (each uses the verdict label from its reference file). For single-concern, that is one verdict block; for full review, six. After the per-type verdicts, add a single combined `## Peer Review Verdict` block summarizing what the peer review returned.

```
## Overall Verdict — <type>

**<Verdict Label>:** <status>

<1-3 sentence assessment>
```

If there are no qualifying findings for a type, state so under that type's verdict block and explain briefly.

## Rules

- Present findings grouped by priority.
- In full code review mode, present findings in file order to minimize context switching.
