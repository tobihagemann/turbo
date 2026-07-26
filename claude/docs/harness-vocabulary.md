# Harness Vocabulary

When porting a Codex skill into the Claude Code edition, translate Codex terms to Claude Code equivalents:

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

Codex-edition `AGENTS.md` is *not* auto-loaded by Claude Code.

Harness facts for each edition live in `claude/skills/create-skill/references/harness.md` and `codex/skills/create-skill/references/harness.md`.
