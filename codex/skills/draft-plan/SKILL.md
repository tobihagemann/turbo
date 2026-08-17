---
name: draft-plan
description: "Produce an implementation plan at .turbo/plans/<slug>.md. Use when the user asks to \"draft a plan\", \"draft the plan\", \"write an implementation plan\", \"plan this change\", \"create an implementation plan\", or needs a first-draft plan file before refinement."
---

# Draft Plan

Produce an implementation plan at `.turbo/plans/<slug>.md`. Capture the task, survey patterns, escalate decisions, discuss, and draft.

## Task Tracking

Use `update_plan` to track each step, restating any remaining steps of a parent workflow alongside them:

1. Capture the task and pick a slug
2. Run `$survey-patterns` skill
3. Consult task-specific skills and docs
4. Escalate product decisions
5. Deep-dive discussion
6. Draft and write the plan file
7. Present summary and finalize

## Step 1: Capture the Task and Pick a Slug

Absorb the user's request without interrupting. Restate the goal in one or two sentences and confirm.

Generate a slug for the plan file from the task title:

- Lowercase
- Replace non-alphanumeric characters with hyphens
- Collapse consecutive hyphens
- Trim leading and trailing hyphens
- Truncate to 40 characters at a word boundary

Example: "Add a caching layer to the image pipeline" → `add-a-caching-layer-to-the-image-pipeline`.

If `.turbo/plans/<slug>.md` already exists, append `-2`, `-3`, etc. until the path is free. Do not overwrite.

The user may pass an explicit slug or output path in their request (e.g., "draft plan as `auth-rewrite`"). If so, honor it. If `.turbo/plans/<slug>.md` exists in that case, use `request_user_input` to ask whether to overwrite, append a numeric suffix, or pick a different slug.

A path to a file that already exists is background input rather than an output destination. Treat it as the output path only when the request says so explicitly.

State the chosen slug and the resulting plan path before continuing.

### Background Document as Input

If a path to a background document is passed as input (a design doc, an issue, a written proposal), treat it as the source of truth for product decisions and discussion areas. Read it, then:

- In Step 4, skip escalation for any product decision the document resolves. Only escalate questions it did not answer.
- In Step 5, skip deep-dive areas the document covers. Only discuss areas it did not address.
- Confirm the deployment's bounds with the user even when the document states them, rather than carrying them over as settled.

A question is resolved only when the document makes a definitive statement that answers it. Mentions without a chosen direction, open questions, and deferred decisions do not count as resolved; escalate those normally.

Step 2 (pattern survey) and Step 3 (consult skills and docs) still run in full. The document describes what; `$draft-plan` still surveys how.

## Step 2: Run `$survey-patterns` Skill

Run the `$survey-patterns` skill with the confirmed task description. Keep the returned findings in conversation context for use in Steps 5 and 6.

## Step 3: Consult Task-Specific Skills and Docs

Ground library and framework choices in current reality before escalating decisions.

1. **Scan for matching skills.** Compare the task description against available skill trigger descriptions. For each unambiguous match, run the skill by reading and following the installed skill instructions. This loads decision-level guidance (idiomatic patterns, known pitfalls, version constraints) before product decisions are made. If unsure, do not load.
2. **Look up library docs.** For libraries or frameworks the task clearly depends on, query documentation MCP tools (or web search as a fallback) when the decision hinges on current library state such as whether a feature exists, which versions support it, or whether an API has been deprecated.

Keep findings at the decision level: what a library can do, which approach is idiomatic, which version to target. Do not embed specific API signatures or code snippets into the plan. Those belong at execution time, where the same skills are re-loaded.

## Step 4: Escalate Product Decisions

Identify product or design decisions the user's request did not resolve. Escalate these via `request_user_input` before drafting steps.

**Escalate when:**

- A plan step requires choosing between user-facing behaviors the request did not specify (opt-in vs opt-out, strict vs lenient, sync vs async)
- The plan assumes product requirements that were not stated
- Design trade-offs affect UX or product direction rather than technical implementation
- Multiple valid approaches exist and the choice is a matter of product preference, not technical merit
- The plan would introduce a pattern not yet established in this codebase, or follow one sourced from outside it
- The plan adds consistency or durability machinery (a lease, lock, queue, versioning scheme, or new persistent entity) that no stated requirement or deployment bound demands; carrying that machinery is itself a product decision

**Do not escalate** technical decisions the agent can make autonomously: which data structure, which existing pattern to follow, internal implementation approach. The boundary is product intent.

**Confirm external constraints before escalating.** When an option depends on a third-party API, service, or platform behaving a particular way, drop it unless that behavior is confirmed by current documentation.

Present each decision as a concise trade-off with options. Mark the strongest option "(Recommended)" and place it first. Draft plan steps that depend on these decisions only after the user responds.

Offer a **Get a second opinion** option whenever the decision is costly to reverse (it establishes a pattern others will follow, defines an interface, commits to a data shape, or imports a pattern the codebase has not used), and whenever no option earns "(Recommended)" with conviction. It runs the `$consult-claude` skill for what each option commits to, what reversing it costs, and what the prevailing convention is. Hold the concrete options to two so the question stays within the three-option limit. Then resolve the decision with that answer in hand, re-asking when the choice stays the user's.

## Step 5: Deep-Dive Discussion

Interview the user relentlessly about every aspect of the implementation shape until you reach shared understanding. Use `request_user_input`, one question at a time. Use the pattern survey findings to frame choices. Cover whichever of these matter for the task. Do not present a rigid checklist.

Settle the first two rows before the rest, so implementation choices land against concrete outcomes and bounds instead of being taken in the abstract. When the user jumps to implementation shape early, engage briefly then circle back.

| Area | What to explore |
|---|---|
| **Outcomes** | What must be true when this is done? The observable behaviors that decide whether it worked, and the acceptance criteria that pin each one. |
| **Bounds** | How many users and operators, now and realistically? Concurrent writers? Which rigor tier is proportionate — personal tool, small team, or business-critical — and what failure tolerance does that imply? |
| **Constraints** | Which non-functional requirements apply: performance, security, accessibility, i18n, compliance? Which tech-stack, hosting, or integration choices does the work commit to? |
| **Reuse vs new** | Which survey findings should the new work build on? Which should it deliberately not follow, and why? |
| **File placement** | Where do new files live? Which existing files are modified? |
| **Data flow** | How does data move through the change? Any new boundaries or contracts? |
| **Edge cases** | Partial failure, empty states, backward compatibility, concurrency |
| **Tests** | Which existing test patterns apply? Where do new tests live? |
| **Scope cut** | Anything to explicitly defer? |

### Discussion Guidelines

- If a question can be answered by exploring the codebase, explore the codebase instead.
- When a question defines a boundary, contract, or data shape, add a **Get a second opinion** option and hold the concrete options to two so the question stays within the three-option limit. It runs the `$consult-claude` skill for the soundest answer on technical merit alone, independent of the task's original scope; on a question of product intent, run it for what each answer commits to and what reversing it costs. Then resolve the question with that answer in hand, re-asking when the choice stays the user's.
- Pair each question with a recommendation and the reasoning behind it, so the discussion stays collaborative.
- Walk down each branch of the design tree, resolving dependencies between decisions one-by-one.
- When the user says "you decide," make the call and explain why.
- Probe short answers before moving on.
- When the shape is clear or the user signals readiness, confirm before drafting.

## Step 6: Draft and Write the Plan File

Synthesize the task description, pattern survey findings, consulted skill and doc context, resolved product decisions, and deep-dive discussion outcomes into a complete plan document.

Create `.turbo/plans/` if it does not exist. Write the plan to `.turbo/plans/<slug>.md` using the slug picked in Step 1 (or the override path from Step 1) using this structure:

````markdown
---
status: draft
---

# Plan: <Task Title>

## Context

<Why this change is being made — the problem or need it addresses, what prompted it, the intended outcome. One or two paragraphs.>

<The deployment's bounds: user and operator count, concurrency, the rigor tier, and the failure tolerance it implies. One or two sentences.>

## Acceptance Criteria

What must be true when this is done:

- When <trigger or condition>, the system shall <expected behavior>.
- As a <persona>, I want <capability> so that <outcome>.
  - Acceptance: <criterion>

## Pattern Survey

<Insert the structured findings from `$survey-patterns`: Analogous Features, Reusable Utilities, Convention Anchors, Proposed Alignment. Use the same format the survey returned.>

## Implementation Steps

1. **<Step 1 title>**
   - <Concrete action with `file_path` references and named functions or symbols>
   - <Another action>
2. **<Step 2 title>**
   - ...
3. ...

## Verification

How to verify the change works end-to-end after implementation:

- <Specific test command, manual smoke check, or MCP tool invocation>
- <Expected observable result for each verification step>
- <Edge cases to spot-check>

## Context Files

Files to read in full before starting implementation:

- `<path/to/file1>` — <why it matters>
- `<path/to/file2>` — <why it matters>
- ...
````

### Content Rules for the Plan

- **Context**: State the deployment's bounds explicitly. Downstream review judges whether the plan's machinery is proportionate against these bounds, so a plan that omits them leaves that judgment ungrounded.
- **Acceptance Criteria**: State observable outcomes, not implementation steps. Use the behavioral form or the user-story form per criterion; both can appear in one plan. Every criterion with observable behavior must be exercised by the Verification section. Omit this section only when the change has no observable behavior, which the Verification section already records.
- **Implementation Steps**: Use concrete `file_path` references and named functions or symbols. Reference existing functions and utilities from the Pattern Survey instead of reinventing them. Each step describes a discrete unit of work that can be tracked independently during execution.
- **Verification**: Describe how to know the change actually works. Prefer specific test commands, named test files, or named smoke checks over vague phrases like "run the tests." If the change has no observable behavior, say so explicitly. When citing an existing test as proof that a behavior is already pinned, first confirm the test asserts the real value or behavior at issue rather than a fixture or the pass-through of a fabricated argument.
- **Context Files**: Curate the minimum set needed to become productive. Do not dump every file touched — only the ones that anchor understanding.
- **Scope**: Plan content describes what to build. Do not embed task tracking, skill loading, `$finalize` invocation, test commands, or commit instructions in the plan content — those are execution-wrapper concerns.

## Step 7: Present Summary and Finalize

Present a brief summary of the drafted plan: the essence of what it builds and the key decisions behind it, short enough to read at a glance so the user does not have to read the full plan file. When the plan delivers value to a user, developer, or operator, also present a short list of stories capturing what that person gains, in the form "As a <persona>, I want <capability> so that <outcome>". Skip the stories only when no beneficiary or outcome can be named, such as a purely mechanical refactor. Fit both to the plan rather than a fixed template.

Then use `request_user_input` to offer two paths:

- **Approve** (Recommended) — the plan is final.
- **Revise** — the user describes what to change. Apply the edits to the plan file, then re-summarize and re-present.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

## Rules

- Never skip the pattern survey.
- Never skip decision escalation for questions left unanswered. When entering from a Background Document as Input, questions the document already resolves are considered answered and may be skipped.
- The plan file and workflow-state bookkeeping under `.turbo/` are the only outputs. Do not write code, scaffolding, or other project files.
- Do not run `$review-plan` or any review skills here.
