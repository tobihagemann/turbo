---
name: draft-plan
description: "Guide a collaborative discussion that produces an implementation plan at .turbo/plan.md. Grounds the plan in existing patterns, escalates product decisions, and produces a file that survives a fresh session. Use when the user asks to \"draft a plan\", \"draft the plan\", \"write an implementation plan\", \"plan this change\", \"create an implementation plan\", or needs a first-draft plan file before refinement."
---

# Draft Plan

Collaborate with the user to produce an initial implementation plan at `.turbo/plan.md`. The output is a draft — refinement happens in `/refine-plan`.

## Task Tracking

At the start, use `TaskCreate` to create a task for each step:

1. Capture the task
2. Run `/survey-patterns` skill
3. Escalate product decisions
4. Deep-dive discussion
5. Draft the plan file

## Step 1: Capture the Task

Absorb the user's request without interrupting. Restate the goal in one or two sentences and confirm.

If an existing `.turbo/plan.md` is present, use `AskUserQuestion` to ask whether to overwrite it or pick a different path. The plan file follows a fixed template, so merging or appending into an existing plan is out of scope.

## Step 2: Run `/survey-patterns` Skill

Run the `/survey-patterns` skill with the confirmed task description. Keep the returned findings in conversation context for use in Steps 4 and 5.

## Step 3: Escalate Product Decisions

Identify product or design decisions the user's request did not resolve. Escalate these via `AskUserQuestion` before drafting steps.

**Escalate when:**

- A plan step requires choosing between user-facing behaviors the request did not specify (opt-in vs opt-out, strict vs lenient, sync vs async)
- The plan assumes product requirements that were not stated
- Design trade-offs affect UX or product direction rather than technical implementation
- Multiple valid approaches exist and the choice is a matter of product preference, not technical merit

**Do not escalate** technical decisions the agent can make autonomously: which data structure, which existing pattern to follow, internal implementation approach. The boundary is product intent.

Present each decision as a concise trade-off with options. Draft plan steps that depend on these decisions only after the user responds.

## Step 4: Deep-Dive Discussion

Work through the implementation shape with the user via `AskUserQuestion`, one or two questions at a time. Use the pattern survey findings to frame choices. Cover whichever of these matter for the task — do not present a rigid checklist:

| Area | What to explore |
|---|---|
| **Reuse vs new** | Which survey findings should the new work build on? Which should it deliberately not follow, and why? |
| **File placement** | Where do new files live? Which existing files are modified? |
| **Data flow** | How does data move through the change? Any new boundaries or contracts? |
| **Edge cases** | Partial failure, empty states, backward compatibility, concurrency |
| **Tests** | Which existing test patterns apply? Where do new tests live? |
| **Scope cut** | Anything to explicitly defer? |

### Discussion Guidelines

- Make recommendations with reasoning, not just questions. Be a collaborator, not an interviewer.
- When the user says "you decide," make the call and explain why.
- Probe short answers before moving on.
- When the shape is clear or the user signals readiness, confirm before drafting.

## Step 5: Draft the Plan File

Create `.turbo/` if it does not exist. Write the plan to `.turbo/plan.md` (or the override path from Step 1) using this structure:

````markdown
# Plan: <Task Title>

## Context

<Why this change is being made — the problem or need it addresses, what prompted it, the intended outcome. One or two paragraphs.>

## Pattern Survey

<Insert the structured findings from `/survey-patterns`: Analogous Features, Reusable Utilities, Convention Anchors, Proposed Alignment. Use the same format the survey returned.>

## Implementation Steps

1. **<Step 1 title>**
   - <Concrete action with `file_path:line_number` references>
   - <Another action>
2. **<Step 2 title>**
   - ...
3. ...

## Context Files

Files to read in full before starting implementation:

- `<absolute/path/to/file1>` — <why it matters>
- `<absolute/path/to/file2>` — <why it matters>
- ...
````

The plan file focuses on the plan itself. It does not include Turbo-specific execution protocol (task tracking, skill loading, `/finalize` invocation). That protocol is `/implement-plan`'s job.

### Content Rules for the Plan

- **Implementation Steps**: Use concrete `file_path:line_number` references. Reference existing functions and utilities from the Pattern Survey instead of reinventing them. Each step describes a discrete unit of work that can be tracked independently during execution.
- **Context Files**: Curate the minimum set needed to become productive. Do not dump every file touched — only the ones that anchor understanding.
- **Scope**: Plan content describes what to build, not how to execute it. Instructions like "run the test suite" or "commit the changes" belong in the execution wrapper, not the plan.

## Rules

- Never skip Step 2 (`/survey-patterns`). A plan without pattern grounding misses reuse and drifts from codebase conventions.
- Never skip Step 3 (escalation). Product decisions baked in without asking become rework.
- The plan file is the only output. Do not write code, scaffolding, or other project files.
- Do not run `/review-plan` or any review skills here. Refinement is `/refine-plan`'s job.
- Do not embed Turbo execution protocol (Task Tracking, Load skills, Run `/finalize`) in the plan file. Those belong in `/implement-plan`.
