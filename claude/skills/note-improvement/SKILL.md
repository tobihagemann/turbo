---
name: note-improvement
description: "Capture an out-of-scope improvement opportunity so it doesn't get lost. Use when the user asks to \"note improvement\", \"save improvement\", \"track this for later\", \"remember this improvement\", \"note this idea\", \"log improvement\", \"backlog this\", or \"park this idea\". Also invoke proactively when noticing something improvable during work that falls outside the current task's scope, or after deliberately shipping a simpler approach that accepts a known ceiling — briefly mention it to the user and offer to note it."
---

# Note Improvement

Capture improvement opportunities discovered during work so they don't get silently dropped. Appends to a project-level `.turbo/improvements.md` file that serves as a backlog of actionable ideas.

## Step 1: Determine Project Root

Find the nearest `.git` directory or project root. The improvements file lives at `.turbo/improvements.md` relative to the project root.

## Step 2: Identify the Improvement

Gather from context or `$ARGUMENTS`:

- **What**: One-line summary of the improvement
- **Type**: One of `direct`, `investigate`, or `plan` — see criteria below
- **Category**: One of `refactor`, `performance`, `reliability`, `readability`, `testing`, `docs`, `dx` (developer experience), or `feature`
- **Where**: File path(s) and/or area of the codebase affected
- **Why**: Brief rationale — what's the benefit?
- **Ceiling** and **Revisit**: when the entry records a deliberate simplification, meaning a simpler approach was shipped in place of a fuller one and accepts a known limit — the limit the shipped approach accepts, and the condition that makes the fuller version worth building

### Type criteria

- **direct** — Clear scope and a known approach, ready to apply via `/implement`.
- **investigate** — A symptom that needs root-cause analysis first: unclear root cause, performance question, intermittent bug, "something feels off".
- **plan** — Everything else: the approach warrants writing down before implementing (multi-file refactor, test additions, feature work).

When the criteria above clearly select one value, use it. Otherwise, use `AskUserQuestion` to confirm; default to `plan` if the user declines to choose.

## Step 3: Append to File

Read `.turbo/improvements.md` if it exists. Create it with the header below if it doesn't.

**File header** (only when creating new):

```markdown
# Improvements

Out-of-scope improvement opportunities captured during work sessions. Review periodically and pull items into active work when appropriate.
```

**Entry format:**

```markdown
### <one-line summary>

- **Type**: <direct | investigate | plan>
- **Category**: <category>
- **Where**: `<file path or area>`
- **Why**: <brief rationale>
- **Ceiling**: <limit the shipped approach accepts>
- **Revisit**: <condition that makes the fuller version worth building>
- **Noted**: <YYYY-MM-DD>
```

Include the Ceiling and Revisit lines when the entry records a deliberate simplification; omit both otherwise. Append the new entry at the end of the file.

## Step 4: Confirm

Tell the user the improvement was noted and where the file is.

## Rules

- Deduplicate before appending: check for a similar entry and update it in place when one exists. When the existing entry predates the Type field, add a Type line while updating.
- When updating an existing entry tagged with the legacy values `trivial` or `standard`, rewrite the Type to `direct` or `plan` respectively so the file converges on current vocabulary.
- Keep entries concise. These are backlog items, not specs.
- When a deliberate simplification's revisit condition is not yet knowable, record what would have to be observed to know it.
- Record only; leave action to the user, who decides when to address it.
- When the project has no `.turbo/` directory, use `AskUserQuestion` to confirm the location before creating one.
