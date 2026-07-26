# Harness Reference

Quick reference for the Codex CLI harness: canonical tool names, limits, and discovery paths.

**Tools (canonical names):**

- `update_plan` — task tracking. Each entry is `{step, status}` where status is `pending`, `in_progress`, or `completed`. At most one step in_progress at a time. The `plan` argument is the full list, so every call replaces the previous one. The handler stores nothing: it emits a UI event and returns `"Plan updated"`. No read-back tool exists, so the only record of the current plan is the `update_plan` call sitting in conversation history.
- `apply_patch` — file edits in the V4A diff envelope (`*** Begin Patch` / `*** Add File:` / `*** Update File:` / `*** Delete File:` / `@@` hunks).
- `request_user_input` — structured user prompts. 1-3 questions per call, 2-3 options per question, "Other" free-form option appended automatically. Available in Plan mode by default; Default mode requires the `default_mode_request_user_input` feature flag (currently `Stage::UnderDevelopment`, off by default).
- `spawn_agent` / `wait_agent` / `close_agent` / `resume_agent` / `send_input` — sub-agent control (Codex multi-agents v1). Spawned agents inherit the parent model unless `model` is set explicitly. Codex's v2 surface (`features.multi_agent_v2`, with `send_message` / `followup_task` / `list_agents` for inter-agent messaging) is feature-flagged off and mutually exclusive with `agents.max_threads`.
- `create_goal` / `update_goal` / `get_goal` — persisted thread goals (`[features] goals`, stable and on by default). One unfinished goal per thread; `create_goal` fails while one exists. The objective is re-injected into context every turn from storage, survives compaction and session restarts, and an idle turn with an active goal auto-restarts. `update_goal` accepts only `complete` or `blocked`; `blocked` is valid only after the same blocking condition has recurred for at least three consecutive goal turns, and the goal continuation enforces that threshold itself — skills mark `complete` at their terminal step and otherwise leave the goal active.

**Sub-agent limits:** `agents.max_threads` defaults to 6 (parallel cap). `agents.max_depth` defaults to 1 (a sub-agent cannot itself call `spawn_agent` under defaults).

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
