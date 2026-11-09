---
name: implement-findings
description: "Implement evaluated findings: apply the accepted fixes, then close out with full or quick QA. Use when the user asks to \"implement findings\" or \"resolve findings\"."
---

# Implement Findings

Apply evaluated findings and close out the change.

## Task Tracking

At the start, use `TaskCreate` to create a task for each step:

1. Run `/code-style` skill
2. Run `/apply-findings` skill
3. Close out the change

## Step 1: Run `/code-style` Skill

Run the `/code-style` skill to load existence, reuse, mirror, and symmetry rules before editing.

## Step 2: Run `/apply-findings` Skill

Run the `/apply-findings` skill on the evaluated findings.

## Step 3: Close Out the Change

If no changes were made, skip this step.

Use `AskUserQuestion` to choose how to close out the change:

- **Full QA** — run the `/finalize` skill
- **Quick close** — run the `/quick-finalize` skill

Then use the TaskList tool and proceed to any remaining task.
