# Cross-Skill Composition

How skills depend on, invoke, and fan out to other skills.

## Contents

- Cross-Skill Dependencies
- Explicitly Invoke Skills When the Verb Matches a Skill Name
- Bundle Parallel Fan-Out Inside One Skill, Not Across Siblings

## Cross-Skill Dependencies

When a skill depends on another skill, make it an explicit numbered step. Use "Run `$skill-name` Skill" as the heading and "Run the `$skill-name` skill" in the step body. Including "skill" signals that the agent should read and follow the named skill's SKILL.md before continuing.

```markdown
## Step 1: Run `$<rules-skill>` Skill

Run the `$<rules-skill>` skill to load shared rules and conventions.

## Step 2: Do the Work

- The actual steps of this skill
```

**Style-guide dependencies get their own step, placed late:** When a skill depends on a style-guide skill that loads conventions, give the load its own discrete instruction: a numbered step, or a numbered item in an ordered list. Burying it in a paragraph of prose is what makes it skippable.

Place it before the first step the guide governs, with no work-producing step in between. In a short skill that is Step 1, as in the example above. In a longer one it lands later. Loading at Step 1 anyway can put the load ahead of the values it depends on: a guide that inspects an artifact needs the step that fetches that artifact to have run first, or it silently takes a fallback path. Late placement also skips the load entirely on runs that exit before the governed output is produced. When the governed output lives inside a conditional branch, the load is the first line of that branch.

- ✗ **Avoid**: A six-step skill loads the style guide at Step 1, gathers context through Step 5, then drafts at Step 6.
- ✓ **Good**: The same skill gathers context through Step 4, loads the style guide at Step 5, then drafts at Step 6.

## Explicitly Invoke Skills When the Verb Matches a Skill Name

When a step body uses an action verb that is also the name of an existing skill, the bare verb reads as inline reasoning and the agent skips the actual skill load. Name the skill explicitly so the invocation is unambiguous.

- ✗ **Avoid**: "If a check fails, halt and `<verb>`."
- ✓ **Good**: "If a check fails, run the `$<verb>` skill."

This complements the explicit numbered-step rule above by covering verb collisions inside step bodies.

## Bundle Parallel Fan-Out Inside One Skill, Not Across Siblings

When a workflow needs N parallel reviewers/dimensions/perspectives (e.g., internal review + peer review, or multiple review types in one pass), put the fan-out inside one skill body rather than asking a parent to mention several sibling skills "in parallel". The parent's "load A and B" pattern can't actually parallelize the sibling skills' work, and it leaks the siblings' implementation details into the parent step.

The right shape is a single skill that emits N+1 `spawn_agent` calls and joins them with `wait_agent`. Add an opt-out (e.g., "skip peer review") for runs that want only the internal pass.

- ✗ **Avoid**: Parent skill step says "Run `$<review-skill>` and `$<peer-review-skill>` skills concurrently" and tries to batch two skill mentions.
- ✓ **Good**: `$<review-skill>` internally spawns both internal reviewer sub-agents and a peer reviewer sub-agent; the parent just runs `$<review-skill>`.
