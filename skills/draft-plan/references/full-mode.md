# Draft Plan: Full Mode

Capture the task, survey patterns, escalate decisions, discuss, and draft the plan in parallel (internal + peer).

## Task Tracking

Use `TaskCreate` to create a task for each step:

1. Capture the task and pick a slug
2. Run `/survey-patterns` skill
3. Escalate product decisions
4. Deep-dive discussion
5. Run two drafts in parallel
6. Reconcile and write the plan file

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

The user may pass an explicit slug or path in their request (e.g., "draft plan as `auth-rewrite`"). If so, honor it. If `.turbo/plans/<slug>.md` exists in that case, use `AskUserQuestion` to ask whether to overwrite, append a numeric suffix, or pick a different slug.

State the chosen slug and the resulting plan path before continuing.

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

Work through the implementation shape with the user via `AskUserQuestion`, one or two questions at a time. Use the pattern survey findings to frame choices. Cover whichever of these matter for the task. Do not present a rigid checklist:

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

## Step 5: Run Two Drafts in Parallel

After the interactive steps (1-4) are complete, draft the plan twice in parallel: once internally and once via `/peer-draft-plan`.

Launch two Agent tool calls in a single message (`model: "opus"`, do not set `run_in_background`):

### Internal Draft

Spawn a subagent and pass it:

- The task description and slug from Step 1
- The pattern survey findings from Step 2
- The product decisions resolved in Step 3
- The deep-dive discussion outcomes from Step 4
- The plan file template and Content Rules from Step 6 below

Instruct it to synthesize the discussion into a complete plan document following the template, returning the full markdown text. The subagent does **not** write to disk; it returns the draft to the caller.

### Run `/peer-draft-plan` Skill

Spawn a subagent whose prompt includes the same task description, slug, pattern survey findings, product decisions, and deep-dive discussion outcomes. Instruct it to invoke `/peer-draft-plan` via the Skill tool, passing the full context as the task input. `/peer-draft-plan` produces an independent plan via codex following the same template.

Wait for both agents to complete before moving to Step 6.

## Step 6: Reconcile and Write the Plan File

Compare the two drafts side by side along these dimensions:

| Dimension | What to compare |
|---|---|
| **Approach** | Do they propose the same overall strategy, or meaningfully different ones? |
| **Step coverage** | Does one draft include steps the other misses? |
| **Concreteness** | Which draft has more `file_path:line_number` references and named symbols? |
| **Verification** | Which draft's verification section is more specific? |
| **Failure modes** | Does one draft handle edge cases the other ignores? |

Reconcile using these rules:

- **Strong agreement** — Use the better-written of the two as the base. Merge in any unique steps or verification items from the other.
- **Different approaches** — Use `AskUserQuestion` to present both approaches as options with a one-sentence trade-off summary. Let the user pick or ask to merge.
- **One draft is clearly stronger** — Use it as the base and discard the weaker one.
- **One agent failed or returned malformed output** — Use the surviving draft.

Create `.turbo/plans/` if it does not exist. Write the reconciled plan to `.turbo/plans/<slug>.md` using the slug picked in Step 1 (or the override path from Step 1) using this structure:

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

## Verification

How to verify the change works end-to-end after implementation:

- <Specific test command, manual smoke check, or MCP tool invocation>
- <Expected observable result for each verification step>
- <Edge cases to spot-check>

## Context Files

Files to read in full before starting implementation:

- `<absolute/path/to/file1>` — <why it matters>
- `<absolute/path/to/file2>` — <why it matters>
- ...
````

### Content Rules for the Plan

- **Implementation Steps**: Use concrete `file_path:line_number` references. Reference existing functions and utilities from the Pattern Survey instead of reinventing them. Each step describes a discrete unit of work that can be tracked independently during execution.
- **Verification**: Describe how to know the change actually works. Prefer specific test commands, named test files, or named smoke checks over vague phrases like "run the tests." If the change has no observable behavior, say so explicitly.
- **Context Files**: Curate the minimum set needed to become productive. Do not dump every file touched — only the ones that anchor understanding.
- **Scope**: Plan content describes what to build. Do not include task tracking, skill loading, test commands, or commit instructions — those are execution-wrapper concerns.
