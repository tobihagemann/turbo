---
name: survey-patterns
description: "Survey the codebase for analogous features, reusable utilities, and existing patterns relevant to a proposed change, reading any source the task names outside this repo. Returns structured findings without writing code. Use when the user asks to \"survey patterns\", \"find existing patterns\", \"look for analogous features\", \"check how similar things are done\", \"find prior art for this change\", or needs pattern context before planning a change."
---

# Survey Patterns

Search the codebase for analogous features and reusable building blocks before planning a change, and read any source the task names outside this repo. Returns structured findings. Does not write code or plans.

## Step 1: Identify the Task

Determine what the change is about:

- If a task description was passed in, use it
- Otherwise, derive it from conversation context (the user's latest request)

State the task back in one sentence to confirm scope before searching.

## Step 2: Spawn Pattern Survey Sub-agent

Spawn a single sub-agent (inherited model defaults). Its prompt must direct it to treat the shared working tree and its git index as read-only and to survey by reading and reasoning. HEAD stays where it is: read other refs with `git show <ref>:<path>` rather than `git checkout` or `git switch`. The sub-agent's prompt must include:

1. The confirmed task description from Step 1
2. An instruction to read [references/pattern-surveyor.md](references/pattern-surveyor.md) for survey guidelines, categories, and output format before searching

The sub-agent covers all three categories (Analogous Features, Reusable Utilities, Convention Anchors) in one sweep, reads any external source the task names, and returns a single structured report.

## Step 3: Output Findings

Output the sub-agent's report verbatim. Do not reformat or re-synthesize — `references/pattern-surveyor.md` specifies the exact output format the sub-agent produces.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

## Rules

- Do not write files.
- Do not propose implementation steps.
