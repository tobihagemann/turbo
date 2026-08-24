---
name: discuss-change
description: "Align on the shape of a change through an interview, then implement it. Escalates open product decisions and settles the implementation shape in conversation. Use when the user asks to \"discuss this change\", \"align on this change first\", \"ask me questions first\", \"interview me then implement\", \"agree on the approach before coding\", or wants the shape of a single change settled before any code is written."
---

# Discuss Change

Escalate open decisions, agree on the implementation shape, then implement.

## Task Tracking

Use `TaskCreate` to create a task for each step:

1. Capture the task
2. Escalate product decisions
3. Deep-dive discussion
4. Confirm the shape
5. Run `/implement` skill

## Step 1: Capture the Task

Absorb the request without interrupting. Take the task from the user's request, or from conversation context when the task was already established. Restate the goal in one or two sentences and confirm.

## Step 2: Escalate Product Decisions

Identify product or design decisions the request did not resolve. Escalate these via `AskUserQuestion` before any code is written. Read the code the change would touch before judging whether a bullet matches. **Skip** when no bullet below matches the change.

**Escalate when:**

- The change requires choosing between user-facing behaviors the request did not specify (opt-in vs opt-out, strict vs lenient, sync vs async)
- The change assumes product requirements that were not stated
- Design trade-offs affect UX or product direction rather than technical implementation
- Multiple valid approaches exist and the choice is a matter of product preference, not technical merit
- The change would introduce a pattern not yet established in this codebase, or follow one sourced from outside it
- The change adds consistency or durability machinery (a lease, lock, queue, versioning scheme, or new persistent entity) that no stated requirement demands; carrying that machinery is itself a product decision

**Do not escalate** technical decisions the agent can make autonomously: which data structure, which existing pattern to follow, internal implementation approach. The boundary is product intent.

**Confirm external constraints before escalating.** When an option depends on a third-party API, service, or platform behaving a particular way, query documentation MCP tools (or WebSearch as a fallback) and drop the option unless current documentation confirms that behavior.

Output what is at stake as text first, even when the reading it came from is fresh in this conversation. When the decision turns on a failure or misuse scenario, that means the invariant the change would protect and what makes that scenario reachable given the existing guards. Then use `AskUserQuestion` to present the decision as a concise trade-off with options. Mark the strongest option "(Recommended)" and place it first.

Offer a **Get a second opinion** option whenever the decision is costly to reverse (it establishes a pattern others will follow, defines an interface, commits to a data shape, or imports a pattern the codebase has not used), and whenever no option earns "(Recommended)" with conviction. It runs the `/consult-codex` skill for what each option commits to, what reversing it costs, and what the prevailing convention is. Hold the concrete options to three so the question stays within the four-option limit. Then resolve the decision with that answer in hand, re-asking when the choice stays the user's.

## Step 3: Deep-Dive Discussion

Interview the user about the implementation shape until you reach shared understanding. Use `AskUserQuestion`, one question at a time. Cover whichever of these matter for the task. Do not present a rigid checklist. **Skip** when the request and the resolved decisions already name the files to touch, the existing code to build on, and the tests to write.

| Area | What to explore |
|---|---|
| **Prototype unknowns** | What does the surface look like, and does the interaction pattern make sense in the hand? Separate these from ordinary design questions by whether an answer in prose would still leave the user guessing. |
| **Reuse vs new** | Which existing code should the change build on? Which patterns should it deliberately not follow, and why? |
| **File placement** | Where do new files live? Which existing files are modified? |
| **Data flow** | How does data move through the change? Any new boundaries or contracts? |
| **Edge cases** | Partial failure, empty states, backward compatibility, concurrency |
| **Tests** | Which existing test patterns apply? Where do new tests live? |
| **Scope cut** | Anything to explicitly defer? |

### Discussion Guidelines

- If a question can be answered by exploring the codebase, explore the codebase instead.
- When a question defines a boundary, contract, or data shape, add a **Get a second opinion** option and hold the concrete options to three so the question stays within the four-option limit. It runs the `/consult-codex` skill for the soundest answer on technical merit alone, independent of the task's original scope; on a question of product intent, run it for what each answer commits to and what reversing it costs. Then resolve the question with that answer in hand, re-asking when the choice stays the user's.
- When a question turns on how a surface looks or how an interaction behaves, and an answer in prose would leave the user guessing, add a **Prototype it first** option and hold the concrete options to three so the question stays within the four-option limit. It runs the `/prototype` skill on that unknown, then asks the question again with the prototype in hand.
- Pair each question with a recommendation and the reasoning behind it, so the discussion stays collaborative.
- When the user says "you decide," make the call and explain why.
- Probe short answers before moving on.
- Stop once the shape is clear or the user signals readiness.

## Step 4: Confirm the Shape

Output the agreed shape as text, short enough to read at a glance: what the change does, where it lands, the decisions resolved in Steps 2 and 3, how to tell it worked, and anything deliberately deferred. This text is the change description Step 5 implements, so keep it concrete enough to act on.

Then use `AskUserQuestion` to offer these paths:

- **Approve** (Recommended) — the shape is settled.
- **Revise** — the user describes what to change. Apply the correction, then re-present the shape.
- **Prototype first** — offer this path when an unknown that only a built artifact settles is still open. Run the `/prototype` skill, fold what it settled into the shape, then re-present. Mark it "(Recommended)" in place of Approve while such an unknown is open, since a surface or interaction pattern that is still unproven cannot be judged from the shape description.

## Step 5: Run `/implement` Skill

Run the `/implement` skill. The shape confirmed in Step 4 is the change it applies.

Then use the TaskList tool and proceed to any remaining task.

## Rules

- Confine Steps 1 through 4 to reading, discussion, confirmation, and any prototype those steps called for.
- If the work turns out to need writing down — unclear scope surfaces, the approach needs surveying first, or context risks being lost across sessions — stop and tell the user to run `/turboplan` for plan mode.
