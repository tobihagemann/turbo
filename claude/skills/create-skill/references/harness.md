# Harness Reference

Quick reference for the Claude Code harness: canonical tool names, limits, and discovery paths.

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

**CLAUDE.md hierarchy:** Auto-loaded from each ancestor of the cwd up through the home directory. Project-root `CLAUDE.md` is the canonical project instruction file; `~/.claude/CLAUDE.md` is the user-global file.

**Hook system:** `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`, and others. Configured under `hooks` in `~/.claude/settings.json` or `.claude/settings.json`.

**Config:** `~/.claude/settings.json` (user) and `.claude/settings.json` (project, with `.local` variants for gitignored overrides).
