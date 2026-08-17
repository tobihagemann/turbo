# Plan Scope Review Reference

## Review Instructions

Read project context (AGENTS.md and files mentioned in the plan) to understand what already exists. Review whether the plan builds more than its acceptance criteria and stated bounds justify.

Identify the plan's acceptance criteria and its stated bounds (Context or the original ask) before judging any step. A step is in scope when a criterion or bound calls for it.

## What to Review

- **Scope** — Acceptance criteria addressed without creep
- **YAGNI** — Steps that build something no acceptance criterion asks for: unrequested features, premature abstractions, or scaffolding for anticipated work
- **Design Direction** — Whether the chosen approach is the simplest safe option. Challenge assumptions the plan depends on and flag when a different approach would be safer or simpler
- **Proportionality** — Steps whose machinery (leases, locks, queues, versioning schemes, state machines, new persistent entities) exceeds the failure modes and scale the plan's Context admits
- **Self-Referential Justification** — Mechanism justified by a failure mode that exists only because that mechanism is present. Trace each justification back to a criterion or bound; when the chain closes on itself, test whether cutting the mechanism removes its dependents rather than judging each link alone

## Determination Criteria

Flag an issue only when ALL of these hold:

1. The plan builds something its acceptance criteria and stated bounds do not justify, or takes an approach a safer or simpler one would replace
2. The issue is discrete and actionable, naming the cut, the merge, or the alternative approach
3. The finding cites the criterion or bound that fails to justify the work, or the concrete advantage the alternative approach holds

A deliberate design choice is in range here: name the choice and the evidence against it rather than treating the author's intent as settling the question.

## Priority Levels

- **P0** — The approach as a whole builds substantially more than the acceptance criteria ask for
- **P1** — A step or abstraction no acceptance criterion stands behind, or an approach a materially safer or simpler one would replace
- **P2** — Machinery disproportionate to the stated bounds, or a step that folds into a neighbor
- **P3** — Minor simplification

## What to Ignore

- Alternative approaches without evidence of concrete advantages over the chosen one
- A step the dependency chain or a stated constraint requires, even when folding it into a neighbor would shorten the plan; a dependency the reviewed mechanism itself creates does not count as such a constraint
- Input validation at trust boundaries, error handling that prevents data loss, security controls, and accessibility affordances; these stay even when the acceptance criteria do not name them
