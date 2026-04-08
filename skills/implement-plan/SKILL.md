---
name: implement-plan
description: "Execute an implementation plan file produced by /draft-plan or /turboplan. Runs pre-implementation prep, loads task-specific skills by matching plan content against available skill triggers, executes the plan steps, and runs /finalize. Use when the user asks to \"implement plan\", \"implement the plan\", \"execute the plan\", \"run the plan\", \"implement .turbo/plan.md\", \"start implementing the plan\", or starts a fresh session to implement a previously drafted plan."
---

# Implement Plan

Execute an implementation plan file. The plan file describes what to build; this skill wraps execution with Turbo's pre-implementation prep, task-specific skill loading, step execution, and finalization.

## Task Tracking

At the start, use `TaskCreate` to create a task for each step:

1. Read the plan file
2. Run `/code-style` skill
3. Read relevant files and load task-specific skills
4. Execute implementation steps
5. Run `/finalize` skill

## Step 1: Read the Plan File

Default path: `.turbo/plan.md`. Accept a different path if the caller or user provides one.

If the file does not exist, tell the user there is no plan to implement and stop.

Parse the plan's sections:

- **Context** — the why
- **Pattern Survey** — existing patterns and utilities to reuse
- **Implementation Steps** — the ordered work
- **Context Files** — files to read in full before editing

## Step 2: Run `/code-style` Skill

Run the `/code-style` skill to load code style principles.

## Step 3: Read Relevant Files and Load Task-Specific Skills

### Read Relevant Files

Read in full:

- Every file listed in the plan's **Context Files** section
- Files the user referenced in their original request (if any)
- Every file path the plan references in the Context, Pattern Survey, and Implementation Steps sections
- One or two similar files in the project to mirror their style when creating new files or extending existing patterns

### Identify and Load Task-Specific Skills

Scan the plan's **Implementation Steps** for work types that match available skills. For each unambiguous match, run the skill via the Skill tool before editing.

To identify matches:

1. Scan the available skill list
2. For each skill, compare its trigger description against the plan's Implementation Steps
3. Load skills whose triggers clearly match the work. For example, if the plan includes "add a Drizzle migration" and a skill exists whose triggers reference Drizzle migrations, load it. If the plan mentions "run the test suite" but no testing-specific skill trigger matches, do not load a generic testing skill.

If unsure, do not load. Do not load `/code-style` here — it was loaded in Step 2.

## Step 4: Execute Implementation Steps

Work through the plan's Implementation Steps in order. Use `TaskCreate` to add one task per plan step. Mark each task `in_progress` when starting and `completed` when done.

Follow the plan's `file_path:line_number` references. Reuse patterns and utilities listed in the Pattern Survey instead of reimplementing them.

If a step cannot be completed (blocked by a dependency, unclear requirement, or environmental issue), stop and report. Do not silently skip steps.

## Step 5: Run `/finalize` Skill

After all Implementation Steps are complete, run the `/finalize` skill. `/finalize` runs polish, changelog, self-improvement, commit, and PR.

## Rules

- The plan file is read-only during execution. If revisions are needed, run `/refine-plan` or `/draft-plan` separately.
- Never skip Step 3. Pre-implementation prep catches style-mirroring gaps and skill loading that the plan content cannot enforce on its own.
- Never skip Step 5. `/finalize` is mandatory even for small plans. Context window, perceived task simplicity, and diff size are not reasons to skip it.
- Do not edit the plan as part of execution. Source code edits are the output; the plan stays as the record of what was planned.
