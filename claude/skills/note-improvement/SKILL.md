---
name: note-improvement
description: "Capture an out-of-scope improvement opportunity so it doesn't get lost. Use when the user asks to \"note improvement\", \"save improvement\", \"track this for later\", \"remember this improvement\", \"note this idea\", \"log improvement\", \"backlog this\", or \"park this idea\". Also invoke proactively when noticing something improvable during work that falls outside the current task's scope, or after deliberately shipping a simpler approach that accepts a known ceiling — briefly mention it to the user and offer to note it."
---

# Note Improvement

Capture improvement opportunities discovered during work so they don't get silently dropped. Appends to the `.turbo/improvements.md` backlog of the repo an improvement concerns.

## Step 1: Locate the Improvements File

Each repo keeps its improvements file at `.turbo/improvements.md` relative to that repo's root, resolved by the nearest `.git` directory.

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

## Step 3: Route and Append

- Append the entry to the `.turbo/improvements.md` of the repo whose files its **Where** names, which may not be the current repo.
- When **Where** spans several repos, split it into one entry per repo and append each to its own repo. Give every entry the titles of all its counterparts so a reader of any one backlog finds the others.
- Rewrite each split entry's **Where** so its paths read repo-local, matching the entries already in that backlog. Qualify any remaining reference that resolves only in another repo with the repo it lives in.
- When a target repo is not reachable on disk, say so plainly and append its entry to the current repo's backlog instead, naming the repo it was meant for.
- Write to a target repo other than the current one with the Edit or Write tool. The Bash sandbox denies a shell append into another repo, and a separately-issued verification command then prints the file's unchanged contents, which reads as success.

Read `.turbo/improvements.md` in each target repo if it exists. Create it with the header below if it doesn't.

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
- **Paired with**: <repo> — <title of the counterpart entry>
- **Noted**: <YYYY-MM-DD>
```

Include the Ceiling and Revisit lines when the entry records a deliberate simplification, and a Paired with line per counterpart when the entry is one half of a split; omit them otherwise. Append the new entry at the end of each target file.

## Step 4: Confirm

Tell the user the improvement was noted and where each entry was written.

## Rules

- Deduplicate before appending: check each target backlog for a similar entry and update it in place when one exists. When the existing entry predates the Type field, add a Type line while updating.
- When updating an existing entry tagged with the legacy values `trivial` or `standard`, rewrite the Type to `direct` or `plan` respectively so the file converges on current vocabulary.
- Keep entries concise. These are backlog items, not specs.
- When a deliberate simplification's revisit condition is not yet knowable, record what would have to be observed to know it.
- Record only; leave action to the user, who decides when to address it.
- When a target repo has no `.turbo/` directory, use `AskUserQuestion` to confirm the location before creating one.
