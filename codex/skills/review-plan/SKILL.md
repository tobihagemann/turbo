---
name: review-plan
description: "Review a plan by running internal reviews and a peer review in parallel and returning combined findings. Use when the user asks to \"review my plan\", \"check my plan\", \"critique my plan\", or wants feedback on a plan."
---

# Review Plan

Review a plan against structure and scope criteria. Runs internal reviews and `$peer-review` in parallel by default. Returns combined structured findings.

## Step 1: Resolve the Plan

1. **Plan text in conversation** — use it
2. **Explicit path** — read it
3. **Explicit slug** — resolve to `.turbo/plans/<slug>.md`
4. **Single file** — Glob `.turbo/plans/*.md`. If exactly one file exists, use it
5. **Most recent** — most recently modified file
6. **Legacy fallback** — `.turbo/plan.md` if `.turbo/plans/` does not exist
7. **Nothing found** — stop and state that no plan was found to review

When the plan came from a file, state the resolved path before continuing.

Unless the plan came from conversation text, or an explicit path or slug was passed, check whether the resolved plan still describes work that remains to be done. Report a frontmatter `status:` of `done` alongside the path.

## Step 2: Run Reviews in Parallel

Two reference files carry the criteria, one per internal review:

- [references/plan-structure-review.md](references/plan-structure-review.md)
- [references/plan-scope-review.md](references/plan-scope-review.md)

Skip peer review when instructed (e.g., "without peer review", "no peer", "internal only").

Run the review branches independently. Launch them with `spawn_agent` / `wait_agent` using inherited model defaults, issuing every call in one batch. Do not issue one and await its result before issuing the rest. That is three branches when peer review is active (two internal + one peer), or two branches when peer review is skipped. Every branch prompt must direct it to treat the shared working tree and its git index as read-only and to assess findings by reading and reasoning. HEAD stays where it is: read other refs with `git show <ref>:<path>` rather than `git checkout` or `git switch`. For a check that genuinely requires mutating code (such as testing whether a finding holds), the branch works in an isolated `git worktree` created under `$TMPDIR` and discarded afterward. Give that worktree its own dependency install rather than reaching the shared tree's install by any route: removing a worktree deletes through symlinks, and a redirected suite writes into the shared install. When its own install is not possible, the check is left unrun and reported as such. Afterward the branch verifies that `git worktree list` no longer shows the worktree, that `git status --short` is clean, that HEAD is still on the branch it started on, and that the shared tree's dependency directory still resolves (a destroyed install leaves `git status` clean, since it is gitignored). Damage the branch cannot repair is reported with the exact repair command in place of findings.

- **Structure branch:** The branch prompt must include the plan text, the path to the structure reference file (`~/.agents/skills/review-plan/references/plan-structure-review.md`), the output format below, and this directive: read that reference file directly, apply its determination criteria as the bar for a real finding, then report every finding that clears that bar tagged with its priority and with `internal (structure)`. Coverage is the goal at this stage, so surface everything that qualifies and let the priority tags convey severity. The branch must also return the Overall Verdict block for its dimension.
- **Scope branch:** Same, with the scope reference file (`~/.agents/skills/review-plan/references/plan-scope-review.md`) and findings tagged `internal (scope)`.
- **Peer review branch (unless skipping):** Spawn a Codex sub-agent and instruct it to read and follow `$peer-review` from the installed skill directory, with a request describing: (a) the plan under review; (b) the criteria live in `~/.agents/skills/review-plan/references/plan-structure-review.md` and `~/.agents/skills/review-plan/references/plan-scope-review.md` — the reviewer should read both files directly and cover every criterion in one single-pass review, applying each file's determination criteria and priority scale to the findings in that file's domain; (c) the Overall Verdict should use the `Readiness: <ready | needs revision>` label. The branch prompt must also state explicitly that the sub-agent's final message must contain the verbatim findings text `$peer-review` produced.

Aggregate findings with attribution (reviewer: "internal" or "peer", each with its "structure" or "scope" dimension). Present them in the output format below.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

## Output Format

Format each finding as:

```
### [P<N>] <title (imperative, ≤80 chars)>

**Section:** <plan section>
**Reviewer:** <internal | peer> (<structure | scope>)

<one paragraph explaining the issue and its impact>
```

After all findings, place the Overall Verdict block each internal branch returned for its dimension, then a single combined block for the peer review:

```
## Overall Verdict: <Structure | Scope>

**Readiness:** <ready | needs revision>

<1-3 sentence assessment>
```

```
## Peer Review Verdict

**Readiness:** <ready | needs revision>

<1-3 sentence assessment>
```

If there are no qualifying findings, state so and explain briefly.

## Rules

- Present findings grouped by priority.
