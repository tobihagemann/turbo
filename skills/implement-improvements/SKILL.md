---
name: implement-improvements
description: "Plan and implement improvements from the .turbo/improvements.md backlog after validating them against the current codebase. Use when the user asks to \"implement improvements\", \"work on improvements\", \"address improvements\", \"process improvement backlog\", \"tackle improvements\", or \"implement noted improvements\"."
---

# Implement Improvements

Read the improvements backlog at `.turbo/improvements.md`, validate each entry against the current codebase to filter out stale items, then plan and implement all remaining improvements in a single session.

## Step 1: Read the Backlog

Read `.turbo/improvements.md`. If the file does not exist, tell the user there are no improvements to implement and stop.

Parse all entries, extracting for each:

- **Summary** (the `###` heading)
- **Category**
- **Where** (file paths or areas)
- **Why** (rationale)
- **Noted** (date)

## Step 2: Validate Against Current Codebase

Improvements can go stale: files get renamed, code gets refactored, issues get fixed as side effects of other work. Before planning, validate each improvement.

For each entry, check whether the improvement still applies:

1. **Files exist** — Do the referenced files/paths still exist?
2. **Problem persists** — Read the relevant code. Is the issue or opportunity still present?
3. **Not already addressed** — Check git log for recent changes to the referenced files that may have already resolved the improvement.

Classify each entry as:

- **Active** — Still relevant, proceed with implementation
- **Stale** — No longer applicable (file removed, code refactored, issue fixed)
- **Unclear** — Cannot determine from code alone, needs user input

## Step 3: Report Findings

Present a summary to the user:

```
## Improvement Backlog Status

### Active (N)
- [summary] — [one-line reason it's still relevant]

### Stale (N)
- [summary] — [one-line reason it's stale]

### Unclear (N)
- [summary] — [what's ambiguous]
```

Use `AskUserQuestion` to confirm:
1. Which active improvements to implement (default: all)
2. Whether to remove stale entries from the backlog
3. Resolution for any unclear items

## Step 4: Plan and Enhance

If there are more than 10 active improvements, suggest splitting into multiple sessions and use `AskUserQuestion` to determine which subset to tackle first.

Enter plan mode. Design an implementation plan that addresses all confirmed improvements together, looking for:

- **Synergies** — Improvements touching the same files or areas should be grouped
- **Dependencies** — Order improvements so that foundational changes come first
- **Conflicts** — Flag if two improvements contradict each other

Run `/enhance-plan` first to add task tracking, a skills line, and a finalize step to the plan. Add a final instruction: "Remove implemented improvements from `.turbo/improvements.md`."

## Step 5: Clean Up the Backlog

After implementation is complete (post-finalize), update `.turbo/improvements.md`:

- Remove entries that were implemented
- Remove entries confirmed as stale in Step 3
- Keep entries the user chose to skip or defer

If all entries are removed, delete the file.

