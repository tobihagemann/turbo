# Simplicity Review Reference

## Review Instructions

Focus on single-file simplicity: reuse, quality, efficiency, and clarity issues that surface within an individual file or a small set of changes.

For reuse, identify analogous utilities, helpers, or shared modules elsewhere in the project before suggesting a rewrite. Common locations are utility directories, shared modules, and files adjacent to the changed ones.

## What to Review

### Reuse

- **Duplicate functionality** — new functions that duplicate existing utilities; suggest the existing function to use instead
- **Inline logic that could use an existing utility** — hand-rolled string manipulation, manual path handling, custom environment checks, and similar patterns where a utility already exists

### Single-File Quality

- **Redundant state** — state that duplicates existing state, cached values that could be derived, reactive subscriptions that could be direct calls
- **Parameter sprawl** — new parameters added to a function instead of generalizing or restructuring existing ones
- **Copy-paste with slight variation** — near-duplicate code blocks within the same file that should be unified with a shared abstraction
- **Leaky abstractions** — exposing internal details that should be encapsulated, or breaking existing abstraction boundaries
- **Stringly-typed code** — raw strings used where constants, enums, or dedicated types already exist in the codebase
- **Unnecessary wrapper nesting** — container elements or wrapper layers that add no structural or layout value

### Efficiency

- **Unnecessary work** — redundant computations, repeated file reads, duplicate network/API calls, N+1 patterns
- **Algorithmic complexity** — nested iterations, repeated linear searches replaceable by sets/maps, missing early exits
- **Missed concurrency** — independent operations run sequentially when they could run in parallel
- **Hot-path bloat** — new blocking work added to startup or per-request hot paths
- **Unnecessary existence checks** — pre-checking file/resource existence before operating (TOCTOU anti-pattern); operate directly and handle the error
- **Memory** — unbounded data structures, missing cleanup, resource leaks
- **Overly broad operations** — reading entire files when only a portion is needed, loading all items when filtering for one

### Clarity and Standards

- **Project standards** — coding conventions from CLAUDE.md not followed (import sorting, naming conventions, component patterns, error handling patterns, module style)
- **Unnecessary complexity** — deep nesting, redundant abstractions, unclear variable or function names, nested conditionals 3+ levels deep (ternary chains like `a ? x : b ? y : ...`, nested if/else, or nested switch — flatten with early returns, guard clauses, a lookup table, or an if/else-if cascade), redundant boolean comparisons (e.g., `x == true` instead of `x`)
- **Unclear code** — overly compact one-liners that sacrifice readability; explicit code is better than clever code
- **Over-simplification** — too many concerns combined into a single function or component, helpful abstractions removed that were aiding code organization, "fewer lines" prioritized over readability
- **Dead weight** — redundant code, abstractions that add indirection without value

### Altitude and Fix-Depth

- **Special case on shared infrastructure** — a narrow branch, flag, or conditional added to a shared mechanism to handle one case, where generalizing the mechanism removes the need for the special case; name the generalization
- **Shallow fix at the symptom** — a change applied at one call site that the same shape will require again at the next similar site; prefer addressing the shared root
- **Wrong layer** — logic placed in a caller, wrapper, or leaf when it belongs in the shared layer all paths flow through, or pushed into shared infrastructure when it is specific to one caller

### Comments and Documentation

- **Restates code, signature, or name** — paraphrases the immediately-following statement or multi-statement block; doc blocks whose text translates a declaration's name; doc blocks above a declaration whose prose elaborates the name and signature without adding rationale; parameter/return descriptions that only echo names and types. Non-obvious constraints (size, units, ranges, preconditions) stay; drop the wrapping parameter/return/error enumeration when no entries survive trimming
- **History or change narration** — references to PRs, tickets, prior behavior, recent changes, "fixed by"/"previously did X"/"no longer Y" framing, or session-narrative voice ("turns out", "discovered", "we found that"); state the current invariant only — past behavior belongs in git history, and session-derived lessons about tooling belong in auto memory or project instructions
- **Cross-references that decay** — names the caller ("used by X", "called from Y"), or task/flow/feature-flag context the code was added for ("added for the Y flow", "for the rollout"); delete — caller relationships belong in the call graph, feature context in the PR description
- **Framework or stdlib explainers** — describes what a well-known language keyword or library construct does
- **Low-value section banners** — banners that don't section anything, or that restate what an access modifier or naming convention already conveys
- **Overgrown rationale** — a comment that captures real WHY but in more lines or concerns than the rationale requires; tighten to one sentence per concern, split bundled concerns to their decision points, or lift shared rationale to a design doc or commit message
- **Compensates for unclear code** — a comment that exists because the code is hard to read; flag the underlying code as a refactor opportunity (rename, extract, restructure) rather than tightening the comment
- **Markdown status-update voice** — for markdown changes in the diff, prose framed as recent updates or transitions; rewrite as timeless current-state prose

## Determination Criteria

Flag an issue only when ALL of these hold:

1. The issue meaningfully impacts readability, maintainability, correctness, or performance
2. The issue is discrete and actionable
3. A specific fix is obvious (reuse existing utility X, remove redundant state Y, collapse nested wrapper Z)
4. The fix does not demand rigor beyond what exists in the rest of the codebase
5. The author would likely accept the fix if aware of it

## Priority Levels

- **P0** — Severe efficiency problem on a hot path, or a reuse miss that duplicates a load-bearing utility
- **P1** — Clear duplication, leaky abstraction, or efficiency issue with meaningful impact
- **P2** — Moderate clarity, efficiency, or reuse opportunity
- **P3** — Minor style or readability nit

## What to Ignore

- Style-only differences that do not obscure meaning or violate documented standards
- Micro-optimizations with no measurable impact
- Comments that capture a load-bearing constraint the code itself cannot express — a hidden constraint or invariant, a workaround for a specific bug (ideally with a reference), a non-obvious performance characteristic, a pointer to a spec or RFC section, or behavior that would surprise a future reader. Greenfield test: would you write this comment if the code had been greenfield from day one?

**Extra metadata:** `**Category:** <reuse | quality | efficiency | clarity | altitude | documentation>`

**Verdict label:** `Simplicity: <clean | issues found>`
