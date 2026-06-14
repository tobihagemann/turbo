---
name: assess-technical-debt
description: "Assess project-wide structural technical debt: complexity hotspots, deprecated API usage, duplication clusters, and architecture rot. Ranks findings by impact and refactor effort into a report at .turbo/technical-debt.md. Use when the user asks to \"assess technical debt\", \"find technical debt\", \"review technical debt\", \"what should we refactor\", \"find refactoring candidates\", \"where is the code rot\", or \"what's our worst code\". Analysis-only — does not modify code."
---

# Assess Technical Debt

Surface the structural debt that routine review keeps out of scope: long-lived complexity, deprecated APIs, duplication, and tangled architecture that need deliberate refactoring. Project-wide, analysis-only. Ranks each finding by impact and effort and writes `.turbo/technical-debt.md` and `.turbo/technical-debt.html`.

## Task Tracking

At the start, use `update_plan` to track each phase:

1. Scope and partition
2. Run debt analysis agents
3. Run the `$evaluate-findings` skill
4. Rank and write markdown report
5. Generate HTML report

## Step 1: Scope and Partition

If `$ARGUMENTS` specifies paths, assess those directly (skip the question).

Otherwise, use `request_user_input` to confirm scope:

- **All source files** — assess the whole codebase
- **Specific paths** — user provides directories or file patterns

Once scope is determined:

1. Glob for source files in the selected scope. Exclude generated and vendored directories (`node_modules/`, `dist/`, `build/`, `vendor/`, `__pycache__/`, `.build/`, `DerivedData/`, `target/`, `.tox/`, and others appropriate to the project).
2. Partition files by top-level source directory. If a single directory holds far more files than its siblings, sub-partition it by its immediate subdirectories.

## Step 2: Run Debt Analysis Agents

Launch the agents below in parallel with `spawn_agent` / `wait_agent` using inherited model defaults. Each sub-agent's prompt instructs it to read [references/debt-reviewer.md](references/debt-reviewer.md) for the debt taxonomy, detection heuristics, the impact/effort rubric, and the finding output format before scanning.

Expect (one per partition, plus one project-wide architecture agent) Codex sub-agent calls total. State the count explicitly before emitting the batch.

- **Partition agents** — one per partition from Step 1. Each scans its files for complexity hotspots, deprecated API usage, and duplication, and notes coupling it observes reaching outside the partition. Pass the partition's file list and the full project root path.
- **Architecture agent** — one project-wide pass over the scoped tree for architecture rot: tangled module boundaries, circular dependencies, layering violations, and refactor candidates that span modules. Pass the partition map and the full project root path.

If more partitions exist than fit a single fan-out, group related directories so the partition agents stay within a manageable batch, and note the grouping in the report.

## Step 3: Run `$evaluate-findings` Skill

Aggregate all findings from all agents. Deduplicate items that surface in more than one agent (e.g., duplication a partition agent and the architecture agent both flag). Run the `$evaluate-findings` skill once on the combined set to verify each finding against the actual code and weed out false positives.

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
This assessment covers in-code structural debt. For dependency freshness, dead code, and diff-scoped bugs, run `$review-dependencies`, `$find-dead-code`, and `$review-code`.
```

## Step 5: Generate HTML Report

Convert the markdown report into a styled, interactive HTML page.

1. Run the `$frontend-design` skill to load design principles.
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

Then update or check the active plan and proceed to any remaining task.

## Rules

- Analysis-only: do not modify source code, stage files, or commit.
- If no significant debt is found, report that explicitly and note any scope limitations or analysis caveats.
