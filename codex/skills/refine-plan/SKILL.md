---
name: refine-plan
description: "Iteratively review and revise a planning artifact until no new findings survive evaluation. Supports plans, shells, and specs. Use when the user asks to \"refine the plan\", \"refine the shells\", \"refine this spec\", \"iterate on the plan\", \"iterate on the shells\", \"tighten the plan\", \"tighten the shells\", \"tighten the spec\", \"improve the plan\", \"improve the shells\", or \"improve the spec\"."
---

# Refine Plan

Loop the review pipeline over a planning artifact until no new findings are accepted. Writes back to the artifact file(s) in place. Supports plans, shells, and specs.

## Task Tracking

At the start of every invocation (including re-runs from Step 5), use `update_plan` to track each step, restating any remaining steps of a parent workflow alongside them:

1. Resolve the artifact
2. Run `$review-plan` skill
3. Run `$evaluate-findings` skill
4. Run `$apply-findings` skill
5. Re-run `$refine-plan` skill if changed

## Step 1: Resolve the Artifact

### Determine Artifact Type

1. **Explicit argument** — If the user specified a type (e.g., "refine plan", "refine shells", "refine spec"), use it
2. **Conversation context** — Infer from conversation (e.g., if `$draft-plan` just ran, type is plan)
3. **Auto-detect** — Check `.turbo/` for existing artifacts. If multiple types exist, use `request_user_input`

### Resolve the Artifact File(s)

#### Plan

1. **Explicit path** — use it
2. **Explicit slug** — resolve to `.turbo/plans/<slug>.md`
3. **Single file** — Glob `.turbo/plans/*.md`. If exactly one file exists, use it
4. **Most recent** — most recently modified file
5. **Legacy fallback** — `.turbo/plan.md` if `.turbo/plans/` does not exist
6. **Nothing found** — tell the user to run `$turboplan` (for a new task) or `$pick-next-shell` (for existing shells) and stop

#### Shells

1. **Explicit spec slug** — Glob `.turbo/shells/<slug>-*.md`
2. **Explicit spec path** — derive slug from filename, glob as above
3. **Single spec** — Glob `.turbo/specs/*.md`. If exactly one, derive slug and glob for shells
4. **Most recent spec** — most recently modified spec, derive slug and glob
5. **Nothing found** — tell the user to run `$draft-shells` first and stop

For shells, read each shell file and extract from its YAML frontmatter: `spec` (source spec path) and `depends_on`. Verify the source spec exists. State the spec path, number of shells, and each shell's filename.

#### Spec

1. **Explicit path** — use it
2. **Explicit slug** — resolve to `.turbo/specs/<slug>.md`
3. **Single file** — Glob `.turbo/specs/*.md`. If exactly one, use it
4. **Most recent** — most recently modified
5. **Legacy fallback** — `.turbo/spec.md` if `.turbo/specs/` does not exist
6. **Nothing found** — tell the user to run `$draft-spec` first and stop

If multiple candidates exist and the choice is non-obvious, use `request_user_input`.

State the resolved path(s) before continuing.

## Loop State

Loop state lives at `.turbo/loops/<slug>.md` — slug from the resolved artifact; for shells, use the source spec's slug so structural rounds cannot rename the ledger; for a legacy single-file fallback, use the file's basename. At the start of every invocation, read the ledger if it exists.

- **Fresh loop** (no ledger, or its `Status:` line is `closed`): write a fresh ledger with `Status: active`, then attempt `create_goal` with the objective: "Run the `$refine-plan` loop on <artifact path(s)> until converged: a run with no changes, a prose-only round, or remaining findings that do not justify another re-run. Loop state: `.turbo/loops/<slug>.md`; re-read it after any context compaction and do not re-adjudicate findings it records as rejected. Mark this goal complete when the loop converges." If an unfinished goal already exists, an outer workflow owns it; continue without creating one.
- **Continuing loop** (`Status: active`): this invocation is the iteration after the last one the ledger records, whether a Step 5 re-run or a resumption after an interruption. Continue from the recorded state. If no unfinished goal exists, attempt `create_goal` with the same objective as a fresh loop.
- **During each iteration:** have the ledger path in context when Step 3 runs so recorded verdicts are honored. After Step 5's classification, append the iteration number, the round's applied and rejected verdicts with reasons, and the classification.
- **Convergence stop** (a run with no changes, a prose-only round, or a further re-run judged pointless): set `Status: closed`; if this loop created the goal, mark it complete with `update_goal`. An inherited goal stays active for the outer workflow. A halt on an unresolved failure leaves `Status: active` and the goal untouched, so the next invocation resumes the recorded state.

## Step 2: Run `$review-plan` Skill

Run the `$review-plan` skill on the resolved artifact.

Always run this step even if the artifact looks polished.

## Step 3: Run `$evaluate-findings` Skill

Run the `$evaluate-findings` skill on the review findings from Step 2.

## Step 4: Run `$apply-findings` Skill

Run the `$apply-findings` skill on the evaluated results.

## Step 5: Re-run `$refine-plan` Skill if Changed

Check whether the artifact file(s) were edited during Step 4. Any edit counts.

Iteration 1 is the initial run; iteration 2 is the first auto-re-run; and so on. The loop is not capped; it terminates on its own: when a run makes no changes, when a round makes only prose-only edits, or when you judge a further re-run pointless.

**If changes were made**, classify what Step 4 edited:

- **Structural edits** — run `$refine-plan` again by reading and following the installed skill instructions, passing the artifact type and resolved path. If the round contains both structural and prose-only edits, treat it as structural and re-run automatically.
- **Prose-only edits only** (reworded sentences in place, fixed stale examples, clarified existing text without changing meaning) — the loop has converged. Output a summary of what changed and stop; do not re-run.

**If changes were made but you judge a re-run unnecessary**, output a summary of what changed and your reasoning for stopping, then stop instead of re-running.

Judge convergence by the trend across iterations: when rounds have stopped surfacing defects (contradictions, infeasible steps, missing requirements) and keep surfacing improvements of kinds earlier rounds already applied, a further re-run is pointless even though the edits were structural. A round that surfaces no defects is the termination signal; never add a confirmation round, an extra reviewer, or review steps beyond this skill's own.

**When the same class of defect recurs across iterations**, stop patching the individual instance and instead write the root-cause invariant into the artifact itself, enumerating the worked failures it must prevent. Treat recurrence on a new axis of the same invariant as a signal that the invariant is incomplete: widen it to cover the new axis rather than assuming the latest fix failed.

The re-invocation is a full, fresh run of this skill. Every step (1-5) executes with its own task tracking and skill invocations.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

### Structural Edit Examples by Type

- **Plan** — added or removed steps, new or removed design decisions, rewired dependencies between steps, changed testing strategy
- **Shells** — added or removed shells, changed Produces/Consumes/Covers Spec Requirements wiring, changed frontmatter `depends_on`, added or removed spec requirement coverage
- **Spec** — added or removed sections, new or removed requirements, rewired cross-references, changed acceptance criteria

## Rules

- Every step must run in every iteration. `$evaluate-findings` is a judgment gate that must run before `$apply-findings` touches the artifact. Each step must invoke its designated skill by reading and following the installed skill instructions.
- Re-invocations from Step 5 are full runs with fresh task tracking and complete skill invocations.
- Besides the loop ledger and workflow-state bookkeeping under `.turbo/`, the artifact file(s) are the only files that should change. For shells, do not modify the source spec.
