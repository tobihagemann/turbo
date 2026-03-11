---
name: plan-implementation
description: This skill should be used when the user asks to "plan this implementation", "break this into steps", "help me plan the work", "decompose this into tasks", "create an implementation plan", "how should I break down this project", "size this work", or wants methodology for decomposing work into well-sized, well-ordered units and planning each one thoroughly.
---

# Plan Implementation

Methodology for decomposing work into implementation units and planning each one. Use this skill standalone or as a reference from other planning skills.

## Decomposition

### Sizing

- One unit = one logical unit of work (a feature, a subsystem, a layer)
- Never split tightly-coupled pieces across units (if UI + API + tests are inseparable, keep them together)
- Split independent subsystems into separate units
- If a unit would touch more than ~15-20 files or span 3+ unrelated subsystems, split further
- If the entire scope fits one session, produce a single unit — do not over-decompose
- Each unit must leave the codebase fully integrated — never leave components unreachable from the project's entry points

### Ordering

Order by dependency — foundational work before dependent work:

1. Setup and scaffolding (project init, config, CI)
2. Data and domain layer (models, schemas, types)
3. Core business logic
4. API and service layer
5. UI and frontend
6. Integration and end-to-end concerns
7. Finalization (QA, commit, PR — always last)

## Adaptation

When a plan meets reality, adjust for divergence before executing:

- **File paths changed** — update references to match actual structure
- **Architecture evolved** — adjust the plan to work with what was actually built
- **Scope shifted** — add or remove items based on what prior work produced
- **New information** — incorporate discoveries from previous sessions

Keep adaptations minimal — adjust only what diverged, do not rewrite plans unnecessarily.

## Planning Each Unit

For each unit of work, plan the implementation thoroughly:

1. **Explore the codebase** — read files relevant to the unit's scope, understand existing patterns, find code to build on
2. **Design the implementation** — determine what files to create or modify, what approach to take, what tests to write
3. **Write a detailed plan** — specific enough to execute: exact file paths, function signatures, data flow, test cases
4. **Include a task list** — one task per step in the plan
5. **Include relevant skills** — identify which skills apply and instruct: "After plan approval and before making edits, run `/skill-a`, `/skill-b`."

## Rules

- Split conservatively when scope is ambiguous (smaller units are safer than oversized ones)
- Each unit must be self-contained with enough context to understand the work without reading the full plan
- Never merge setup and finalization into the same unit
