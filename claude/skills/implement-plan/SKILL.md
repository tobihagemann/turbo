---
name: implement-plan
description: "Execute an implementation plan file produced by /draft-plan or /turboplan. Runs pre-implementation prep, then runs /implement to execute the steps and finalize once they are all done. Use when the user asks to \"implement plan\", \"implement the plan\", \"execute the plan\", \"run the plan\", \"implement plans/<slug>.md\", \"start implementing the plan\", or starts a fresh session to implement a previously drafted plan."
---

# Implement Plan

Execute an implementation plan file.

## Task Tracking

At the start, use `TaskCreate` to create a task for each step:

1. Resolve and read the plan file
2. Read context files
3. Run `/implement` skill
4. Update plan status

## Step 1: Resolve and Read the Plan File

Determine which plan file to implement using these rules in order:

1. **Explicit path** — If an absolute or relative path was passed and that file exists, use it
2. **Explicit slug** — If a slug was passed (e.g., `add-image-cache`), resolve to `.turbo/plans/<slug>.md` if that file exists
3. **Single file** — Glob `.turbo/plans/*.md`. If exactly one plan exists, use it
4. **Most recent** — If multiple plans exist, use the most recently modified
5. **Legacy fallback** — If `.turbo/plans/` does not exist but `.turbo/plan.md` exists, use it
6. **Nothing found** — If no rule above resolved to an existing file, tell the user to run `/turboplan` and stop. When a slug or path was passed but no file matched it, say which one was tried

If multiple plans exist and the most-recent choice is non-obvious (e.g., several plans were modified within the same minute), use `AskUserQuestion` to let the user pick from the candidates.

State the resolved plan path before continuing, then read the file.

Unless an explicit path or slug was passed, confirm the resolved plan still describes work that remains to be done:

- **Already implemented** — the frontmatter `status:` is `done`
- **Waiting on a gate** — the plan's Context states a gate that must pass before its work can start

When a signal fires, output it as text. Then use `AskUserQuestion` to offer:

- **Implement anyway** — the marker is stale, or the gate has passed
- **Pick another plan** — resolve to a different file under `.turbo/plans/`, then confirm that plan against these same signals
- **Leave it unimplemented** — the plan needs revising first, or its gate has not passed

On **Leave it unimplemented**, tell the user to bring the plan current with `/refine-plan` and run this skill again, or, for a plan whose gate has not passed, to run this skill again once it has. Mark the remaining implement steps deleted, then use the TaskList tool and proceed to any remaining task.

## Step 2: Read Context Files

Read in full:

- Every file listed in the plan's **Context Files** section
- Files the user referenced in their original request (if any)
- Every file path the plan references in the Context, Pattern Survey, and Implementation Steps sections

## Step 3: Run `/implement` Skill

Run the `/implement` skill. The plan file, its file references, and its Verification section are already in conversation context from Step 1.

## Step 4: Update Plan Status

After `/implement` completes, set the plan's frontmatter `status:` to `done` with the Edit tool. If the plan is the legacy `.turbo/plan.md` without frontmatter, skip the status update.

When that edit is refused while this session runs inside a linked worktree, report that the status update was not applied and name the edit to make from a session that can write to the main checkout: `status: done` in the resolved plan path.

When the plan's Context names a larger source it implements part of (an assessment, a backlog, an issue), report the plan's completion separately from that source's: name the source's items the plan left out, and say whether another plan under `.turbo/plans/` covers them.

## Rules

- The plan file is read-only during execution. If revisions are needed, run `/refine-plan` or `/draft-plan` separately.
- Never skip Step 2.
- Never enumerate or execute the plan's Implementation Steps inline. The work runs through `/implement`. Restating steps as a turn-level narration counts as inline execution and bypasses the delegation.
- If the plan's Implementation Steps or Verification include `git commit`, `git push`, or PR creation, halt before Step 3 and ask the user to remove them via `/refine-plan`.
