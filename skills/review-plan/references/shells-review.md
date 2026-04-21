# Shells Review Reference

## Review Instructions

Shells review focuses on structural wiring, not broad codebase patterns. Skip sweeping project-context reads — but spot-check any concrete codebase element a shell names (function, file, type, API surface) to verify it exists and can carry the contract the shell assigns to it. A shell whose Produces or Consumes cites a nonexistent or misdescribed seam is a structural wiring bug.

## What to Review

- **Spec coverage** — The union of every shell's `Covers Spec Requirements` field must equal the set of requirements in the source spec. Flag any requirement not covered by any shell. Partial coverage must be marked `(partial: <what's deferred>)` with the deferred work named in that shell's Open Questions.
- **Wiring** — Every entry in a shell's `Consumes` field must trace to a prior shell's `Produces` entry (check dependency ordering via `depends_on` frontmatter) or an explicit "from existing codebase" annotation. Flag missing prerequisites (Consumes with no source), dead ends (Produces not consumed by any later shell and not part of the final system's entry points), and implicit dependencies (Consumes tracing to a shell not in `depends_on`).
- **Cited-element accuracy** — For each external resource a shell names (file path, function, type, API surface, codebase reference, documentation link), open the cited target and verify it exists and supports the contract the shell assigns to it. Wrong citations pass spec-text review and surface later as unimplementable shells.
- **Completeness** — Walk through shells in dependency order, accumulating Produces. After the final shell, verify every spec requirement is satisfied by a reachable component. No component should be orphaned.
- **No duplication** — `Covers Spec Requirements` fields across shells must be disjoint. Flag any requirement appearing in more than one shell. If two shells intentionally touch the same area, the requirement should still map to exactly one.

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
