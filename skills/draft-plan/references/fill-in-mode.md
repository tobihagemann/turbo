# Draft Plan: Fill-In Mode

Expand a shell plan into a full plan. The shell's Context, Produces, Consumes, Covers, and high-level Implementation Steps are authoritative; fill-in adds pattern survey, concrete references, and verification.

## Task Tracking

Use `TaskCreate` to create a task for each step:

1. Load the shell and verify consumes
2. Run `/survey-patterns` skill (shell-focused)
3. Escalate the shell's open questions
4. Run two fill-in drafts in parallel
5. Reconcile and write back to the shell path

## Step 1: Load the Shell and Verify Consumes

Read the shell file from the path passed by the caller. Parse these fields:

- **Title** (from the `# Plan:` heading)
- **Context** (the why)
- **Produces** (artifacts this shell creates)
- **Consumes** (dependencies this shell requires)
- **Covers Spec Requirements** (the spec sections this shell implements)
- **Implementation Steps (high-level)** (named tasks without file paths)
- **Open Questions** (decisions deferred to now)

**Verify Consumes are present in the current codebase.** For each Consumes entry:

- If marked "from existing codebase," grep or read relevant files to confirm the artifact still exists at the expected conceptual location
- If the entry references a prior shell's Produces (traceable via the prompt plan index), verify the prior shell has `Status: done` in the index AND that the artifact is actually present in the current codebase (the prior implementation may have diverged)

If any Consumes entry fails verification, escalate via `AskUserQuestion`:

- **Adapt the shell** — open the shell for editing, adjust the shell's Consumes/Implementation Steps to match what actually exists, then re-verify
- **Skip this prompt** — mark the shell's index entry back to `pending` and stop. Tell the user to run `/pick-next-prompt` again or resolve the prior work.
- **Stop and investigate** — halt without edits so the user can debug

Do not proceed to Step 2 until all Consumes verify cleanly.

## Step 2: Run `/survey-patterns` Skill (Shell-Focused)

Run the `/survey-patterns` skill with a task description built from the shell's structural content:

```
<shell title>

Context: <shell Context>
Produces: <shell Produces, as a bulleted list>
Implementation steps: <shell Implementation Steps, numbered>
```

This scopes the survey to the shell's concern area instead of a generic sweep. Keep the returned findings in conversation context for use in Step 4.

## Step 3: Escalate the Shell's Open Questions

For each entry in the shell's `Open Questions` field, present it via `AskUserQuestion` and collect the answer. Frame each question with enough context from the shell for the user to decide.

Do **not** escalate other questions. If you identify a new question while reading the codebase, note it as a risk in the drafted plan's Verification or Context Files sections.

If the shell's Open Questions field is empty or contains "None," skip this step entirely.

## Step 4: Run Two Fill-in Drafts in Parallel

Launch two Agent tool calls in a single message (`model: "opus"`, do not set `run_in_background`):

### Internal Fill-in Draft

Spawn a subagent and pass it:

- The complete shell content (Context, Produces, Consumes, Covers, high-level Implementation Steps, Open Questions)
- The resolved Open Questions from Step 3 (if any)
- The pattern survey findings from Step 2
- The shell file path (where the draft will be written)
- The full plan template and Content Rules listed below

Instruct it to:

1. Use the shell's Context as the plan's Context (preserve verbatim or lightly edit)
2. Use the shell's high-level Implementation Steps as the skeleton, concretizing each with `file_path:line_number` references, named functions, and specific symbols from the pattern survey
3. Add a Pattern Survey section with the Step 2 findings
4. Write a Verification section with specific test commands and expected observable results for this shell's work
5. Write a Context Files section listing the files an implementer needs to read in full
6. Return the full plan markdown to the caller (do NOT write to disk — Step 5 handles that)

### Run `/peer-draft-plan` Skill

Spawn a subagent whose prompt includes the same shell content, resolved open questions, and pattern survey findings, and instructs it to invoke `/peer-draft-plan` via the Skill tool. The peer draft produces an independent fill-in following the same template.

Wait for both agents to complete before moving to Step 5.

## Step 5: Reconcile and Write Back

Compare the two fill-in drafts along these dimensions:

| Dimension | What to compare |
|---|---|
| **Approach** | Do they propose the same overall strategy, or meaningfully different ones? |
| **Step coverage** | Does one draft include steps the other misses? |
| **Concreteness** | Which draft has more `file_path:line_number` references and named symbols? |
| **Verification** | Which draft's verification section is more specific? |
| **Failure modes** | Does one draft handle edge cases the other ignores? |

Reconcile using these rules:

- **Strong agreement** — Use the better-written of the two as the base. Merge in any unique steps or verification items from the other.
- **Different approaches** — Use `AskUserQuestion` to present both approaches as options with a one-sentence trade-off summary. Let the user pick or ask to merge.
- **One draft is clearly stronger** — Use it as the base and discard the weaker one.
- **One agent failed or returned malformed output** — Use the surviving draft.

Write the reconciled full plan to the shell file path (overwriting the shell content) using this structure:

````markdown
# Plan: <Task Title>

<!-- Decomposed from: <spec path> (prompt <N> of <prompt plan path>) -->

## Context

<Shell Context, preserved verbatim or lightly edited.>

## Pattern Survey

<Insert the structured findings from `/survey-patterns`: Analogous Features, Reusable Utilities, Convention Anchors, Proposed Alignment. Use the same format the survey returned.>

## Implementation Steps

1. **<Step 1 title>**
   - <Concrete action with `file_path:line_number` references>
2. **<Step 2 title>**
   - ...
3. ...

## Verification

- <Specific test command, manual smoke check, or MCP tool invocation>
- <Expected observable result>
- <Edge cases to spot-check>

## Context Files

- `<absolute/path/to/file1>` — <why it matters>
- `<absolute/path/to/file2>` — <why it matters>
````

### Content Rules for the Plan

- **Implementation Steps**: Use concrete `file_path:line_number` references. Reference existing functions and utilities from the Pattern Survey instead of reinventing them. Each step describes a discrete unit of work that can be tracked independently during execution.
- **Verification**: Describe how to know the change actually works. Prefer specific test commands, named test files, or named smoke checks over vague phrases like "run the tests." If the change has no observable behavior, say so explicitly.
- **Context Files**: Curate the minimum set needed to become productive. Do not dump every file touched — only the ones that anchor understanding.
- **Scope**: Plan content describes what to build. Do not include task tracking, skill loading, test commands, or commit instructions — those are execution-wrapper concerns.

## Fill-In Mode Rules

- Never proceed past Step 1 if Consumes verification fails.
