# Workflows and Common Patterns

How to shape multi-step skills, convergence loops, exit signals, and recurring output patterns.

## Contents

- Use Workflows for Complex Tasks
- Implement Feedback Loops
- Use Recursive Self-Invocation for Convergence Loops
- Use Neutral Exit Signals So Parent Pipelines Can Continue
- Template Pattern
- Examples Pattern
- Conditional Workflow Pattern
- Align Output Formats Across Parallel Producers

## Use Workflows for Complex Tasks

Break complex operations into clear, sequential steps. Use `## Step N:` headings for the steps. For particularly complex workflows with distinct phases, nest steps under phases using `## Phase N` with `### Step N:` subheadings.

**Simple workflow:**

```markdown
## Step 1: Analyze Input
...
## Step 2: Transform Data
...
## Step 3: Validate Output
...
```

**Complex multi-phase workflow:**

```markdown
## Phase 1: Planning

### Step 1: Gather Requirements
...
### Step 2: Design Solution
...

## Phase 2: Execution

### Step 1: Implement Changes
...
### Step 2: Run Tests
...
```

**Avoid** wrapper sections like `## Process` with `### 1.` numbered subsections. Steps should be top-level, not nested under a generic heading.

**Avoid** any section whose only purpose is to inspect input or detect a mode, regardless of what it is labeled. This includes numbered "Step 0" headings, unnumbered `## Mode Selection` sections, or any subheading that collapses to "if X, read file A; otherwise read file B." A step or section should do work the agent executes. Trivial input inspection and mode routing are one-line branches — fold them into the skill's opening prose rather than giving them their own heading.

For particularly complex workflows, provide a checklist that the agent can copy into its response and check off as it progresses. The pattern works for any multi-step process — code-based or analysis-only. Clear steps prevent the agent from skipping critical validation, and the checklist helps both the agent and you track progress.

````markdown
Copy this checklist and check off items as you complete them:

```
Task Progress:
- [ ] Step 1: <action>
- [ ] Step 2: <action>
- [ ] Step 3: <validation>
```
````

## Implement Feedback Loops

**Common pattern**: Run validator → fix errors → repeat. The validator can be a script, a reference document, or a checklist — what matters is the loop.

State the loop so the agent cannot advance past a failure: make the edit, validate immediately, review the error and fix on failure, re-validate, and only proceed once validation passes.

## Use Recursive Self-Invocation for Convergence Loops

When a skill needs to repeat its workflow until stable (e.g., simplify → review → test → repeat if changed), have the last step re-invoke the skill itself rather than encoding an internal loop. This keeps each step distinct and the flow linear. Use "skipping Step N" to bypass one-time setup steps on re-runs.

```markdown
## Step 1: Setup (first run only)
...
## Step 2: Do work
...
## Step 3: Re-run if changed

If any prior step produced changes, run the `$this-skill` skill again, skipping Step 1.

## Rules

- The loop ends when a run makes no changes. Rely on that convergence signal rather than a fixed iteration cap.
- Only defects justify a re-run. When a round stops surfacing defects and keeps surfacing improvements of kinds earlier rounds already applied, the loop has converged; a clean round is the termination signal, never grounds for a confirmation round.
```

## Use Neutral Exit Signals So Parent Pipelines Can Continue

When a skill detects a clean early-exit case (a degenerate input that doesn't warrant the full output), the exit instructions need to allow parent pipelines to detect and reroute. Phrasing like "Halt and tell the user X" reads as a hard stop and terminates the agent's flow, including any parent pipeline that called the skill.

Phrasing like "Present this message: <factual summary>. Then call `update_plan` to mark this step completed and continue with the next step of the active workflow." lets the agent surface what happened and continue to whatever task is next. The signal that the early-exit fired lives in the side effects (no file written, factual message shown), and the parent pipeline reads them via filesystem checks or remaining-step detection.

Blocker gates (covered in [tools.md](tools.md) under "Using request_user_input") handle a different case: when the agent needs the user to choose between recoveries. Use neutral exit signals when the work simply terminates earlier than the full path.

- ✗ **Avoid**: "Halt and tell the user 'no shells produced — run `$draft-plan` instead.'"
- ✓ **Good**: "Present this message: '<factual summary>'. Then call `update_plan` to mark this step completed and continue with the next step of the active workflow."

## Template Pattern

Provide templates for output format. Match the level of strictness to your needs — open with "ALWAYS use this exact template" for strict requirements (API responses, data formats), or "Here is a sensible default; use your best judgment" when adaptation is useful.

Give the template as a fenced block with bracketed slots naming what goes in each one, so the structure is unambiguous and the agent fills rather than invents.

## Examples Pattern

For Skills where output quality depends on seeing examples, provide input/output pairs just like in regular prompting. Two or three pairs showing input and desired output, followed by a one-line statement of the rule the pairs demonstrate, convey style and level of detail more precisely than description alone.

Reserve this pattern for cases where the output has a house style that description genuinely fails to pin down. When the rule can be stated directly, state it — examples narrow the space the agent explores, so they cost more than their line count suggests.

## Conditional Workflow Pattern

Guide the agent through decision points. Open the step with the discriminating question, then give each branch its own labeled sequence:

```markdown
1. Determine the modification type:

   **Creating new content?** → Follow "Creation workflow" below
   **Editing existing content?** → Follow "Editing workflow" below

2. Creation workflow:
   - <steps>

3. Editing workflow:
   - <steps>
```

> **Tip:** If workflows become large or complicated with many steps, consider pushing them into separate files and tell the agent to read the appropriate file based on the task at hand.

## Align Output Formats Across Parallel Producers

When two or more skills produce findings that feed a shared downstream pipeline (for example, an evaluation or triage skill), align their default output formats so the consumer can concatenate findings without transforming them. Drift in finding shape (different metadata labels, missing source attribution, divergent priority scales) forces the consumer to reformat, which invites bugs and defeats composition.

- **Match field names** — if one producer emits `**File:** <path> (lines <start>-<end>)`, the other's default should use the same label and slot, even if the line-range slot is optional for some inputs.
- **Include source attribution** — when findings from multiple producers merge, each should carry a `**Reviewer:**` (or equivalent) line so the consumer can distinguish them.
- **Share the priority scale** — use the same labels and semantics (e.g., P0–P3) across producers so the downstream can rank findings uniformly.
- **Let the invoking skill override the default** — alignment applies to the producer's *default* format. A specific invocation can still pass a tailored output format when it needs extra fields.
