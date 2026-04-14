---
name: review-plan
description: "Review a planning artifact (plan, shells, or spec) against type-specific criteria and return structured findings. Use when the user asks to \"review my plan\", \"review my shells\", \"review my spec\", \"check my plan\", \"check my shells\", \"check my spec\", \"critique my plan\", \"critique my shells\", \"critique my spec\", or wants feedback on a planning artifact."
---

# Review Plan

Review a planning artifact against type-specific criteria. Return structured findings.

## Step 1: Determine Artifact Type and Resolve

### Determine Artifact Type

1. **Explicit argument** — If the user specified a type (e.g., "review shells", "review spec"), use it. No argument defaults to **plan**.
2. **Conversation context** — If artifact text or a path is already in context, infer the type.
3. **Auto-detect** — Check `.turbo/` for existing artifacts. If multiple types exist, use `AskUserQuestion`.

### Resolve the Artifact

#### Plan (default)

1. **Plan text in conversation** — use it
2. **Explicit path** — read it
3. **Explicit slug** — resolve to `.turbo/plans/<slug>.md`
4. **Single file** — Glob `.turbo/plans/*.md`. If exactly one file exists, use it
5. **Most recent** — most recently modified file
6. **Legacy fallback** — `.turbo/plan.md` if `.turbo/plans/` does not exist
7. **Nothing found** — use `AskUserQuestion` to ask what to review

#### Shells

1. **Shell text in conversation** — use it
2. **Explicit spec slug** — Glob `.turbo/shells/<slug>-*.md`
3. **Explicit spec path** — derive slug from filename, glob as above
4. **Single spec** — Glob `.turbo/specs/*.md`. If exactly one, derive slug and glob for shells
5. **Most recent spec** — most recently modified spec, derive slug and glob
6. **Nothing found** — use `AskUserQuestion` to ask what to review

For shells, read each shell file and parse its YAML frontmatter (`spec`, `depends_on`). Read the source spec from the `spec` field.

#### Spec

1. **Spec text in conversation** — use it
2. **Explicit path** — read it
3. **Explicit slug** — resolve to `.turbo/specs/<slug>.md`
4. **Single file** — Glob `.turbo/specs/*.md`. If exactly one, use it
5. **Most recent** — most recently modified
6. **Legacy fallback** — `.turbo/spec.md` if `.turbo/specs/` does not exist
7. **Nothing found** — use `AskUserQuestion` to ask what to review

If multiple candidates exist and the choice is non-obvious, use `AskUserQuestion`.

## Step 2: Review

Read the reference file for the resolved type:

- **Plan** — [references/plan-review.md](references/plan-review.md)
- **Shells** — [references/shells-review.md](references/shells-review.md)
- **Spec** — [references/spec-review.md](references/spec-review.md)

Launch an Agent tool call (`model: "opus"`, do not set `run_in_background`) with the artifact text and one reference file's content. Read project context (CLAUDE.md, relevant codebase files) before applying criteria. Exception: shells review focuses on structural wiring, not codebase patterns.

Return findings in the output format below.

Check your task list for remaining tasks and proceed.

## Output Format

Return findings as a numbered list. For each finding:

```
### [P<N>] <title (imperative, ≤80 chars)>

**<Location>:** <plan section, shell number(s), or spec section>

<one paragraph explaining the issue and its impact>
```

After all findings, add:

```
## Overall Verdict

**Readiness:** <ready | needs revision>

<1-3 sentence assessment>
```

If there are no qualifying findings, state so and explain briefly.

## Rules

- Present findings grouped by priority.
