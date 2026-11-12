---
name: backlog
description: "Capture an out-of-scope improvement or accepted simplification in .turbo/backlog.md. Use proactively mid-task, or when the user asks to \"backlog this\", \"note this idea\", or \"track this for later\"."
---

# Backlog

Capture improvement opportunities discovered during work so they don't get silently dropped. Appends to the `.turbo/backlog.md` file of the repo an improvement concerns.

## Step 1: Locate the Backlog File

Each repo keeps its backlog at `.turbo/backlog.md` relative to that repo's root. Resolve that root with `git -C <repo path> rev-parse --show-toplevel`, except inside a linked worktree — where `git -C <repo path> rev-parse --git-dir` differs from `--git-common-dir` — in which case use the parent of the common dir, so the entry lands in the main checkout rather than in a worktree that is destroyed with its branch.

## Step 2: Identify the Improvement

Gather from context or `$ARGUMENTS`:

- **What**: One-line summary of the improvement
- **Type**: One of `direct`, `investigate`, or `plan` — see criteria below
- **Category**: One of `refactor`, `performance`, `reliability`, `readability`, `testing`, `docs`, `dx` (developer experience), or `feature`
- **Where**: File path(s) and/or area of the codebase affected
- **Why**: Brief rationale — what's the benefit? For a defect or risk, whether it was observed in use or derived from reading code or a review.
- **Ceiling** and **Revisit**: when the entry records a deliberate simplification, meaning a simpler approach was shipped in place of a fuller one and accepts a known limit — the limit the shipped approach accepts, and the condition that makes the fuller version worth building. **Revisit** alone when the entry waits on an outside event: that event

### Type criteria

- **direct** — Clear scope and a known approach, ready to apply via `/implement`.
- **investigate** — A symptom that needs root-cause analysis first: unclear root cause, performance question, intermittent bug, "something feels off".
- **plan** — Everything else: the approach warrants writing down before implementing (multi-file refactor, test additions, feature work).

When the criteria above clearly select one value, use it. Otherwise, use `AskUserQuestion` to confirm; default to `plan` if the user declines to choose.

## Step 3: Route and Append

- Append the entry to the `.turbo/backlog.md` of the repo whose files its **Where** names, which may not be the current repo.
- When **Where** spans several repos, split it into one entry per repo and append each to its own repo. Give every entry the titles of all its counterparts so a reader of any one backlog finds the others.
- Rewrite each split entry's **Where** so its paths read repo-local, matching the entries already in that backlog. Qualify any remaining reference that resolves only in another repo with the repo it lives in.
- When a target repo's checkout cannot be found on disk, use `AskUserQuestion` to ask where it is cloned, offering as the alternative to note its entry in the backlog of the repo root resolved in Step 1. Given a path, route the entry to the repo at that path. Without one, say that the checkout was not found and append the entry to that backlog, naming the repo it was meant for.
- Write to any path outside the current working directory with the Edit or Write tool, the main checkout of the worktree this session runs in included. The Bash sandbox denies a shell append there, and a separately-issued verification command then prints the file's unchanged contents, which reads as success.
- When that write is refused while this session runs inside a linked worktree, report that the entry cannot be persisted from here and print the fully formatted entry so it can be pasted in from a session that can write to the main checkout. Leave it out of the worktree's own `.turbo/`, which is gitignored and is destroyed with the worktree.

When a target repo holds the legacy `.turbo/improvements.md`, carry it into that repo's `.turbo/backlog.md` before reading, with the Write or Edit tool. When `.turbo/backlog.md` does not exist, write the legacy content there with its `# Improvements` header changed to `# Backlog`. Otherwise, append each legacy entry that `.turbo/backlog.md` does not already hold word for word. Once `.turbo/backlog.md` holds every legacy entry, delete the legacy file. When the write or the deletion is refused, tell the user what is left to do.

Read `.turbo/backlog.md` in each target repo if it exists. Create it with the header below if it doesn't.

**File header** (only when creating new):

```markdown
# Backlog

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

Include the Ceiling and Revisit lines when the entry records a deliberate simplification, the Revisit line alone when the entry waits on an outside event, and a Paired with line per counterpart when the entry is one half of a split; omit them otherwise. Append the new entry at the end of each target file.

## Step 4: Confirm

Tell the user the improvement was noted and where each entry was written, or that it could not be persisted and is printed above.

Then use the TaskList tool and proceed to any remaining task.

## Rules

- Deduplicate before appending: search each target backlog for the paths and symbols the new entry names and for entries on a similar subject, and update an existing entry in place when it covers the same improvement. When the existing entry predates the Type field, add a Type line while updating.
- When updating an existing entry tagged with the legacy values `trivial` or `standard`, rewrite the Type to `direct` or `plan` respectively so the file converges on current vocabulary.
- Keep entries concise. These are backlog items, not specs.
- When a deliberate simplification's revisit condition is not yet knowable, record what would have to be observed to know it.
- Record only; leave action to the user, who decides when to address it.
- When a target repo has no `.turbo/` directory, use `AskUserQuestion` to confirm the location before creating one.
