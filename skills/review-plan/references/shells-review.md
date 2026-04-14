# Shells Review Reference

## Review Instructions

Shells review focuses on structural wiring, not codebase patterns. Do not read project context.

## What to Review

- **Spec coverage** — The union of every shell's `Covers Spec Requirements` field must equal the set of requirements in the source spec. Flag any requirement not covered by any shell.
- **Wiring** — Every entry in a shell's `Consumes` field must trace to a prior shell's `Produces` entry (check dependency ordering via `depends_on` frontmatter) or an explicit "from existing codebase" annotation. Flag missing prerequisites (Consumes with no source), dead ends (Produces not consumed by any later shell and not part of the final system's entry points), and implicit dependencies (Consumes tracing to a shell not in `depends_on`).
- **Completeness** — Walk through shells in dependency order, accumulating Produces. After the final shell, verify every spec requirement is satisfied by a reachable component. No component should be orphaned.
- **No duplication** — `Covers Spec Requirements` fields across shells must be disjoint. Flag any requirement appearing in more than one shell. If two shells intentionally touch the same area, the requirement should still map to exactly one.
- **Cross-reference accuracy** — Spot-check that referenced external resources (codebases, documentation, APIs) actually exist and are relevant.

## Determination Criteria

Flag an issue only when it would cause implementation problems, incorrect wiring, or spec coverage gaps. The issue must be discrete and actionable.

## Priority Levels

- **P0** — Spec requirement missing from all shells, or shell chain produces a broken system
- **P1** — Dead end, missing prerequisite, or implicit dependency that will cause implementation problems
- **P2** — Moderate issue: duplicated requirement, unclear shell boundary, or ordering improvement
- **P3** — Minor improvement

## What to Ignore

- Stylistic preferences that don't affect wiring or coverage
- Implementation details that belong in the expanded plan, not the shell
