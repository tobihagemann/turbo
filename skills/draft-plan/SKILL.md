---
name: draft-plan
description: "Produce an implementation plan at .turbo/plans/<slug>.md. Runs in two modes: full mode (fresh task, guided discussion) or fill-in mode (expands a shell plan handed in by /turboplan in shell mode, typically from /pick-next-prompt). Use when the user asks to \"draft a plan\", \"draft the plan\", \"write an implementation plan\", \"plan this change\", \"create an implementation plan\", \"fill in the shell\", \"expand the shell\", or needs a first-draft plan file before refinement."
---

# Draft Plan

Produce an implementation plan at `.turbo/plans/<slug>.md`. This skill has two modes:

- **Full mode** is the default for standalone invocation or when called from `/turboplan`'s small-task path. It runs the full interactive pipeline: capture task, survey, escalate, deep-dive discussion, parallel internal+peer drafting.
- **Fill-in mode** is triggered when a shell file path is passed in. Shells are produced upstream by `/create-prompt-plan` and are typically handed to this skill via `/turboplan` shell mode (which is invoked by `/pick-next-prompt`). Fill-in mode verifies consumes against the current codebase, refreshes the pattern survey, escalates only the shell's open questions, and fills in concrete file references and verification.

## Step 0: Determine Mode

Inspect the caller's input:

- If a **shell file path** was passed in (typically from `/turboplan` in shell mode), use **Fill-in mode**. Skip to the "Fill-in Mode Steps" section below.
- Otherwise, use **Full mode**. Continue with "Full Mode Steps" below.

## Task Tracking

Use `TaskCreate` at the start. The task list depends on the mode:

**Full mode:**

1. Capture the task and pick a slug
2. Run `/survey-patterns` skill
3. Escalate product decisions
4. Deep-dive discussion
5. Run two drafts in parallel
6. Reconcile and write the plan file

**Fill-in mode:**

1. Load the shell and verify consumes
2. Run `/survey-patterns` skill (shell-focused)
3. Escalate the shell's open questions
4. Run two fill-in drafts in parallel
5. Reconcile and write back to the shell path

## Full Mode Steps

### Step 1: Capture the Task and Pick a Slug

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

### Step 2: Run `/survey-patterns` Skill

Run the `/survey-patterns` skill with the confirmed task description. Keep the returned findings in conversation context for use in Steps 4 and 5.

### Step 3: Escalate Product Decisions

Identify product or design decisions the user's request did not resolve. Escalate these via `AskUserQuestion` before drafting steps.

**Escalate when:**

- A plan step requires choosing between user-facing behaviors the request did not specify (opt-in vs opt-out, strict vs lenient, sync vs async)
- The plan assumes product requirements that were not stated
- Design trade-offs affect UX or product direction rather than technical implementation
- Multiple valid approaches exist and the choice is a matter of product preference, not technical merit

**Do not escalate** technical decisions the agent can make autonomously: which data structure, which existing pattern to follow, internal implementation approach. The boundary is product intent.

Present each decision as a concise trade-off with options. Draft plan steps that depend on these decisions only after the user responds.

### Step 4: Deep-Dive Discussion

Work through the implementation shape with the user via `AskUserQuestion`, one or two questions at a time. Use the pattern survey findings to frame choices. Cover whichever of these matter for the task. Do not present a rigid checklist:

| Area | What to explore |
|---|---|
| **Reuse vs new** | Which survey findings should the new work build on? Which should it deliberately not follow, and why? |
| **File placement** | Where do new files live? Which existing files are modified? |
| **Data flow** | How does data move through the change? Any new boundaries or contracts? |
| **Edge cases** | Partial failure, empty states, backward compatibility, concurrency |
| **Tests** | Which existing test patterns apply? Where do new tests live? |
| **Scope cut** | Anything to explicitly defer? |

#### Discussion Guidelines

- Make recommendations with reasoning, not just questions. Be a collaborator, not an interviewer.
- When the user says "you decide," make the call and explain why.
- Probe short answers before moving on.
- When the shape is clear or the user signals readiness, confirm before drafting.

### Step 5: Run Two Drafts in Parallel

After the interactive steps (1-4) are complete, draft the plan twice in parallel: once internally and once via `/peer-draft-plan`. Two independent drafts surface blind spots and let the user pick the strongest framing.

Launch two Agent tool calls in a single message (`model: "opus"`, do not set `run_in_background`):

#### Internal Draft

Spawn a subagent and pass it:

- The task description and slug from Step 1
- The pattern survey findings from Step 2
- The product decisions resolved in Step 3
- The deep-dive discussion outcomes from Step 4
- The plan file template and Content Rules from Step 6 below

Instruct it to synthesize the discussion into a complete plan document following the template, returning the full markdown text. The subagent does **not** write to disk; it returns the draft to the caller.

#### Run `/peer-draft-plan` Skill

Spawn a subagent whose prompt includes the same task description, slug, pattern survey findings, product decisions, and deep-dive discussion outcomes. Instruct it to invoke `/peer-draft-plan` via the Skill tool, passing the full context as the task input. `/peer-draft-plan` produces an independent plan via codex following the same template.

Wait for both agents to complete before moving to Step 6.

### Step 6: Reconcile and Write the Plan File

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

The plan file focuses on the plan content. Turbo-specific execution protocol (task tracking, skill loading, `/finalize` invocation) lives in `/implement-plan`.

#### Content Rules for the Plan

- **Implementation Steps**: Use concrete `file_path:line_number` references. Reference existing functions and utilities from the Pattern Survey instead of reinventing them. Each step describes a discrete unit of work that can be tracked independently during execution.
- **Verification**: Describe how to know the change actually works. Prefer specific test commands, named test files, or named smoke checks over vague phrases like "run the tests." If the change has no observable behavior, say so explicitly.
- **Context Files**: Curate the minimum set needed to become productive. Do not dump every file touched — only the ones that anchor understanding.
- **Scope**: Plan content describes what to build, not how to execute it. Instructions like "run the test suite" or "commit the changes" belong in the execution wrapper, not the plan.

## Fill-in Mode Steps

Fill-in mode expands a shell plan into a full plan with pattern survey, concrete references, and verification. Shells are produced upstream by `/create-prompt-plan`; the decomposition work (Produces, Consumes, Covers, high-level Implementation Steps) already happened at create time and is authoritative. Fill-in only adds the parts that require current codebase state.

### Step 1: Load the Shell and Verify Consumes

Read the shell file from the path passed by the caller. Parse these fields:

- **Title** (from the `# Plan:` heading)
- **Context** (the why)
- **Produces** (artifacts this shell creates)
- **Consumes** (dependencies this shell requires)
- **Covers Spec Requirements** (the spec sections this shell implements)
- **Implementation Steps (high-level)** (named tasks without file paths)
- **Open Questions** (decisions deferred to now)

The shell file path is also the destination path: fill-in writes back to the same file, converting shell → full plan.

**Verify Consumes are present in the current codebase.** For each Consumes entry:

- If marked "from existing codebase," grep or read relevant files to confirm the artifact still exists at the expected conceptual location
- If the entry references a prior shell's Produces (traceable via the prompt plan index), verify the prior shell has `Status: done` in the index AND that the artifact is actually present in the current codebase (the prior implementation may have diverged)

If any Consumes entry fails verification, escalate via `AskUserQuestion`:

- **Adapt the shell** — open the shell for editing, adjust the shell's Consumes/Implementation Steps to match what actually exists, then re-verify
- **Skip this prompt** — mark the shell's index entry back to `pending` and stop. Tell the user to run `/pick-next-prompt` again or resolve the prior work.
- **Stop and investigate** — halt without edits so the user can debug

Do not proceed to Step 2 until all Consumes verify cleanly.

### Step 2: Run `/survey-patterns` Skill (Shell-Focused)

Run the `/survey-patterns` skill with a task description built from the shell's structural content:

```
<shell title>

Context: <shell Context>
Produces: <shell Produces, as a bulleted list>
Implementation steps: <shell Implementation Steps, numbered>
```

This scopes the survey to the shell's concern area instead of a generic sweep. Keep the returned findings in conversation context for use in Step 4.

### Step 3: Escalate the Shell's Open Questions

For each entry in the shell's `Open Questions` field, present it via `AskUserQuestion` and collect the answer. Frame each question with enough context from the shell for the user to decide.

Do **not** escalate other questions. The shell explicitly marked its open questions at decomposition time; any decision the shell did not defer is already resolved at spec time. If you identify a new question while reading the codebase, note it as a risk in the drafted plan's Verification or Context Files sections rather than escalating.

If the shell's Open Questions field is empty or contains "None," skip this step entirely.

### Step 4: Run Two Fill-in Drafts in Parallel

Launch two Agent tool calls in a single message (`model: "opus"`, do not set `run_in_background`):

#### Internal Fill-in Draft

Spawn a subagent and pass it:

- The complete shell content (Context, Produces, Consumes, Covers, high-level Implementation Steps, Open Questions)
- The resolved Open Questions from Step 3 (if any)
- The pattern survey findings from Step 2
- The shell file path (where the draft will be written)
- The full plan template and Content Rules from the Full Mode section above

Instruct it to:

1. Use the shell's Context as the plan's Context (preserve verbatim or lightly edit)
2. Use the shell's high-level Implementation Steps as the skeleton, concretizing each with `file_path:line_number` references, named functions, and specific symbols from the pattern survey
3. Add a Pattern Survey section with the Step 2 findings
4. Write a Verification section with specific test commands and expected observable results for this shell's work
5. Write a Context Files section listing the files an implementer needs to read in full
6. Return the full plan markdown to the caller (do NOT write to disk — Step 5 handles that)

#### Run `/peer-draft-plan` Skill

Spawn a subagent whose prompt includes the same shell content, resolved open questions, and pattern survey findings, and instructs it to invoke `/peer-draft-plan` via the Skill tool. The peer draft produces an independent fill-in following the same template.

Wait for both agents to complete before moving to Step 5.

### Step 5: Reconcile and Write Back

Compare the two fill-in drafts along the reconciliation dimensions from Full Mode Step 6 (Approach, Step coverage, Concreteness, Verification, Failure modes). Apply the same reconciliation rules (strong agreement → use better-written one, different approaches → AskUserQuestion, one stronger → use it, one failed → use survivor).

Write the reconciled full plan to the shell file path (overwriting the shell content). Use the same plan template as Full Mode Step 6. The resulting file is a complete plan ready for `/refine-plan` and `/implement-plan`.

Retain traceability by adding an HTML comment near the top of the file (after the `# Plan:` heading):

```
<!-- Decomposed from: <spec path> (prompt <N> of <prompt plan path>) -->
```

The scaffolding fields (Produces, Consumes, Covers Spec Requirements, Open Questions) are dropped from the final plan; they were decomposition-time tools. Context is retained.

## Rules

- Never skip Step 2 (`/survey-patterns`) in either mode. A plan without pattern grounding misses reuse and drifts from codebase conventions.
- Never skip Step 3 in either mode. In full mode, product decisions baked in without asking become rework. In fill-in mode, deferred open questions need to be resolved before drafting.
- Never skip Step 5 (full mode) or Step 4 (fill-in mode). Both internal and peer drafts must run in parallel. "The task is small" or "context window concerns" are not reasons to skip the peer draft. If `/peer-draft-plan` is unavailable or fails, fall through to the surviving internal draft and note that the peer draft was unavailable.
- The plan file is the only output. Do not write code, scaffolding, or other project files.
- Do not run `/review-plan` or any review skills here. Refinement is `/refine-plan`'s job.
- Do not embed Turbo execution protocol (Task Tracking, Load skills, Run `/finalize`) in the plan file. Those belong in `/implement-plan`.
- In fill-in mode, never proceed past Step 1 if Consumes verification fails. A shell whose prerequisites don't exist in the current codebase cannot be safely filled in.
