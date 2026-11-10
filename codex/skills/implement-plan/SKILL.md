---
name: implement-plan
description: "Execute an implementation plan file from .turbo/plans/. Use when the user asks to \"implement the plan\", \"execute the plan\", \"implement plans/[slug].md\", or starts a fresh session to implement one."
---

# Implement Plan

Execute an implementation plan file.

## Task Tracking

At the start, use `update_plan` to track each step, restating any remaining steps of a parent workflow alongside them:

1. Resolve and read the plan file
2. Read context files
3. Run `$implement` skill
4. Update plan status

## Step 1: Resolve and Read the Plan File

Determine which plan file to implement using these rules in order:

1. **Explicit path** — If an absolute or relative path was passed and that file exists, use it
2. **Explicit slug** — If a slug was passed (e.g., `add-image-cache`), resolve to `.turbo/plans/<slug>.md` if that file exists
3. **Single file** — Glob `.turbo/plans/*.md`. If exactly one plan exists, use it
4. **Most recent** — If multiple plans exist, use the most recently modified
5. **Legacy fallback** — If `.turbo/plans/` does not exist but `.turbo/plan.md` exists, use it
6. **Nothing found** — If no rule above resolved to an existing file, tell the user to run `$turbo:plan` and stop. When a slug or path was passed but no file matched it, say which one was tried

If multiple plans exist and the most-recent choice is non-obvious (e.g., several plans were modified within the same minute), use `request_user_input` to let the user pick from the candidates.

State the resolved plan path before continuing, then read the file.

Unless an explicit path or slug was passed, confirm the resolved plan still describes work that remains to be done:

- **Already implemented** — the frontmatter `status:` is `done`
- **Waiting on a gate** — the plan's Context states a gate that must pass before its work can start

When you check whether a gate has passed, check each condition it names at its source of record, such as the remote's tags for another repository's release, rather than a local copy.

When a signal fires, output it as text. Then use `request_user_input` to offer:

- **Implement anyway** — the marker is stale, or the gate has passed
- **Pick another plan** — resolve to a different file under `.turbo/plans/`, then confirm that plan against these same signals
- **Leave it unimplemented** — the plan needs revising first, or its gate has not passed

On **Leave it unimplemented**, tell the user to bring the plan current with `$turbo:refine-plan` and run this skill again, or, for a plan whose gate has not passed, to run this skill again once it has. Call `update_plan` to drop the remaining implement steps, restating any remaining steps of a parent workflow, then continue with the next step of the active workflow.

Workflow state lives in a file under `.turbo/workflows/` that pairs one-to-one with the thread's goal. When no unfinished goal exists, mint its path once as `.turbo/workflows/<label>-<tag>.md`. The label is the resolved plan's basename. The tag is the output of `head -c 4 /dev/urandom | xxd -p`. Only when this run's `create_goal` attempt succeeds, write the file with this invocation's `update_plan` list as a checkbox list. When an unfinished goal already exists, mint nothing and mirror into the workflow file its objective names; when it names none, continue without workflow state. Mirror every `update_plan` call into the file; it holds the pipeline's remaining steps and their statuses. When this run created the goal, run the terminal step in order: mark the final entry completed, mark the goal complete with `update_goal`, delete the workflow file, then emit any halt message.

Attempt `create_goal` with the objective, filling in the minted path: "Execute the implementation plan at <plan path> through `$implement`, then set the plan's frontmatter status to done when it has frontmatter. Workflow state: <workflow path>; mirror every `update_plan` call into it. Loop state lives under `.turbo/loops/`. After any context compaction, re-read the plan file, the workflow file, and every ledger it registers, and continue from the first unfinished entry. Mark this goal complete only after that status update, or after `$implement` completes for a plan without frontmatter." If an unfinished goal already exists, an outer workflow owns it; continue without creating one.

## Step 2: Read Context Files

Read in full:

- Every file listed in the plan's **Context Files** section
- Files the user referenced in their original request (if any)
- Every file path the plan references in the Context, Pattern Survey, and Implementation Steps sections

## Step 3: Run `$implement` Skill

Run the `$implement` skill. The plan file, its file references, and its Verification section are already in conversation context from Step 1.

## Step 4: Update Plan Status

After `$implement` completes, set the plan's frontmatter `status:` to `done`. If the plan is the legacy `.turbo/plan.md` without frontmatter, skip the status update.

When the plan's Context names a larger source it implements part of (an assessment, a backlog, an issue), report the plan's completion separately from that source's: name the source's items the plan left out, and say whether another plan under `.turbo/plans/` covers them.

If this run created a goal in Step 1, follow the closing `update_plan` call below by marking the goal complete with `update_goal`, then deleting the workflow file.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

## Rules

- The plan file is read-only during execution. If revisions are needed, the user runs `$turbo:refine-plan` or `$turbo:draft-plan` separately.
- Never skip Step 2.
- Never enumerate or execute the plan's Implementation Steps inline. The work runs through `$implement`. Restating steps as a turn-level narration counts as inline execution and bypasses the delegation.
- If the plan's Implementation Steps or Verification include `git commit`, `git push`, or PR creation, halt before Step 3 and ask the user to remove them via `$turbo:refine-plan`. A Verification item that observes the result of a push without instructing one is not grounds to halt.
