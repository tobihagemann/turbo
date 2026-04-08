---
name: peer-draft-plan
description: "Draft an implementation plan independently via codex. Designed to run in parallel with an internal draft from /draft-plan as the planning sibling of /peer-review. Use when the user asks to \"peer draft a plan\", \"get a peer plan\", \"draft a plan with codex\", \"second draft of the plan\", or \"alternative plan from codex\", or when called by /draft-plan as the peer half of its parallel internal+peer drafting step."
---

# Peer Draft Plan

Draft an implementation plan independently via codex. Returns the peer draft text to the caller.

This skill is the planning sibling of `/peer-review`: where `/peer-review` asks codex to critique an existing artifact, `/peer-draft-plan` asks codex to produce one from scratch. It is designed to run in parallel with an internal drafter inside `/draft-plan`'s parallel-drafting step.

## Step 1: Identify the Task Context

Determine the mode and the context to draft from. This skill supports three invocation shapes:

- **Full-mode context** (from `/draft-plan` full mode): caller provides task description, slug, pattern survey findings, resolved product decisions, and deep-dive discussion outcomes
- **Fill-in context** (from `/draft-plan` fill-in mode): caller provides a shell's structural content — Context, Produces, Consumes, Covers Spec Requirements, high-level Implementation Steps, resolved Open Questions — plus the pattern survey findings refreshed at fill-in time
- **Standalone context** (from the user directly): caller provides only a task description. Ask the user for any decisions the prompt cannot infer, then proceed

The richer the context, the more comparable the peer draft will be to an internal draft running in parallel.

## Step 2: Build the Codex Prompt

Construct a `/codex-exec` prompt with whatever context you have, asking codex to produce a plan in the exact structure `/draft-plan` writes. This makes the two drafts directly comparable.

The prompt has three parts: a `<task>` block (mode-dependent), a `<structured_output_contract>` block (shared across modes), and a `<dig_deeper_nudge>` block (shared across modes). Concatenate the appropriate task block with the two shared blocks before passing to `/codex-exec`.

### Task block — full-mode or standalone context

```
<task>
Draft an implementation plan for the task below. Ground the plan in the actual codebase by reading the relevant files first. Produce the plan in the exact structure specified, using concrete file_path:line_number references for every step.

Task: <task description>
Slug: <slug if provided>

Pattern survey findings (analogous features, reusable utilities, convention anchors): <findings or "none provided">
Resolved product decisions: <decisions or "none provided">
Deep-dive discussion outcomes: <outcomes or "none provided">
</task>
```

### Task block — fill-in context

```
<task>
Expand the shell plan below into a full implementation plan. The shell was produced by /create-prompt-plan at decomposition time. Its Context, Produces, Consumes, Covers, and high-level Implementation Steps are authoritative; do not second-guess them. Your job is to fill in the parts the shell deferred: pattern survey, concrete file_path:line_number references for each step, Verification, and Context Files. Ground the plan in the actual codebase by reading the relevant files first.

Shell title: <title>
Shell slug: <slug>

Shell Context:
<context paragraph>

Shell Produces:
<produces list>

Shell Consumes:
<consumes list>

Shell Covers Spec Requirements:
<covers list>

Shell Implementation Steps (high-level, concretize these with file_path:line_number references):
<high-level steps>

Resolved Open Questions (answered at fill-in time):
<resolved questions, or "none">

Pattern survey findings (refreshed at fill-in time):
<findings>
</task>
```

### Shared output contract (append to both modes)

```
<structured_output_contract>
Produce a markdown document with these sections in order:

# Plan: <Task Title>

## Context
<Why this change is being made: the problem, what prompted it, the intended outcome.>

## Pattern Survey
### Analogous Features
- `<absolute/path>:<line>` — <description>
### Reusable Utilities
- `<absolute/path>:<line>` — `<functionName>` — <what it does>
### Convention Anchors
- <convention name>: <description with file paths>
### Proposed Alignment
<1-3 sentences on whether to follow, deviate, or blend.>

## Implementation Steps
1. **<Step title>**
   - <Concrete action with file_path:line_number reference>
2. ...

## Verification
- <Specific test command, manual smoke check, or expected observable result>

## Context Files
- `<absolute/path>` — <why it matters>

Every Implementation Step must reference at least one concrete file_path:line_number, function name, or symbol. Avoid vague directives like "add validation", "handle edge cases", "as needed", "similar to step N", "etc.", or "TBD".
</structured_output_contract>
```

### Shared dig-deeper nudge (append to both modes)

```
<dig_deeper_nudge>
Before finalizing, verify the plan handles failure modes the task description does not call out: partial failure, race conditions, rollback safety, stale state, and data loss. If any of these apply, address them in Implementation Steps or Verification.
</dig_deeper_nudge>
```

## Step 3: Run `/codex-exec` Skill

Run the `/codex-exec` skill in read-only mode with the prompt from Step 2.

## Step 4: Return the Peer Draft

Return the codex output to the caller as the final assistant message. Do not write to a file. When called by `/draft-plan`, the caller's reconciliation step decides what to keep. When called standalone, the user decides.

## Rules

- Never modify an existing plan file. This skill is read-only with respect to project state.
- If codex is unavailable, report the failure to the caller. Do not silently fall back to an internal draft.
