---
name: review-plan
description: "Review a planning artifact (plan, shells, or spec) by running internal reviews and a peer review in parallel and returning combined findings. Use when the user asks to \"review my plan\", \"review my shells\", \"review my spec\", \"check my plan\", \"check my shells\", \"check my spec\", \"critique my plan\", \"critique my shells\", \"critique my spec\", or wants feedback on a planning artifact."
---

# Review Plan

Review a planning artifact against type-specific criteria. Runs internal reviews and `$peer-review` in parallel by default. Returns combined structured findings.

## Step 1: Determine Artifact Type and Resolve

### Determine Artifact Type

1. **Explicit argument** — If the user specified a type (e.g., "review shells", "review spec"), use it. No argument defaults to **plan**.
2. **Conversation context** — If artifact text or a path is already in context, infer the type.
3. **Auto-detect** — Check `.turbo/` for existing artifacts. If multiple types exist, pick the one with the most recently modified file.

### Resolve the Artifact

#### Plan (default)

1. **Plan text in conversation** — use it
2. **Explicit path** — read it
3. **Explicit slug** — resolve to `.turbo/plans/<slug>.md`
4. **Single file** — Glob `.turbo/plans/*.md`. If exactly one file exists, use it
5. **Most recent** — most recently modified file
6. **Legacy fallback** — `.turbo/plan.md` if `.turbo/plans/` does not exist
7. **Nothing found** — stop and state that no artifact was found to review

#### Shells

1. **Shell text in conversation** — use it
2. **Explicit spec slug** — Glob `.turbo/shells/<slug>-*.md`
3. **Explicit spec path** — derive slug from filename, glob as above
4. **Single spec** — Glob `.turbo/specs/*.md`. If exactly one, derive slug and glob for shells
5. **Most recent spec** — most recently modified spec, derive slug and glob
6. **Nothing found** — stop and state that no artifact was found to review

For shells, read each shell file and parse its YAML frontmatter (`spec`, `depends_on`). Read the source spec from the `spec` field.

#### Spec

1. **Spec text in conversation** — use it
2. **Explicit path** — read it
3. **Explicit slug** — resolve to `.turbo/specs/<slug>.md`
4. **Single file** — Glob `.turbo/specs/*.md`. If exactly one, use it
5. **Most recent** — most recently modified
6. **Legacy fallback** — `.turbo/spec.md` if `.turbo/specs/` does not exist
7. **Nothing found** — stop and state that no artifact was found to review

If multiple candidates exist, pick the most recently modified.

## Step 2: Run Reviews in Parallel

Each artifact type has two reference files, one per internal review:

- **Plan** — [references/plan-structure-review.md](references/plan-structure-review.md), [references/plan-scope-review.md](references/plan-scope-review.md)
- **Shells** — [references/shells-structure-review.md](references/shells-structure-review.md), [references/shells-scope-review.md](references/shells-scope-review.md)
- **Spec** — [references/spec-structure-review.md](references/spec-structure-review.md), [references/spec-scope-review.md](references/spec-scope-review.md)

Skip peer review when instructed (e.g., "without peer review", "no peer", "internal only").

Run the review branches independently. Launch them with `spawn_agent` / `wait_agent` using inherited model defaults, issuing every call in one batch. Do not issue one and await its result before issuing the rest. That is three branches when peer review is active (two internal + one peer), or two branches when peer review is skipped. Every branch prompt must direct it to treat the shared working tree and its git index as read-only and to assess findings by reading and reasoning. HEAD stays where it is: read other refs with `git show <ref>:<path>` rather than `git checkout` or `git switch`. For a check that genuinely requires mutating code (such as testing whether a finding holds), the branch works in an isolated `git worktree` created under `$TMPDIR` and discarded afterward. Give that worktree its own dependency install rather than reaching the shared tree's install by any route: removing a worktree deletes through symlinks, and a redirected suite writes into the shared install. When its own install is not possible, the check is left unrun and reported as such. Afterward the branch verifies that `git worktree list` no longer shows the worktree, that `git status --short` is clean, that HEAD is still on the branch it started on, and that the shared tree's dependency directory still resolves (a destroyed install leaves `git status` clean, since it is gitignored). Damage the branch cannot repair is reported with the exact repair command in place of findings.

- **Structure branch:** The branch prompt must include the artifact text, the path to the type's structure reference file (`~/.agents/skills/review-plan/references/<type>-structure-review.md`), the output format below, and this directive: read that reference file directly, apply its determination criteria as the bar for a real finding, then report every finding that clears that bar tagged with its priority and with `internal (structure)`. Coverage is the goal at this stage, so surface everything that qualifies and let the priority tags convey severity. The branch must also return the Overall Verdict block for its dimension.
- **Scope branch:** Same, with the type's scope reference file (`~/.agents/skills/review-plan/references/<type>-scope-review.md`) and findings tagged `internal (scope)`.
- **Peer review branch (unless skipping):** Spawn a Codex sub-agent and instruct it to read and follow `$peer-review` from the installed skill directory, with a request describing: (a) the artifact under review; (b) the criteria live in `~/.agents/skills/review-plan/references/<type>-structure-review.md` and `~/.agents/skills/review-plan/references/<type>-scope-review.md` for the resolved type from Step 1 — the reviewer should read both files directly and cover every criterion in one single-pass review, applying each file's determination criteria and priority scale to the findings in that file's domain; (c) the Overall Verdict should use the `Readiness: <ready | needs revision>` label. The branch prompt must also state explicitly that the sub-agent's final message must contain the verbatim findings text `$peer-review` produced.

Aggregate findings with attribution (reviewer: "internal" or "peer", each with its "structure" or "scope" dimension). Present them in the output format below.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

## Output Format

Format each finding as:

```
### [P<N>] <title (imperative, ≤80 chars)>

**Section:** <plan section, shell number(s), or spec section>
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
