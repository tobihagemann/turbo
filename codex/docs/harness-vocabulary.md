# Harness Vocabulary

When porting a Claude Code skill into the Codex edition, translate Claude Code terms to Codex equivalents:

| Claude Code term | Codex term |
|---|---|
| `TaskCreate`, `TaskUpdate` | `update_plan` (steps with `pending` / `in_progress` / `completed`; one step in_progress at a time) |
| `TaskList` | no equivalent — `update_plan` is write-only |
| `AskUserQuestion` | `request_user_input` (Plan mode by default; Default mode requires the `default_mode_request_user_input` feature flag — see `codex/SETUP.md` Step 4) |
| `Agent tool` | Codex sub-agent tools (`spawn_agent` / `wait_agent`) when permitted |
| `Skill tool` | read/invoke the installed skill instructions |
| `Edit` / `Write` | `apply_patch` (V4A diff envelope) |
| `~/.claude/skills` | `~/.agents/skills` |
| `CLAUDE.md` | `AGENTS.md` for Codex-facing project instructions |
| `/skill-name` invocation | `$skill-name` invocation |

Turbo targets Codex multi-agents v1 only, and `codex/SETUP.md` Step 5 sets `agents.max_threads` (recommended 16, Codex default 6).

Harness facts for each edition live in `codex/skills/create-skill/references/harness.md` and `claude/skills/create-skill/references/harness.md`.
