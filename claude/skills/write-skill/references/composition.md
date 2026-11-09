# Cross-Skill Composition

How skills depend on, invoke, and fan out to other skills.

## Contents

- Cross-Skill Dependencies
- Explicitly Invoke Skills When the Verb Matches a Skill Name
- Keep One Concern's Fan-Out Inside One Skill

## Cross-Skill Dependencies

When a skill depends on another skill, make it an explicit numbered step. Use "Run `/skill-name` Skill" as the heading and "Run the `/skill-name` skill" in the step body. Including "skill" signals to invoke via the Skill tool rather than treating it as a general reference.

```markdown
## Step 1: Run `/<rules-skill>` Skill

Run the `/<rules-skill>` skill to load shared rules and conventions.

## Step 2: Do the Work

- The actual steps of this skill
```

**Style-guide dependencies get their own step, placed late:** When a skill depends on a style-guide skill that loads conventions, give the load its own discrete instruction: a numbered step, or a numbered item in an ordered list. Burying it in a paragraph of prose is what makes it skippable.

Place it before the first step the guide governs, with no work-producing step in between. In a short skill that is Step 1, as in the example above. In a longer one it lands later. Loading at Step 1 anyway can put the load ahead of the values it depends on: a guide that inspects an artifact needs the step that fetches that artifact to have run first, or it silently takes a fallback path. Late placement also skips the load entirely on runs that exit before the governed output is produced. When the governed output lives inside a conditional branch, the load is the first line of that branch.

- ✗ **Avoid**: A six-step skill loads the style guide at Step 1, gathers context through Step 5, then drafts at Step 6.
- ✓ **Good**: The same skill gathers context through Step 4, loads the style guide at Step 5, then drafts at Step 6.

Late placement has a floor: the load still precedes any step whose condition the guide defines. A step that tests for the presence, location, or shape of something the guide specifies is governed by that guide even though it produces no output of its own. Run it first and it resolves against a default the guide would have overridden, so the skill exits as a silent no-op on exactly the projects that customized that detail. Moving a cheap check ahead of an expensive load is safe only when the check's subject is fixed independently of what the guide defines.

- ✗ **Avoid**: A skill checks whether the target artifact exists, exits when it does not, and loads the style guide that defines where that artifact lives afterward.
- ✓ **Good**: The same skill loads the style guide first, then applies the existence check to the location the guide resolves.

## Explicitly Invoke Skills When the Verb Matches a Skill Name

When a step body uses an action verb that is also the name of an existing skill, the bare verb reads as inline reasoning and the agent skips the actual Skill tool call. Name the skill explicitly so the invocation is unambiguous.

- ✗ **Avoid**: "If a check fails, halt and `<verb>`."
- ✓ **Good**: "If a check fails, run the `/<verb>` skill."

This complements the explicit numbered-step rule above by covering verb collisions inside step bodies.

## Keep One Concern's Fan-Out Inside One Skill

When a workflow needs N parallel reviewers/dimensions/perspectives (e.g., internal review + peer review, or multiple review types in one pass), put the fan-out inside one skill body rather than splitting it across sibling skills that a parent loads "in parallel" via the Skill tool. Splitting one fan-out across siblings leaks their implementation details into the parent step.

The right shape is a single skill that emits N+1 Agent tool calls in one message. Add an opt-out (e.g., "skip peer review") for runs that want only the internal pass.

- ✗ **Avoid**: Parent skill Step says "Run `/<review-skill>` and `/<peer-review-skill>` skills concurrently", leaving neither sibling able to cover the concern alone.
- ✓ **Good**: `/<review-skill>` internally launches both internal reviewer Agents and a peer reviewer Agent in one message; the parent just calls `/<review-skill>`.

A parent may batch Skill calls when each sibling already fans out on its own and covers a distinct concern. A Skill call only loads instructions into the current context, so batching two lands both bodies in the same agent, which then emits every sibling's Agent call in one message. Keep such a parent to the scope it resolves and the ordering it imposes, and leave each sibling's criteria in the sibling.

- ✓ **Good**: `/<combined-skill>` batches the Skill calls for `/<code-skill>` and `/<docs-skill>`, launches every agent both define in one message, then applies a single round of fixes.
