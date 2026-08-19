---
name: assess-technical-debt
description: "Assess project-wide structural technical debt: complexity hotspots, deprecated API usage, duplication clusters, and architecture rot. Ranks findings by impact and refactor effort into a report at .turbo/technical-debt.md. Use when the user asks to \"assess technical debt\", \"find technical debt\", \"review technical debt\", \"what should we refactor\", \"find refactoring candidates\", \"where is the code rot\", or \"what's our worst code\". Analysis-only — does not modify code."
---

# Assess Technical Debt

Surface the structural debt that routine review keeps out of scope: long-lived complexity, deprecated APIs, duplication, and tangled architecture that need deliberate refactoring. Project-wide, analysis-only. Ranks each finding by impact and effort and writes `.turbo/technical-debt.md` and `.turbo/technical-debt.html`.

## Task Tracking

At the start, use `TaskCreate` to create a task for each phase:

1. Scope and partition
2. Run debt analysis agents
3. Run `/evaluate-findings` skill
4. Rank and write markdown report
5. Generate HTML report

## Step 1: Scope and Partition

If `$ARGUMENTS` specifies paths, assess those directly (skip the question).

Otherwise, use `AskUserQuestion` to confirm scope:

- **All source files** — assess the whole codebase
- **Specific paths** — user provides directories or file patterns

Once scope is determined:

1. Glob for source files in the selected scope. Exclude generated and vendored directories (`node_modules/`, `dist/`, `build/`, `vendor/`, `__pycache__/`, `.build/`, `DerivedData/`, `target/`, `.tox/`, and others appropriate to the project).
2. Partition files by top-level source directory. If a single directory holds far more files than its siblings, sub-partition it by its immediate subdirectories.

## Step 2: Run Debt Analysis Agents

Before dispatching, read the project's test configuration and CI workflow to identify any test tier that resets a shared external resource between tests, such as a database, a fixed port, or a cache. Such tiers have no cross-process interlock, so agents running them concurrently wipe each other's state and return failures that look like real defects. Name any such tier to every agent as off-limits.

Emit all Agent tool calls below in one assistant message. Each Agent call uses `model: "opus"` and no `name`. Wait for every agent to report before continuing. Do not begin the next step on a partial set, and do not relaunch an agent that has not yet reported. Each Agent's prompt instructs it to read [references/debt-reviewer.md](references/debt-reviewer.md) for the debt taxonomy, detection heuristics, the impact/effort rubric, and the finding output format before scanning, and to treat the shared working tree and its git index as read-only — any empirical check runs in an isolated `git worktree` created under `$TMPDIR` and discarded afterward. HEAD stays where it is: read other refs with `git show <ref>:<path>` rather than `git checkout` or `git switch`. Give that worktree its own dependency install rather than reaching the shared tree's install by any route: removing a worktree deletes through symlinks, and a redirected suite writes into the shared install. When its own install is not possible, the check is left unrun and reported as such. Afterward the agent verifies that `git worktree list` no longer shows the worktree, that `git status --short` is clean, that HEAD is still on the branch it started on, and that the shared tree's dependency directory still resolves (a destroyed install leaves `git status` clean, since it is gitignored). Damage the agent cannot repair is reported with the exact repair command in place of findings.

Expect (one per partition, plus one project-wide architecture agent) Agent tool calls total. State the count explicitly when emitting the calls.

- **Partition agents** — one per partition from Step 1. Each scans its files for complexity hotspots, deprecated API usage, and duplication, and notes coupling it observes reaching outside the partition. Pass the partition's file list and the full project root path.
- **Architecture agent** — one project-wide pass over the scoped tree for architecture rot: tangled module boundaries, circular dependencies, layering violations, and refactor candidates that span modules. Pass the partition map and the full project root path.

If more partitions exist than fit a single fan-out, group related directories so the partition agents stay within a manageable batch, and note the grouping in the report.

## Step 3: Run `/evaluate-findings` Skill

Aggregate all findings from all agents. Deduplicate items that surface in more than one agent (e.g., duplication a partition agent and the architecture agent both flag). Run the `/evaluate-findings` skill once on the combined set to verify each finding against the actual code and weed out false positives.

## Step 4: Rank and Write Markdown Report

Assign each surviving finding an **impact** (maintenance drag, change risk, blast radius) and an **effort** (rough refactor size) per the rubric in [references/debt-reviewer.md](references/debt-reviewer.md). Sort findings into priority tiers:

- **Quick wins** — high impact, low effort
- **Strategic refactors** — high impact, high effort
- **Incremental** — low-to-medium impact, low effort
- **Defer** — low impact, high effort

Output the summary and priority matrix as text. Then write `.turbo/technical-debt.md` using the template below.

### Report Template

```markdown
# Technical Debt Assessment

**Date:** <date>
**Scope:** <what was assessed>

## Summary

| Dimension | Findings | High impact |
|---|---|---|
| Complexity hotspots | <N> | <N> |
| Deprecated API usage | <N> | <N> |
| Duplication clusters | <N> | <N> |
| Architecture rot | <N> | <N> |

## Priority Matrix

Ranked by impact against refactor effort. Take quick wins first; schedule strategic refactors deliberately.

### Quick Wins (high impact, low effort)
| Item | Dimension | Location | Recommended refactor |
|---|---|---|---|

### Strategic Refactors (high impact, high effort)
| Item | Dimension | Location | Recommended refactor |
|---|---|---|---|

### Incremental (low–medium impact, low effort)
| Item | Dimension | Location | Recommended refactor |
|---|---|---|---|

### Defer (low impact, high effort)
| Item | Dimension | Location | Recommended refactor |
|---|---|---|---|

## Detailed Findings

### Complexity Hotspots
<findings: location, description, impact, effort, recommended refactor>

### Deprecated API Usage
<findings>

### Duplication Clusters
<findings>

### Architecture Rot
<findings>

---
This assessment covers in-code structural debt. For dependency freshness, dead code, and diff-scoped bugs, run `/review-dependencies`, `/find-dead-code`, and `/review-code`.
```

## Step 5: Generate HTML Report

Convert the markdown report into a styled, interactive HTML page.

1. Run the `/frontend-design` skill to load design principles.
2. Read `.turbo/technical-debt.md` for the full report content.
3. Write a self-contained `.turbo/technical-debt.html` (single file, no external dependencies beyond Google Fonts) that presents all findings from the markdown report with:
   - Summary grid with per-dimension finding counts
   - Priority matrix laid out as an impact-by-effort quadrant, color-coded by tier (quick wins highlighted)
   - Sticky navigation between sections
   - Collapsible dimension sections
   - Finding cards with location, impact, effort, and recommended refactor
   - Impact and effort badges with color-coding
   - Entrance animations and hover states
   - Print-friendly styles via `@media print`
   - Responsive layout for mobile

Then use the TaskList tool and proceed to any remaining task.

## Rules

- Analysis-only: do not modify source code, stage files, or commit.
- If no significant debt is found, report that explicitly and note any scope limitations or analysis caveats.
