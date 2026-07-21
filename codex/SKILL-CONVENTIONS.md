# Codex Skill Conventions

This file holds Turbo conventions for the Codex edition. The Claude Code edition has its own conventions in `claude/SKILL-CONVENTIONS.md`. General skill-authoring principles (applicable to any skill, in any project) live in `codex/skills/create-skill/references/best-practices.md`. When adding guidance, place turbo-specific rules here and general principles there; when a rule fits both, prefer the narrower home.

- Codex `SKILL.md` frontmatter has `name` and `description`; descriptions include trigger phrases.
- Skills should not reference which pipelines call them (stay self-contained).
- Skills stay domain-generic. Session-specific examples belong in project instructions or memory, not in a shared Turbo skill.
- Workflow skills compose child skills by name, but do not inline the child skill's implementation details. The child skill's documented interface is the abstraction boundary.
- Workflow skills use Codex plan tracking (`update_plan` when available) for multi-step execution. Body steps should match plan entries one-to-one when a workflow chains child skills.
- `update_plan` replaces the whole step list on every call, so a skill that calls it with only its own steps erases whatever the plan held before. Child skills restate the remaining steps of a parent workflow alongside their own, keeping the chain in one call — on entry and on the closing call alike, since the closing call is the last chance to erase the parent's steps. This works from the parent's own `update_plan` call in conversation history, so it holds until a compaction drops that call and fails silently afterwards. Treat it as reducing the loss, not preventing it: a workflow whose later steps must survive a long child chain needs those steps written somewhere re-derivable.
- Child skills that return findings should frame their final step as the same Codex agent continuing the active workflow. Avoid "caller", "main agent", "return to", or "hand off" phrasing that encourages an end-of-turn response.
- Child skills invoked by workflow skills should end the final numbered step with: "Then call `update_plan` to mark this step completed and continue with the next step of the active workflow." Reference skills without numbered steps do not need this line. The tool call is a concrete action that breaks the end-of-turn pull, and unlike the Claude edition's `TaskList` there is nothing to read back — an instruction to "check the active plan" resolves to nothing.
- User choice gates should ask the user directly. If a structured user-input tool is available in the current mode, use it for concise option sets.
- Parallel or delegated work uses `spawn_agent` / `wait_agent` with inherited model defaults.
- Codex caps sub-agent fan-out at `agents.max_threads` (Codex default 6, Turbo's `codex/SETUP.md` recommends 16) and nesting at `agents.max_depth` (default 1). A sub-agent cannot itself spawn sub-agents under the default config — when a child skill is invoked via `spawn_agent`, that child must complete its work without further `spawn_agent` calls of its own.
- Do not hardcode Claude model names such as `opus` in Codex skills. If a sub-agent is used, inherit the current model unless the user requested otherwise.
- Skills must not request elevated sandbox or approval modes for routine work. Do not instruct the user to pass `--dangerously-bypass-approvals-and-sandbox` / `--yolo` or set `sandbox_mode = "danger-full-access"`. Read-only and `workspace-write` are sufficient for every Turbo skill at runtime; peer-review and consultation skills explicitly run read-only. Setup, update, and `$contribute-turbo` are exempt because they intentionally write to user-scope paths (`~/.agents/skills`, `~/.turbo/`, `~/.codex/`); their instructions cover the wider scope explicitly.
- When a skill step delegates to another skill inside a Codex sub-agent, say "spawn a Codex sub-agent" and "instruct it to read and follow `$skill-name` from the installed skill directory." Vague phrasing like "spawn a sub-agent to run the `$skill-name` skill" lets the global rule about reading SKILL.md before acting override the sub-agent wrapping, causing the skill to load in the parent agent instead.
- When a skill delegates specialized work to a sub-agent (not another skill), instruct it to read a reference file at `references/<role>.md` for its specialty. This keeps Turbo skills harness-agnostic. Examples: `$create-skill` uses `references/skill-reviewer.md`, `$survey-patterns` uses `references/pattern-surveyor.md`.
- Skills communicate through standard interfaces: git staging area, PR state, and file conventions under `.turbo/`.
- Skills should be context-agnostic: accept context that was passed in but determine their own when called standalone.
- Analysis review skills accept a standardized scope interface: a diff command or a file/directory list. In diff mode, only flag issues introduced by the changeset. In file scope mode, all issues in the reviewed files are in scope.
- Skills should avoid side effects outside their domain. Leave cross-cutting concerns such as staging files to dedicated skills.
- Steps that primarily run a skill use "Run `$skill-name` Skill" for headings and "Run the `$skill-name` skill" in plan entries.
- Run `$create-skill` when creating or editing Codex skills.
- When adding a new Codex skill, update `codex/SKILL-INDEX.md` (add it to the appropriate category table) and update any relevant prose sections in the root README.

## Harness Reference

Quick reference for the Codex CLI harness. The prescriptive rules above derive from these facts; cross-edition porters should read this section before translating a Claude skill into Codex idioms.

**Tools (canonical names):**

- `update_plan` — task tracking. Each entry is `{step, status}` where status is `pending`, `in_progress`, or `completed`. At most one step in_progress at a time. The `plan` argument is the full list, so every call replaces the previous one. The handler stores nothing: it emits a UI event and returns `"Plan updated"`. No read-back tool exists, so the only record of the current plan is the `update_plan` call sitting in conversation history.
- `apply_patch` — file edits in the V4A diff envelope (`*** Begin Patch` / `*** Add File:` / `*** Update File:` / `*** Delete File:` / `@@` hunks).
- `request_user_input` — structured user prompts. 1-3 questions per call, 2-3 options per question, "Other" free-form option appended automatically. Available in Plan mode by default; Default mode requires the `default_mode_request_user_input` feature flag (currently `Stage::UnderDevelopment`, off by default — see `codex/SETUP.md` Step 4).
- `spawn_agent` / `wait_agent` / `close_agent` / `resume_agent` / `send_input` — sub-agent control (Codex multi-agents v1). Spawned agents inherit the parent model unless `model` is set explicitly. Turbo targets v1 only; Codex's v2 surface (`features.multi_agent_v2`, with `send_message` / `followup_task` / `list_agents` for inter-agent messaging) is feature-flagged off and mutually exclusive with `agents.max_threads`, which Turbo's `codex/SETUP.md` Step 5 sets.

**Sub-agent limits:** `agents.max_threads` Codex default is 6 (parallel cap); Turbo's `codex/SETUP.md` recommends raising to 16. `agents.max_depth` defaults to 1 (a sub-agent cannot itself call `spawn_agent` under defaults).

**Sandbox modes:** `read-only`, `workspace-write`, `danger-full-access`. Bypass flag is `--dangerously-bypass-approvals-and-sandbox` (alias `--yolo`).

**Approval policies:** `untrusted`, `on-request`, `never`, `granular`. Default is `on-request`.

**Skill discovery:**

- User-scope: `~/.agents/skills/` (canonical per Codex `core-skills` loader).
- Project-scope: `.agents/skills/` walked from project root down to cwd; closer directories take precedence.
- Admin-scope: `/etc/codex/skills/`.
- Skills invoked as `$skill-name` (slash form also works); `SKILL.md` frontmatter requires `name` and `description`.

**AGENTS.md hierarchy:**

- Global: `~/.codex/AGENTS.md` (with optional `AGENTS.override.md` to replace).
- Project: walked from project root down to cwd. `AGENTS.override.md` at any level *replaces* the `AGENTS.md` at that level (not additive).
- Combined cap: `project_doc_max_bytes` = 32 KiB by default.

**Config:** `~/.codex/config.toml` (user) and `.codex/config.toml` (project).

**Compaction:** several implementations exist — local, remote v1, remote v2 (the shipped default for OpenAI and Azure Responses providers), and a token-budget path that skips summarization entirely — and they differ in what they retain, so depend on none of the details. What holds across all of them: function calls and their output are dropped, so no `update_plan` call survives; skill bodies do not survive either, by a separate filter on injected context; and initial context is re-injected, so `AGENTS.md` comes back. Anything a skill must still know after a compaction has to be re-derivable, not remembered.

## Harness Vocabulary

Use Codex vocabulary in `codex/skills/`:

| Claude Code term | Codex term |
|---|---|
| `TaskCreate`, `TaskUpdate` | `update_plan` (steps with `pending` / `in_progress` / `completed`; one step in_progress at a time) |
| `TaskList` | no equivalent — `update_plan` is write-only |
| `AskUserQuestion` | `request_user_input` (Plan mode by default; Default mode requires the `default_mode_request_user_input` feature flag) |
| `Agent tool` | Codex sub-agent tools (`spawn_agent` / `wait_agent`) when permitted |
| `Skill tool` | read/invoke the installed skill instructions |
| `Edit` / `Write` | `apply_patch` (V4A diff envelope) |
| `~/.claude/skills` | `~/.agents/skills` |
| `CLAUDE.md` | `AGENTS.md` for Codex-facing project instructions |
| `/skill-name` invocation | `$skill-name` invocation |
