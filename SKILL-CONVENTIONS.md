## Skill Conventions

- SKILL.md frontmatter has `name` and `description` — description includes trigger phrases
- Skills should not reference which pipelines call them (stay self-contained)
- Workflow skills should not embed implementation details of delegated skills (downstream CLI commands, tool-specific flags, model coupling in reference materials). The skill interface is the abstraction boundary.
- Workflow skills use `TaskCreate` for phase tracking. Skills that chain multiple skill invocations sequentially must have a `## Task Tracking` section covering the full workflow. Each loaded skill displaces the parent's continuation context; without a persistent task list, the agent loses track of remaining steps.
- Body steps should match task tracking entries one-to-one. If task tracking lists three skill invocations as separate entries, the body must have three numbered steps, not one bundled step with sub-bullets. Bundling skill invocations under a single step contradicts the rationale for task tracking (each skill load displaces continuation context) and causes the agent to lose progress between loads.
- When a skill step delegates to another skill inside a subagent, say "Agent tool call" (not "agent") and "instructs it to invoke `/skill-name` via the Skill tool." Vague phrasing like "spawn a subagent to run the `/skill-name` skill" lets the global "always use the Skill tool" rule override the subagent wrapping, causing the skill to load in the main conversation instead.
- When a skill delegates specialized work to a subagent (not another skill), launch a generic subagent (`model: "opus"`, no `subagent_type`) and instruct it to read a reference file at `references/<role>.md` for its specialty. This keeps Turbo independent of Claude Code's built-in subagent types (`Explore`, `Plan`, etc.). Examples: `/create-skill` uses `references/skill-reviewer.md`, `/survey-patterns` uses `references/pattern-surveyor.md`.
- Skills communicate through standard interfaces: git staging area, PR state, file conventions at `.turbo/`
- Skills should be context-agnostic: accept caller-specified context but determine their own when called standalone (from conversation context or git state). See `/simplify-code` as the model.
- Analysis review skills accept a standardized scope interface: a diff command OR a file/directory list. In diff mode, only flag issues introduced by the changeset. In file scope mode, all issues in the reviewed files are in scope.
- Skills should avoid side effects outside their domain. Let the caller or a dedicated skill handle cross-cutting concerns (e.g., staging files).
- Steps that primarily run a skill use "Run `/skill-name` Skill" for headings and "Run `/skill-name` skill" for task tracking items. Steps with their own logic use human-readable names (e.g., "Deterministic Cleanup", "Ship It").
- Run `/create-skill` when creating or editing skills
- When adding a new skill, update README.md: add it to the appropriate table in "All Skills" and update any relevant prose sections
