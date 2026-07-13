# Claude Edition

This directory is the Claude Code edition of Turbo. The root [`CLAUDE.md`](../CLAUDE.md) covers project-wide context; this file adds edition-specific rules.

- Keep Claude Code tool vocabulary here: `TaskCreate`, `TaskList`, `AskUserQuestion`, the Skill tool, and Claude Agent tool phrasing are expected in this edition.
- Install/update paths point at `claude/skills/` and `~/.claude/skills/`.
- Claude peer review delegates to Codex. `/peer-review` is the stable abstraction (uses `/codex-exec` with a Turbo-controlled prompt). `/codex-exec` is the raw one-shot helper. `/consult-codex` is the consultation helper. `/codex-review` wraps Codex's built-in `codex review` CLI subcommand and has no Claude analog (Codex CLI exposes a review subcommand; Claude Code does not), so the Codex edition correctly has no `$claude-review` mirror.
- Codex-specific changes belong under [`../codex/`](../codex/), not here.
- When changing a skill, convention, addition, or setup/update/migration file here, mirror the change to the parallel file in [`../codex/`](../codex/). Translate vocabulary via the Harness Vocabulary table in [`../codex/SKILL-CONVENTIONS.md`](../codex/SKILL-CONVENTIONS.md). The two editions track each other behaviorally; vocabulary differs but principles stay aligned. Drift between editions is the most common failure mode.
- After mirroring, run [`/codex-exec`](skills/codex-exec/SKILL.md) to have Codex review the Codex sibling against `../codex/SKILL-CONVENTIONS.md` and `../codex/AGENTS.md`. Independent cross-edition eyes catch vocabulary leaks and behavioral drift the same-edition reviewer cannot see. Treat findings the same as a same-edition review (evaluate, apply).
- **Intentional divergence — loop autonomy:** the Codex edition deliberately runs `$polish-code`/`$refine-plan` without this edition's iteration hard cap and skip/continue `AskUserQuestion` gates, because Codex's `request_user_input` is unreliable in non-interactive modes. Keep the Claude gates as-is; do not strip them to match Codex when mirroring, and do not port Codex's autonomy here.
