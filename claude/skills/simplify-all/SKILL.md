---
name: simplify-all
description: "Run the code and documentation simplification passes together over one scope, launching every review agent concurrently before applying a single round of fixes. Use when the user asks to \"simplify all\", \"simplify everything\", \"simplify code and docs\", \"clean up code and docs\", \"run both simplify skills\", or \"simplify code and docs in parallel\"."
---

# Simplify All

## Step 1: Run `/simplify-code` and `/simplify-docs` Skills

Run the `/simplify-code` and `/simplify-docs` skills via the Skill tool in one assistant message, passing along any scope that was provided so both passes cover identical files.

Emit the Agent tool calls for every review agent the two skills define in one assistant message. Each Agent call uses `model: "opus"` and no `name`. Wait for every agent to report before continuing. Do not begin the next step on a partial set, and do not relaunch an agent that has not yet reported. State the count explicitly when emitting the calls. Hold every fix for Step 2 in place of each skill's own fix step.

## Step 2: Fix Issues

Aggregate the findings and apply one round of fixes, following each skill's own guidance for resolving its findings.

Then use the TaskList tool and proceed to any remaining task.
