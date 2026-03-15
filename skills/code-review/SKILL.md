---
name: code-review
description: "Analyzes a diff for bugs, security issues, and correctness problems using strict determination criteria. Returns structured findings without applying fixes. Use when the user asks to \"scan my code for bugs\", \"find issues in my changes\", \"analyze my diff\", \"check for security issues\", or \"run a code review analysis\"."
---

# Code Review

Analyze code changes for bugs, security issues, and correctness problems. Return structured findings.

## Step 1: Determine the Diff Target

Determine what to review based on context:

- **Uncommitted changes**: `--uncommitted`
- **Against a base branch**: `--base <branch>`
- **Specific commit**: `--commit <sha>`

Default to reviewing against the repository's default branch (detect via `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`). If the caller specifies a different target, use that.

## Step 2: Review Changes

1. Run the appropriate diff command to obtain the changes
2. For each changed file, read enough surrounding context to understand the change
3. Apply the bug determination criteria and return findings in the output format below

## Bug Determination Criteria

Flag an issue only when ALL of these hold:

1. It meaningfully impacts the accuracy, performance, security, or maintainability of the code
2. The bug is discrete and actionable (not a general codebase issue or combination of multiple issues)
3. Fixing it does not demand rigor beyond what exists in the rest of the codebase
4. The bug was introduced in the changeset (do not flag pre-existing bugs)
5. The author would likely fix the issue if aware of it
6. The bug does not rely on unstated assumptions about the codebase or author's intent
7. Speculation is insufficient — identify the parts of the code that are provably affected
8. The issue is clearly not an intentional change by the original author

## Comment Standards

1. Be clear about why the issue is a bug
2. Communicate severity accurately — do not overstate
3. Keep the body to one paragraph maximum
4. No code chunks longer than 3 lines. Use markdown inline code or code blocks
5. Explicitly communicate the scenarios, environments, or inputs needed for the bug to arise
6. Use a matter-of-fact tone, not accusatory or overly positive
7. Write so the author can immediately grasp the idea without close reading
8. No flattery ("Great job...", "Thanks for...")

## Priority Levels

- **P0** — Drop everything. Blocking release or operations. Only for universal issues that do not depend on assumptions about inputs
- **P1** — Urgent. Should be addressed in the next cycle
- **P2** — Normal. To be fixed eventually
- **P3** — Low. Nice to have

## What to Ignore

- Trivial style unless it obscures meaning or violates documented standards
- Pre-existing issues not introduced by this changeset

## Output Format

Return findings as a numbered list. For each finding:

```
### [P<N>] <title (imperative, ≤80 chars)>

**File:** `<file path>` (lines <start>-<end>)

<one paragraph explaining why this is a bug, what scenarios trigger it, and the impact>
```

After all findings, add:

```
## Overall Verdict

**Correctness:** <correct | incorrect>

<1-3 sentence explanation>
```

If there are no qualifying findings, state that the code looks correct and explain briefly.
