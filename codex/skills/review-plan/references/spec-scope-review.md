# Spec Scope Review Reference

## Review Instructions

Read project context (AGENTS.md and any existing codebase) to understand what already exists. Review whether the spec asks for more system than its purpose and stated bounds justify.

Identify the spec's stated bounds before judging any requirement — the deployment, the user count, the operating assumptions, wherever the spec states them (Overview, Users, or a requirement). A requirement is in scope when the spec's purpose or a stated bound calls for it.

## What to Review

- **Scope** — Spec focuses on a coherent system. No unconnected components or features that serve no specified consumer
- **YAGNI** — Unrequested features, over-engineering, or premature abstractions that add complexity without clear value
- **Design Direction** — Whether the proposed system design is the simplest safe option. Challenge assumptions about users, environment, or dependencies and flag when a different approach would be safer or simpler
- **Proportionality** — Requirements or acceptance criteria whose machinery (leases, locks, queues, versioning schemes, state machines, new persistent entities) exceeds the failure modes and scale the spec's own stated bounds admit

## Determination Criteria

Flag an issue only when ALL of these hold:

1. The spec asks for something its purpose and stated bounds do not justify, or proposes a design a safer or simpler one would replace
2. The issue is discrete and actionable, naming the cut or the alternative design
3. The finding cites the bound or purpose that fails to justify the requirement, or the concrete advantage the alternative design holds

A deliberate design choice is in range here: name the choice and the evidence against it rather than treating the author's intent as settling the question. A requirement the user confirmed during the drafting discussion still qualifies when the spec's own bounds do not support it.

## Priority Levels

- **P0** — The system as specified is substantially larger than its purpose requires
- **P1** — A feature or component no stated purpose stands behind, or a design a materially safer or simpler one would replace
- **P2** — Machinery disproportionate to the stated bounds
- **P3** — Minor simplification

## What to Ignore

- Alternative architectural approaches without evidence of concrete advantages over the chosen one
- A requirement other requirements or the spec's stated bounds depend on, even when removing it would simplify the design
- Input validation at trust boundaries, error handling that prevents data loss, security controls, and accessibility affordances; these stay even when no requirement names them
