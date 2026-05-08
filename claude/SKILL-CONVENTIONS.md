## Skill Conventions

This file holds Turbo conventions for the Claude Code edition. Codex-specific conventions live at `codex/SKILL-CONVENTIONS.md`. General Claude Code skill-authoring principles (applicable to any skill, in any project) live in `claude/skills/create-skill/references/best-practices.md`. When adding guidance, place turbo-specific rules here and general principles there; when a rule fits both, prefer the narrower home.

- SKILL.md frontmatter has `name` and `description` — description includes trigger phrases
- Skills should not reference which pipelines call them (stay self-contained)
- Turbo skills must stay domain-generic. When encoding a lesson extracted from a specific task, drop all examples tied to that context (file formats, project names, domain concepts) and state the principle alone. Concrete originating examples belong in auto memory or project docs, not in a skill that ships to every Turbo user.
- Workflow skills should not embed implementation details of delegated skills — including downstream CLI commands, tool-specific flags, model coupling in reference materials, or enumerations of the delegate's internal step sequence ("X loads A, executes B, runs C"). The skill interface is the abstraction boundary. Step-sequence leaks let the agent treat the enumeration as instructions and skip the Skill tool call. When extracting inline logic into a new child skill, delete the explanatory prose from the parent rather than migrating it.
- Workflow skills use `TaskCreate` for phase tracking. Skills that chain multiple skill invocations sequentially must have a `## Task Tracking` section covering the full workflow. Each loaded skill displaces the parent's continuation context; without a persistent task list, the agent loses track of remaining steps.
- Child skills that return findings should frame the body — intros, scope descriptions, and the final step — as the same agent continuing through more prompting. Second-person, agent-facing voice crowds out the end-of-turn pull; the last step names a concrete next action (e.g., "Then use the TaskList tool and proceed to any remaining task."). Third-party framing like "caller", "main agent", "return to", or "hand off" reads as an end-of-turn signal and strands the parent workflow's remaining steps. This is the "stop" problem, distinct from the "skip" problem that task tracking and anti-skip rules address. Stalls also appear to cascade within a session: once the agent has stopped at one skill boundary, it tends to stop at the next one too, so continuation framing at the earliest leaf skill in a chain tends to prevent stalls downstream. See `claude/skills/create-skill/references/best-practices.md` "Avoid 'caller' phrasing".
- Skills invoked as children by workflow skills with task tracking must end their last step with: "Then use the TaskList tool and proceed to any remaining task." Place this line at the end of the last numbered step's content, before any Rules or reference sections. Reference/principle skills without numbered steps (e.g., style guides like `/github-voice`, `/code-style`, `/frontend-design`) do not need this line — they have no "last step" to terminate. This is a mitigation for the stop problem (see anthropics/claude-code#17351): the agent treats child skill completion as a turn boundary and stops instead of continuing the parent workflow. The TaskList tool call is a required concrete action that breaks the end-of-turn pull more reliably than prose. When no parent workflow is active, the empty list naturally yields nothing to proceed to.
- Body steps should match task tracking entries one-to-one. If task tracking lists three skill invocations as separate entries, the body must have three numbered steps, not one bundled step with sub-bullets. Bundling skill invocations under a single step contradicts the rationale for task tracking (each skill load displaces continuation context) and causes the agent to lose progress between loads.
- When a skill step delegates to another skill inside a subagent, say "Agent tool call" (not "agent") and "instructs it to invoke `/skill-name` via the Skill tool." Vague phrasing like "spawn a subagent to run the `/skill-name` skill" lets the global "always use the Skill tool" rule override the subagent wrapping, causing the skill to load in the main conversation instead.
- When a skill delegates specialized work to a subagent (not another skill), launch a generic subagent (`model: "opus"`, no `subagent_type`) and instruct it to read a reference file at `references/<role>.md` for its specialty. This keeps Turbo independent of Claude Code's built-in subagent types (`Explore`, `Plan`, etc.). Examples: `/create-skill` uses `references/skill-reviewer.md`, `/survey-patterns` uses `references/pattern-surveyor.md`.
- Skills communicate through standard interfaces: git staging area, PR state, file conventions at `.turbo/`
- Skills should be context-agnostic: accept context that was passed in but determine their own when called standalone (from conversation context or git state). See `/simplify-code` as the model.
- Analysis review skills accept a standardized scope interface: a diff command OR a file/directory list. In diff mode, only flag issues introduced by the changeset. In file scope mode, all issues in the reviewed files are in scope.
- Skills should avoid side effects outside their domain. Leave cross-cutting concerns (e.g., staging files) to a dedicated skill.
- Steps that primarily run a skill use "Run `/skill-name` Skill" for headings and "Run `/skill-name` skill" for task tracking items. Steps with their own logic use human-readable names (e.g., "Deterministic Cleanup", "Ship It").
- Run `/create-skill` when creating or editing skills
- When adding a new skill, update `claude/SKILL-INDEX.md` (add it to the appropriate category table) and update any relevant prose sections in README.md

## Harness Reference

Quick reference for the Claude Code harness. The prescriptive rules above derive from these facts; cross-edition porters should read this section before translating a Codex skill into Claude Code idioms.

**Tools (canonical names):**

- `TaskCreate` / `TaskUpdate` / `TaskList` / `TaskGet` — task tracking. Statuses: `pending`, `in_progress`, `completed`, plus `deleted` for removal. Tasks support `owner`, `blocks` / `blockedBy`, and arbitrary `metadata`.
- `AskUserQuestion` — structured user prompts with option lists.
- `Edit` / `Write` / `Read` / `NotebookEdit` — file operations. `Edit` requires the file to be read first.
- `Bash` — shell execution; supports `run_in_background` for long-running commands.
- `Skill tool` — invoke an installed skill by name.
- `Agent tool` — spawn a sub-agent. The `subagent_type` field selects a specialized agent (built-ins include `Explore`, `Plan`, `general-purpose`, plus user-defined types). Generic sub-agents accept a `model` override.

**Sub-agents:** No documented hard cap on count or nesting; pragmatic limits are whatever the parent context can manage. Sub-agents inherit the parent model unless `model` is specified. Specialized agents have restricted tool subsets defined per agent type.

**Permission modes:** `default`, `acceptEdits`, `plan`, `bypassPermissions`, `dontAsk`. Set via `--permission-mode`, `/permissions`, or per-tool allow-lists. `plan` mode blocks writes until plan approval.

**Skill discovery:**

- User-scope: `~/.claude/skills/`.
- Project-scope: `.claude/skills/` (cwd).
- Skills invoked as `/skill-name`; `SKILL.md` frontmatter requires `name` and `description`.

**CLAUDE.md hierarchy:** Auto-loaded from each ancestor of the cwd up through the home directory. Project-root `CLAUDE.md` is the canonical project instruction file; `~/.claude/CLAUDE.md` is the user-global file. Codex-edition `AGENTS.md` is *not* auto-loaded by Claude Code.

**Hook system:** `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`, and others. Configured under `hooks` in `~/.claude/settings.json` or `.claude/settings.json`.

**Config:** `~/.claude/settings.json` (user) and `.claude/settings.json` (project, with `.local` variants for gitignored overrides).

## Harness Vocabulary

When porting a Codex skill into this edition, translate Codex terms to Claude Code equivalents:

| Codex term | Claude Code term |
|---|---|
| `update_plan` (steps with `pending` / `in_progress` / `completed`) | `TaskCreate`, `TaskUpdate`, `TaskList` |
| `request_user_input` (Plan mode by default; Default mode requires the `default_mode_request_user_input` feature flag) | `AskUserQuestion` |
| `spawn_agent` / `wait_agent` | Agent tool (with optional `subagent_type`) |
| read/invoke installed skill instructions | Skill tool |
| `apply_patch` (V4A diff envelope) | `Edit` / `Write` |
| `~/.agents/skills` | `~/.claude/skills` |
| `AGENTS.md` (Codex project instructions) | `CLAUDE.md` |
| `$skill-name` invocation | `/skill-name` invocation |
