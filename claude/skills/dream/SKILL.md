---
name: dream
description: "Consolidate the project's auto memory in place (merge, correct, prune, re-index), then offer to clean up .turbo/. Use when the user asks to \"dream\", \"tidy memory\", or \"clean up stale notes\"."
---

# Dream

Consolidate this project's auto memory, then clear out what `.turbo/` no longer needs.

Text passed with the invocation steers the memory pass: what to look for and how to organize the notes. Every note is still read, and Step 3's conditions for deleting a note hold regardless.

## Step 1: Read the Memory

Use the auto-memory directory the system prompt names. When it names none, an effective `autoMemoryDirectory` setting gives the location. Otherwise the directory is `<Claude config home>/projects/<encoded project root>/memory/`. The config home is `CLAUDE_CONFIG_DIR` when set and `~/.claude` otherwise. The key replaces every character outside `A-Za-z0-9` with `-`, and long keys may be truncated and hashed.

List the directory, then read `MEMORY.md` and every note with the Read tool. When the directory does not exist or holds no notes, say so and continue with Step 4.

## Step 2: Gather Evidence

Judge each statement in every note, and in every entry `MEMORY.md` holds in full rather than as a pointer to a note, by its kind:

- **A claim the project can confirm or refute**, such as a path, a symbol, a flag, or a command: check it by searching the current code, reading a file only where the match does not settle the claim. A claim about how a tool behaves at runtime is unverifiable unless reading settles it.
- **A decision or preference of the user**: the code never contradicts it. Only a note modified more recently, or the user reversing it in a session transcript, does.
- **Anything else**: unverifiable.

Search the session transcripts only to settle which of two notes that contradict each other holds. Claude Code writes them to `<Claude config home>/projects/<key>/<session-id>.jsonl`. A session started in a subdirectory uses its own key, so match the encoded project root as a prefix. An `autoMemoryDirectory` setting does not move them. Search the transcripts modified after the older of the two notes for a narrow term, and output a short window around each match rather than the whole line, since one line can hold an entire tool result.

The step is done when every statement carries one of three verdicts: confirmed, contradicted with the evidence named, or unverifiable.

## Step 3: Consolidate the Memory

Apply these changes without asking, following the memory conventions from the system prompt:

- **Merge** notes that cover the same fact into the one that covers it best, keeping every detail any of them held, and delete the others.
- **Correct** a contradicted statement so it states what the evidence shows. Delete the note when nothing true remains in it.
- **Leave** the content of an unverifiable statement as it stands. Merging and date rewriting still apply to it.
- **Rewrite** a relative date as an absolute one when the note's own text fixes the day.
- **Repoint** each link in another note that names a note merged away at the note that absorbed it, and remove each link to a deleted note.
- **Re-index** `MEMORY.md`: one line per note, each pointing at a file that exists. Leave entries it holds in full where they are, correcting or deleting them under the rules above.

Before the first edit this step makes to a note, and before deleting one, output its path and its full original text. Output each line of `MEMORY.md` before changing or removing it. Leave every file that is not a note or the index untouched.

When a write or a deletion is refused, continue with the rest and carry what is left to do into Step 5.

## Step 4: Clean Up `.turbo/`

Resolve the repo root with `git rev-parse --show-toplevel`, except inside a linked worktree — where `git rev-parse --git-dir` differs from `--git-common-dir` — in which case use the parent of the common dir. Outside a git repository, use the working directory. When that root has no `.turbo/` directory, continue with Step 5.

List the top-level entries of `.turbo/` with one command that prints one line per entry: its size and the date of its newest file. Say what each holds from its name and, for a file, its heading. Read the frontmatter `status:` of every plan with one search.

Recommend deleting or keeping each entry by its kind:

- **The backlog** (`backlog.md` and a legacy `improvements.md`) — keep
- **A plan** — delete when its frontmatter `status:` is `done`, keep otherwise, including a legacy `plan.md`
- **A standing document**, one fixed name that a skill replaces on each run — keep
- **A handoff, or a file that tracks one execution**, named `<label>-<tag>`, such as a ledger under `loops/` — keep
- **A file that only carried text to a command**, named by a random tag or by the identifier of what it carried — delete when it was last modified before today
- **A prototype, capture, or scratch directory** — delete when its newest file predates the last commit to what it shows
- **Anything else**, including an entry whose purpose you cannot tell — keep

Where a directory holds items with different recommendations, list the ones recommended for deletion together as one entry and the rest as another.

Output a numbered table of the entries with size, the date of the newest file, what each holds, and the recommendation.

Then use `AskUserQuestion`, one question per entry recommended for deletion, in number order, filling each call to its four-question limit:

- **Header** — `#<number>`
- **Question** — the entry's name, what it holds, its size and age, ending with "Delete or keep?"
- **Options** — **Delete (Recommended)** with the reason in its description, then **Keep** with what keeping costs in its description

After each call, delete the entries the user chose to delete. When an answer asks a question or gives an instruction in place of a choice, act on it, then ask about that entry again when delete or keep is still open. When a deletion is refused, carry it into Step 5.

## Step 5: Report

Output what changed:

- **Memory** — each note merged, corrected, or deleted, with the evidence for it, the dates rewritten, and the index lines added, changed, or removed
- **`.turbo/`** — each entry deleted, with the space freed
- **Left to do** — each write or deletion that was refused, with the path

Then use the TaskList tool and proceed to any remaining task.
