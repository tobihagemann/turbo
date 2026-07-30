# Shells Scope Review Reference

## Review Instructions

Shells scope review covers whether the decomposition earns the sessions it costs. Skip sweeping project-context reads. Read the source spec's `## Requirements` section and its stated bounds, then read every shell's `depends_on` frontmatter plus its Context, Produces, Consumes, and Covers.

## What to Review

- **Proportionality** — A decomposition finer than the spec's requirements and stated bounds justify: a shell whose Produces another shell already carries, or a split the work does not need. Each shell costs a full expansion and implementation session, so name the merge or the cut.

## Determination Criteria

Flag an issue only when ALL of these hold:

1. The decomposition costs a session the spec's requirements and stated bounds do not justify, or a shell produces what another shell already produces
2. The issue is discrete and actionable, naming which shells merge or which shell is cut
3. The finding accounts for the dependency chain: the proposed merge leaves no `Consumes` entry ahead of its `Produces`

A deliberate design choice is in range here: name the choice and the evidence against it rather than treating the author's intent as settling the question.

## Priority Levels

- **P0** — The decomposition as a whole costs substantially more sessions than the work requires
- **P1** — A shell whose Produces another shell already carries
- **P2** — A split the work does not need, where the merge is clean
- **P3** — Minor consolidation

## What to Ignore

- A split the dependency chain or session load requires, even when the resulting shells are small
- A shell that carries prerequisite work a later shell consumes, even when it claims no `R<N>` of its own
