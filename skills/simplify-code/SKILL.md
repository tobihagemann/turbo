---
name: simplify-code
description: Run a multi-agent review of changed files for reuse, quality, efficiency, and clarity issues followed by automated fixes. Use when the user asks to "simplify code", "review changed code", "check for code reuse", "review code quality", "review efficiency", "simplify changes", "clean up code", "refactor changes", or "run simplify".
---

# Simplify Code

Review all changed files for reuse, quality, and efficiency. Fix any issues found.

## Step 1: Determine the Diff Command

Determine the appropriate diff command (e.g. `git diff`, `git diff --cached`, `git diff HEAD`) based on the current git state. If the caller specifies which diff command to use, use that. Do NOT run the diff yourself — each review agent will run it independently to keep the diff out of the main agent's context.

If there are no git changes, review the most recently modified files that the user mentioned or that you edited earlier in this conversation.

## Step 2: Launch Four Review Agents in Parallel

Use the Agent tool to launch all four agents concurrently in a single message. Every Agent tool call must set `model: "opus"`. Instruct each agent to run the diff command itself to obtain the diff.

### Agent 1: Code Reuse Review

For each change:

1. **Search for existing utilities and helpers** that could replace newly written code. Look for similar patterns elsewhere in the codebase — common locations are utility directories, shared modules, and files adjacent to the changed ones.
2. **Flag any new function that duplicates existing functionality.** Suggest the existing function to use instead.
3. **Flag any inline logic that could use an existing utility** — hand-rolled string manipulation, manual path handling, custom environment checks, ad-hoc type guards, and similar patterns are common candidates.

### Agent 2: Code Quality Review

Review the same changes for hacky patterns:

1. **Redundant state**: state that duplicates existing state, cached values that could be derived, observers/effects that could be direct calls
2. **Parameter sprawl**: adding new parameters to a function instead of generalizing or restructuring existing ones
3. **Copy-paste with slight variation**: near-duplicate code blocks that should be unified with a shared abstraction
4. **Leaky abstractions**: exposing internal details that should be encapsulated, or breaking existing abstraction boundaries
5. **Stringly-typed code**: using raw strings where constants, enums (string unions), or branded types already exist in the codebase
6. **Unnecessary JSX nesting**: wrapper Boxes/elements that add no layout value — check if inner component props (flexShrink, alignItems, etc.) already provide the needed behavior

### Agent 3: Efficiency Review

Review the same changes for efficiency:

1. **Unnecessary work**: redundant computations, repeated file reads, duplicate network/API calls, N+1 patterns
2. **Missed concurrency**: independent operations run sequentially when they could run in parallel
3. **Hot-path bloat**: new blocking work added to startup or per-request/per-render hot paths
4. **Unnecessary existence checks**: pre-checking file/resource existence before operating (TOCTOU anti-pattern) — operate directly and handle the error
5. **Memory**: unbounded data structures, missing cleanup, event listener leaks
6. **Overly broad operations**: reading entire files when only a portion is needed, loading all items when filtering for one

### Agent 4: Clarity and Standards Review

Review the same changes for clarity, standards, and balance:

1. **Project standards**: coding conventions from CLAUDE.md not followed — import sorting, naming conventions, component patterns, error handling patterns, module style
2. **Unnecessary complexity**: deep nesting, redundant abstractions, unclear variable or function names, comments that describe obvious code, nested ternary operators (prefer switch/if-else chains)
3. **Unclear code**: choose clarity over brevity — explicit code is better than overly compact code. Consolidate related logic, but not at the cost of readability
4. **Over-simplification**: overly clever solutions that are hard to understand, too many concerns combined into single functions or components, "fewer lines" prioritized over readability (dense one-liners, nested ternaries), helpful abstractions removed that were aiding code organization
5. **Dead weight**: unnecessary comments, redundant code, abstractions that add indirection without value

## Step 3: Fix Issues

Wait for all four agents to complete. Aggregate their findings, run the diff command to get the current diff, then apply each fix directly, skipping false positives. Only edit files — do not stage, build, or test.

When done, briefly summarize what was fixed (or confirm the code was already clean).
