---
name: simplify-code
description: "Run a multi-agent review of changed files for scope, reuse, quality, efficiency, clarity, and altitude issues followed by fixes. Use when the user asks to \"simplify code\", \"review changed code\", \"check for code reuse\", \"review code quality\", \"review efficiency\", \"simplify changes\", \"clean up code\", \"refactor changes\", or \"run simplify\"."
---

# Simplify Code

Review code for scope, reuse, quality, efficiency, clarity, and altitude issues, then fix them.

## Step 1: Determine the Scope

Determine what to review:

- If a specific **diff command** was provided (e.g., `git diff --cached`), use that.
- If a **file list or directory** was provided, review those files directly (read the full files, not a diff).
- If **neither** was provided, determine the appropriate diff command (e.g., `git diff`, `git diff --cached`, `git diff HEAD`) based on the current git state. If there are no git changes, review the most recently modified files mentioned in the conversation.

## Step 2: Launch Six Review Agents in Parallel

Launch all six agents below with `spawn_agent` / `wait_agent` using inherited model defaults, issuing every call in one batch. Do not issue one and await its result before issuing the rest. Pass the scope from Step 1 to each agent. Every sub-agent's prompt must direct it to treat the shared working tree and its git index as read-only and to reach its findings by reading and reasoning; fixes happen in Step 3. HEAD stays where it is: read other refs with `git show <ref>:<path>` rather than `git checkout` or `git switch`.

Confine the sub-agent's prompt to what to review, plus the conventions and factual properties that bear on it. Pass a property of the existing code as a fact the sub-agent weighs, such as "the retry loop guards a dependency known to fail intermittently". Leave out any statement that tells the sub-agent what verdict to reach about that property, such as "the duplication here is intentional for readability, judge against that", because it binds the sub-agent to accept the very property the review exists to assess.

### Agent 1: Scope Review

Review the changes for code that should not exist:

1. **Unrequested machinery**: an abstraction with one implementation, a configuration point with one caller, a factory for one product, a wrapper that only delegates, scaffolding for an anticipated requirement. Recommend deletion rather than simplification.
2. **Unreachable defensive code**: a branch, guard, retry, or fallback for a state the surrounding code's own constraints rule out. When the callers cannot produce the input, the handling for it is dead on arrival.
3. **Reinvented standard library or platform feature**: hand-rolled logic the language's standard library or the target platform already ships, or a new dependency for what an already-installed one covers. Name the replacement.

Trace the callers of any code proposed for deletion and confirm nothing depends on the behavior being removed. Input validation at trust boundaries, error handling that prevents data loss, security controls, accessibility affordances, and anything the request explicitly asked for outrank the three checks above.

### Agent 2: Code Reuse Review

For each change:

1. **Search for existing utilities and helpers** that could replace newly written code. Look for similar patterns elsewhere in the codebase — common locations are utility directories, shared modules, and files adjacent to the changed ones.
2. **Flag any new function that duplicates existing functionality.** Suggest the existing function to use instead.
3. **Flag any inline logic that could use an existing utility** — hand-rolled string manipulation, manual path handling, custom environment checks, and similar patterns are common candidates.

### Agent 3: Code Quality Review

Review the same changes for hacky patterns:

1. **Redundant state**: state that duplicates existing state, cached values that could be derived, reactive subscriptions that could be direct calls
2. **Parameter sprawl**: adding new parameters to a function instead of generalizing or restructuring existing ones
3. **Copy-paste with slight variation**: near-duplicate code blocks that should be unified with a shared abstraction
4. **Leaky abstractions**: exposing internal details that should be encapsulated, or breaking existing abstraction boundaries
5. **Stringly-typed code**: using raw strings where constants, enums, or dedicated types already exist in the codebase
6. **Unnecessary wrapper nesting**: container elements or wrapper layers that add no structural or layout value

### Agent 4: Efficiency Review

Review the same changes for efficiency:

1. **Unnecessary work**: redundant computations, repeated file reads, duplicate network/API calls, N+1 patterns
2. **Algorithmic complexity**: nested iterations, repeated linear searches replaceable by sets/maps, missing early exits
3. **Missed concurrency**: independent operations run sequentially when they could run in parallel
4. **Hot-path bloat**: new blocking work added to startup or per-request hot paths
5. **Unnecessary existence checks**: pre-checking file/resource existence before operating (TOCTOU anti-pattern) — operate directly and handle the error
6. **Memory**: unbounded data structures, missing cleanup, resource leaks
7. **Overly broad operations**: reading entire files when only a portion is needed, loading all items when filtering for one

### Agent 5: Clarity and Standards Review

Review the same changes for clarity, standards, and balance:

1. **Project standards**: coding conventions not followed — import sorting, naming conventions, component patterns, error handling patterns, module style. Beyond the auto-loaded instruction files, walk each directory that is an ancestor of a changed file, from the project root down, and read its `AGENTS.override.md` when one is present, otherwise its `AGENTS.md` — a directory's file governs only the files at or below it, and an override replaces that directory's `AGENTS.md` rather than adding to it. Flag a violation only when you can quote the exact rule and cite what breaks it: the offending line, or the location where a required element is missing. Name the file the rule came from
2. **Unnecessary complexity**: deep nesting, unclear variable or function names, nested conditionals 3+ levels deep (ternary chains like `a ? x : b ? y : ...`, nested if/else, or nested switch — flatten with early returns, guard clauses, a lookup table, or an if/else-if cascade), redundant boolean comparisons (e.g., `x == true` instead of `x`)
3. **Unclear code**: choose clarity over brevity — explicit code is better than overly compact code. Consolidate related logic, but not at the cost of readability
4. **Over-simplification**: overly clever solutions that are hard to understand, too many concerns combined into single functions or components, "fewer lines" prioritized over readability (dense one-liners), helpful abstractions removed that were aiding code organization
5. **Dead weight**: code no longer reached by any path, and variables, imports, or parameters the change orphaned
6. **Unnecessary comments**: comments explaining WHAT the code does, narrating the change, or referencing the task/caller — delete; keep only non-obvious WHY (hidden constraints, subtle invariants, workarounds)

### Agent 6: Altitude and Fix-Depth Review

Review the same changes for whether each is implemented at the right depth:

1. **Special case on shared infrastructure**: a narrow branch, flag, or conditional bolted onto a shared mechanism to handle one case, where generalizing the mechanism would remove the need for the special case. Name the generalization.
2. **Shallow fix at the symptom**: a change applied at one call site that the same shape will require again at the next similar site. Prefer addressing the shared root.
3. **Wrong layer**: logic placed in a caller, wrapper, or leaf when it belongs in the shared layer all paths flow through, or pushed into shared infrastructure when it is specific to one caller.

## Step 3: Fix Issues

Wait for all six agents to complete. Aggregate their findings, then apply each fix directly, skipping only findings that are wrong. When a deletion recommendation and a refactor recommendation land on the same code, the deletion wins.

A finding that would revise an interface or shape the user already approved is not a false positive. Output its technical detail as text, then use `request_user_input` to let the user decide, naming what the revision would change and what reversing the earlier decision costs. Place the genuinely best option first and append `(Recommended)` to its label, judging "best" on technical merit alone, independent of how closely it conforms to the earlier decision. When merit cannot settle it, say so instead of forcing a pick. Present the consultation option in place of **Note for later**, keeping the question at three options:

- **Apply** — make the change
- **Keep the approved shape** — leave as-is
- **Note for later** — run the `$note-improvement` skill to capture it
- **Get a second opinion** — run the `$consult-claude` skill for the soundest shape on technical merit alone, independent of the earlier decision, carrying back what changing it costs. Then apply, keep, or note the finding with that answer in hand

A freeform answer asking to record the finding without changing the code runs the `$note-improvement` skill to capture it.

Report the outcome as a table, one row per finding, keeping every cell to a single line:

| File | Finding | Outcome |
|------|---------|---------|

Where Outcome is one of:

- **Fixed** — the fix was made
- **Escalated** — name the resolution the user chose: fixed, kept, or noted for later
- **Skipped** — name the reason

Keep the report to the table. Add prose only where an escalation's resolution changed what the other fixes look like. When the table would be empty, report one line stating the code was already clean instead.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.
