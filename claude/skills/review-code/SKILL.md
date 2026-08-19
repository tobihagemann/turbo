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

State the resolved file list before continuing: add `--name-only` to a diff command, or list the files for a file or directory scope. When the scope is a staged diff, also state how many further files `git diff HEAD --name-only` reports, so a scope narrower than intended stays visible before fanning out.

## Step 2: Run Reviews in Parallel

Each active type maps to a criteria reference file:

- **Correctness** — [references/correctness-review.md](references/correctness-review.md)
- **Security** — [references/security-review.md](references/security-review.md)
- **API usage** — [references/api-usage-review.md](references/api-usage-review.md)
- **Consistency** — [references/consistency-review.md](references/consistency-review.md)
- **Simplicity** — [references/simplicity-review.md](references/simplicity-review.md)
- **Coverage** — [references/coverage-review.md](references/coverage-review.md)

Full review activates all six types; a single-concern argument activates one. Skip peer review when instructed (e.g., "without peer review", "no peer", "internal only").

Before dispatching, read the project's test configuration and CI workflow to identify any test tier that resets a shared external resource between tests, such as a database, a fixed port, or a cache. Such tiers have no cross-process interlock, so agents running them concurrently wipe each other's state and return failures indistinguishable from defects in the change. Name any such tier to every agent as off-limits.

When the scope contains a guard whose safety rests on an assumption stated in the conversation, in a plan file, or in a code comment, give every agent that assumption as the claim to refute rather than as background.

When the scope contains content that a build or render transform rewrites before it ships — markup compiled to components, template expansion, code generation, translation extraction — build the project before dispatching, in an isolated `git worktree` under `$TMPDIR` when the build writes to tracked files, and name the emitted files as part of the scope every agent receives, so each type judges the emitted artifact rather than the source.

Confine each agent's prompt to what to review, plus the conventions and factual properties that bear on it. A statement that tells an agent what verdict to reach about a property of the existing code binds it to accept the very property the review exists to assess.

Emit all Agent tool calls below in one assistant message. Do not send one and await its result before sending the rest. Each Agent call uses `model: "opus"` and no `name`. Wait for every agent to report before continuing. Do not begin the next step on a partial set, and do not relaunch an agent that has not yet reported. For full review that is seven Agent tool calls (six internal + one peer); for single-concern it is two (one internal + one peer). Every agent's prompt must direct it to treat the shared working tree and its git index as read-only and to assess findings by reading and reasoning. HEAD stays where it is: read other refs with `git show <ref>:<path>` rather than `git checkout` or `git switch`. For a check that genuinely requires mutating code (such as testing whether a finding holds), the agent works in an isolated `git worktree` created under `$TMPDIR` and discarded afterward. Give that worktree its own dependency install rather than reaching the shared tree's install by any route: removing a worktree deletes through symlinks, and a redirected suite writes into the shared install. When its own install is not possible, the check is left unrun and reported as such. Afterward the agent verifies that `git worktree list` no longer shows the worktree, that `git status --short` is clean, that HEAD is still on the branch it started on, and that the shared tree's dependency directory still resolves (a destroyed install leaves `git status` clean, since it is gitignored). Damage the agent cannot repair is reported with the exact repair command in place of findings.

- **Internal Agent (one per active type):** Launch a separate Agent tool call for each active type. The subagent's prompt must include the scope, the path to the type's reference file (`~/.claude/skills/review-code/references/<type>-review.md`), the output format below, and this directive: read that reference file directly, apply its determination criteria as the bar for a real finding, then report every finding that clears that bar tagged with its priority. Coverage is the goal at this stage, so surface everything that qualifies and let the priority tags convey severity. The subagent must also return the Overall Verdict block for its type, using the verdict label from the reference file it read.
- **Peer review Agent (unless skipping):** Launch an Agent tool call whose prompt instructs the subagent to invoke `/peer-review` via the Skill tool with a request describing: (a) the scope to review; (b) all active types covered in one single-pass review run that evaluates every dimension, each judged independently against its criteria file, rather than a per-dimension parallel fan-out; (c) for each dimension, the criteria live in `~/.claude/skills/review-code/references/<type>-review.md` — the reviewer should read that file directly, use its priority scale and verdict label, and include any extra metadata fields it specifies; (d) the output format below, including the `**Failure scenario:**` line. The prompt must also state explicitly that the subagent's final assistant message must contain the verbatim findings text `/peer-review` produced.

Aggregate the findings and per-type verdicts the subagents return, with attribution (reviewer: "internal" or "peer"; type; file path). Present them in the output format below.

Then use the TaskList tool and proceed to any remaining task.

## Output Format

Format each finding as:

```
### [P<N>] <title (imperative, ≤80 chars)>

**File:** `<file path>` (lines <start>-<end>)
**Reviewer:** <internal | peer> (<type>)
**Failure scenario:** <concrete trigger → the consequence>

<one paragraph explaining the issue and its impact>
```

For `**Failure scenario:**`, state the consequence a user or maintainer would observe: an error, wrong output, or data loss; for the non-correctness types, the concrete cost — what breaks on the next change, what is duplicated, what goes untested, which stated rule is violated. An intermediate state ("the cached value goes stale", "the collection keeps growing") stops short of a consequence; carry it through to what that state causes.

The reference file may specify additional metadata fields (e.g., `**Category:**`, `**Library:**`, `**Docs:**`). Include them between the `**Reviewer:**` line and the `**Failure scenario:**` line.

After all findings, place the Overall Verdict block each internal subagent returned for its type (each uses the verdict label from its reference file). For single-concern, that is one verdict block; for full review, six. After the per-type verdicts, add a single combined `## Peer Review Verdict` block summarizing what the peer review returned.

```
## Overall Verdict — <type>

**<Verdict Label>:** <status>

<1-3 sentence assessment>
```

If there are no qualifying findings for a type, state so under that type's verdict block and explain briefly.

## Rules

- Present findings grouped by priority in single-concern mode, and in file order in full review mode to minimize context switching.
