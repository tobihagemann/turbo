---
name: create-prompt-plan
description: This skill should be used when the user asks to "create a prompt plan", "break spec into prompts", "decompose spec into sessions", "plan prompts for spec", "generate prompts from spec", "make prompts from spec", or wants to decompose a specification file into context-sized implementation prompts.
---

# Create Prompt Plan

Read a specification file and decompose it into a series of implementation prompts. Each prompt represents one unit of work for a separate Claude Code session. Save the output to `.turbo/prompts.md`.

General skill assignment happens later by `/pick-next-prompt` when each prompt is planned for implementation. However, if the spec implies domain-specific skills, mention those specific skills in the prompt text as hints.

## Step 1: Read the Spec

Read the spec file. Default location: `.turbo/spec.md`. Accept a different path if provided by the user.

Identify:
- **Scope** — total surface area of work
- **Work categories** — UI, backend, data layer, infrastructure, tests, documentation, tooling
- **Dependencies** — which pieces must exist before others can start
- **Greenfield vs existing** — is there an established codebase to work within

## Step 2: Decompose Into Prompts

Split the spec into prompts where each prompt fits a single Claude Code context session. Run the `/plan-implementation` skill and apply its Decomposition section (Sizing and Ordering), treating each "unit" as a prompt.

### Status tracking

Each prompt gets a status: `pending`, `in-progress`, `done`.

## Step 3: Write .turbo/prompts.md

Create the `.turbo/` directory if it does not exist. Write the output using this format:

````markdown
# Prompt Plan: [Project/Feature Name]

Source: `.turbo/spec.md`
Generated: [date]
Total prompts: N

---

## Prompt 1: [Descriptive Title]
**Status:** pending
**Context:** [What state the project is in before this session starts]
**Depends on:** none

### Prompt

```
[What to build — specific files, features, acceptance criteria.
What "done" looks like — tests passing, endpoints working, etc.
Reference to spec sections if helpful.]
```

---

## Prompt 2: [Descriptive Title]
**Status:** pending
**Context:** [What prior prompts built that this one depends on]
**Depends on:** Prompt 1

### Prompt

```
[What to build...]
```
````

## Step 4: Verify with Subagents

After writing, launch three review agents **in parallel** to validate the prompt plan:

1. **Dead code / wiring gaps agent** — For each prompt, verify that every module or layer touched is explicitly mentioned. Check that protocol or backend work is always wired to a consumer (UI, CLI, API). Flag any prompt where new capabilities are added without a corresponding integration point — these will produce dead code.

2. **Spec completeness agent** — Cross-check every item in the spec against the prompt plan. Verify each item is assigned to exactly one prompt (no duplicates, no gaps). Confirm intentionally omitted items are documented. Validate the dependency chain is acyclic and correct.

3. **Cross-reference validation agent** — If the prompts reference external resources (other codebases, documentation, APIs, search terms), verify those references are accurate. Check that suggested search terms actually find relevant code, that referenced projects actually implement the feature, and that the most useful reference is called out as primary.

Once all three agents complete, run `/evaluate-findings` on their combined output to triage issues and apply fixes to `.turbo/prompts.md`.

## Step 5: Present Summary

After writing and verification, present a brief summary: number of prompts, one-line description of each prompt's scope, and any assumptions made about ambiguities.

## Rules

- Never merge setup and finalization into the same prompt
- If the spec is ambiguous about what belongs together, split conservatively (smaller prompts are safer than oversized ones)
- Each prompt must be self-contained with enough context to understand the work without reading the full spec
- The `.turbo/prompts.md` file is the only output — do not modify the spec or project files
