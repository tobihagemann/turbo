---
name: simplify-all
description: "Run the code and documentation simplification passes together over one scope, launching every review sub-agent concurrently before applying a single round of fixes. Use when the user asks to \"simplify all\", \"simplify everything\", \"simplify code and docs\", \"clean up code and docs\", \"run both simplify skills\", or \"simplify code and docs in parallel\"."
---

# Simplify All

## Step 1: Run `$simplify-code` and `$simplify-docs` Skills

Run the `$simplify-code` and `$simplify-docs` skills together, passing along any scope that was provided so both passes cover identical files.

Issue the `spawn_agent` calls for every review sub-agent the two skills define in one batch. Do not issue one and await its result before issuing the rest. Hold every fix for Step 2 in place of each skill's own fix step.

## Step 2: Fix Issues

Once `wait_agent` has joined every sub-agent, aggregate the findings and apply one round of fixes, following each skill's own guidance for resolving its findings.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.
