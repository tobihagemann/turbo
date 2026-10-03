---
name: triage-improvements
description: "Triage the improvements backlog at .turbo/improvements.md: merge duplicate entries, state the user story or simplification behind each one, and decide with the user which to keep and which to drop. Use when the user asks to \"triage improvements\", \"triage the backlog\", \"clean up the backlog\", \"clean up improvements\", \"groom the backlog\", \"prune the improvements backlog\", or \"go through the backlog with me\"."
---

# Triage Improvements

Decide, entry by entry, which improvements in `.turbo/improvements.md` are worth keeping.

## Step 1: Read the Backlog and Merge Duplicates

Read `.turbo/improvements.md`, relative to the repo root resolved with `git rev-parse --show-toplevel`, except inside a linked worktree — where `git rev-parse --git-dir` differs from `--git-common-dir` — in which case use the parent of the common dir. When the file does not exist or holds no entries, present "No improvements to triage." Then use the TaskList tool and proceed to any remaining task.

Merge entries that cover the same improvement into one entry that keeps every detail either held, write the merged entries back, and output which ones were merged. Update each **Paired with** line in counterpart entries that names a title the merge retired.

Number the remaining entries in file order.

## Step 2: Assess Each Entry

Work from each entry's own text. Read the code an entry names only when its text is too thin to say what the entry is for.

For each entry, settle the two parts its question in Step 3 carries, without outputting them yet:

- **Story** — one sentence naming who benefits and what they get, in plain language a reader who has not seen the code can follow. When nothing changes for the person using the software, tell it from the maintainer's side: what the entry simplifies.
- **Recommendation** — keep or drop, with a one-line reason.

Recommend keeping an entry that serves a goal the person using the software actually has, fixes a problem that was observed, or simplifies existing code. Recommend dropping one that is theoretical or was never observed, is decoration, would be resolved by another entry's fix, or adds machinery no requirement demands. For an entry carrying a **Revisit** line, apply these criteria to the fuller version it describes as though its condition held; the condition being unmet is no ground to drop it. When the entry's text settles neither, recommend neither and name what is unclear.

## Step 3: Decide Keep or Drop

Use `AskUserQuestion`, one question per entry in number order, filling each call to its four-question limit:

- **Header** — `#<number>`
- **Question** — the entry's summary, then its story, then what is unclear when Step 2 recommended neither, ending with "Keep or drop?"
- **Options** — **Keep** and **Drop**. Place the recommended one first with "(Recommended)" appended and put the reason in its description. In the other's description, say what choosing it gives up. When neither is recommended, list **Keep** first unlabeled and say in each description what choosing it gives up.

After each call, delete the entries the user dropped from `.turbo/improvements.md`. When a dropped entry carries a **Paired with** line, remove that reference from each counterpart entry it names. When an answer asks a question or gives an instruction in place of a choice, act on it, then ask about that entry again when keep or drop is still open.

Repeat until every entry is decided.

## Step 4: Report

Delete `.turbo/improvements.md` when no entries remain. Output the entry count as read and the count remaining, followed by the summaries of the dropped and merged entries.

Then use the TaskList tool and proceed to any remaining task.
