---
name: implement-improvements
description: "Validate improvements from .turbo/improvements.md, recommend a working set tailored to what's in the backlog, and run one lane: trivial fixes, investigation, or standard planning. One lane per session. Use when the user asks to \"implement improvements\", \"work on improvements\", \"address improvements\", \"process improvement backlog\", \"tackle improvements\", or \"implement noted improvements\"."
---

# Implement Improvements

Validate improvements from `.turbo/improvements.md`, propose a specific working set based on the backlog's actual contents, and run one lane per session: trivial, investigate, or standard. Mixing lanes in a single run tangles commits, so the skill processes exactly one lane each time. Entries outside the confirmed working set stay in the backlog for future runs.

## Task Tracking

At the start, use `TaskCreate` to create a task for each step:

1. Read the backlog
2. Validate and classify
3. Recommend, confirm, and prune stale
4. Run the chosen lane
5. Prune working-set entries from the backlog

## Step 1: Read the Backlog

Read `.turbo/improvements.md`. If the file does not exist, tell the user there are no improvements to implement and stop.

Parse all entries, extracting for each:

- **Summary** (the `###` heading)
- **Type** (`trivial`, `investigate`, or `standard`; may be missing in older entries)
- **Category**
- **Where** (file paths or areas)
- **Why** (rationale)
- **Noted** (date)

## Step 2: Validate and Classify

Improvements can go stale: files get renamed, code gets refactored, issues get fixed as side effects of other work. Before routing, validate each improvement and classify any entry missing a Type.

### Validate

For each entry, verify whether the specific problem or opportunity described still exists. Do not rely on git log alone. Recent commits touching the same files do not mean the specific issue was addressed. Read the actual code and confirm:

1. **Files exist** — Do the referenced files/paths still exist? If not, the entry is stale.
2. **Problem persists** — Read the relevant code sections. Is the exact issue or opportunity described in the entry still present? Check the specific claims: if the entry says a function is uncalled, verify it has no callers; if it says error handling is missing, check whether it was added.

Classify each entry as:

- **Active** — The described problem or opportunity is confirmed present in the current code
- **Stale** — The referenced files no longer exist, or the specific issue has been resolved (cite evidence: what changed and where)
- **Unclear** — Cannot determine from code alone, needs user input

When in doubt, classify as Active. The cost of re-examining a resolved issue is low; dismissing a valid improvement is high.

### Classify type if missing

For any Active entry without a Type field, infer one on the fly. Base the classification on the code you just read during validation, not just the entry's one-line summary.

- **trivial** — A direct fix: typo, rename, obvious one-liner, small localized cleanup with clear scope. No investigation or plan needed.
- **investigate** — A symptom, not a fix: unclear root cause, performance question, intermittent bug, "something feels off". Needs dedicated root-cause analysis before any change.
- **standard** — Everything else: clear-scope work that warrants planning (multi-file refactor, test additions, feature work).

Do not ask the user to pick. If genuinely ambiguous, default to `standard`.

## Step 3: Recommend, Confirm, and Prune Stale

Output the backlog status as text first, grouped by type and status. Include each entry's category inline and a category tally across active entries:

```
## Improvement Backlog Status

### Active (N)
Categories: refactor (N), performance (N), testing (N), docs (N)

**Trivial (N)**
- [summary] (category) — [one-line reason it's still relevant]

**Investigate (N)**
- [summary] (category) — [one-line reason it's still relevant]

**Standard (N)**
- [summary] (category) — [one-line reason it's still relevant]

### Stale (N)
- [summary] — [one-line reason it's stale]

### Unclear (N)
- [summary] — [what's ambiguous]
```

### Recommend a Working Set

Pick one specific working set tailored to the active entries. Read the entries again before recommending and weigh:

- **Cohesion** — Entries that share files, modules, or themes are stronger when batched. A cluster of related testing or reliability entries usually beats a scattered mix.
- **Decisiveness** — One investigation that unblocks several deferred entries can outweigh a larger trivial batch.
- **Impact vs effort** — A reliability or correctness entry often outweighs lower-stakes cleanups even when it's a single entry.
- **Lane shape** — Trivial naturally batches multiple fixes per session, investigate runs one symptom per session, standard hands one entry to `/turboplan` per session.
- **Unit of work size** — Don't undersize the session. A trivial batch should fill a focused session, so prefer the whole cohesive cluster over a narrow filter unless the filter clearly preserves session-sized work. Picking 1–2 entries off a cluster of 7 wastes the slot. Investigate and standard lanes are naturally one entry per session, but reject entries that turn out to be one-line fixes — those belong in the trivial lane.
- **Backlog state** — Heavy trivial concentration calls for clearing the cluster; a long-deferred symptom often deserves the slot.

State the recommendation as: lane + concrete working set (specific entries or a category-scoped subset) + one or two sentences on why this beats the alternatives. Then list 1–3 honest alternatives, each named with the actual entry or subset (e.g., "investigate the flaky presence test", "standard lane on persist-before-send"). When only one lane has active entries, recommend that lane and skip alternatives.

### Confirm via AskUserQuestion

Use `AskUserQuestion` to confirm. Combine into the same prompt:

1. Confirm the recommended working set or pick one of the named alternatives
2. Whether to remove stale entries — include only when stale entries exist
3. Resolution for unclear items — include only when unclear entries exist

If the user confirmed stale removal, edit `.turbo/improvements.md` to delete the stale entries.

Compute the **working set** from the confirmed choice. If the working set is empty, stop.

## Step 4: Run the Chosen Lane

Read the reference file for the confirmed lane and follow its phases:

- **Trivial lane** — [references/trivial-lane.md](references/trivial-lane.md)
- **Investigate lane** — [references/investigate-lane.md](references/investigate-lane.md)
- **Standard lane** — [references/standard-lane.md](references/standard-lane.md)

State the chosen lane before continuing with the reference file.

## Step 5: Prune Working-Set Entries from the Backlog

Edit `.turbo/improvements.md` to delete the working-set entries that the lane processed. "Processed" means:

- **Trivial lane** — entries whose fixes were applied
- **Investigate lane** — entries whose concluded fixes were applied
- **Standard lane** — entries now captured in the plan file produced by `/turboplan`

Keep any entries the lane re-classified mid-flight (trivial → investigate/standard, or investigate → standard). These stay in the backlog for a future run. Delete the file if no entries remain.

## Rules

- `.turbo/` is gitignored. Edits to `.turbo/improvements.md` are local-only and do not need to be staged or committed.
- If the user selected a lane, do not secondarily run another lane in the same session. Other active entries stay in the backlog for a future run.
