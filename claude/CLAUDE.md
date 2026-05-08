# Claude Edition

This directory is the Claude Code edition of Turbo. The root [`CLAUDE.md`](../CLAUDE.md) covers project-wide context; this file adds edition-specific rules.

- Keep Claude Code tool vocabulary here: `TaskCreate`, `TaskList`, `AskUserQuestion`, the Skill tool, and Claude Agent tool phrasing are expected in this edition.
- Install/update paths point at `claude/skills/` and `~/.claude/skills/`.
- Claude peer review delegates to Codex. `/peer-review` is the stable abstraction (uses `/codex-exec` with a Turbo-controlled prompt). `/codex-exec` is the raw one-shot helper. `/consult-codex` is the consultation helper. `/codex-review` wraps Codex's built-in `codex review` CLI subcommand and has no Claude analog (Codex CLI exposes a review subcommand; Claude Code does not), so the Codex edition correctly has no `$claude-review` mirror.
- Codex-specific changes belong under [`../codex/`](../codex/), not here.
- When changing a skill, convention, addition, or setup/update/migration file here, check whether the parallel file in [`../codex/`](../codex/) needs the same change. The two editions track each other behaviorally; vocabulary differs but principles stay aligned. Drift between editions is the most common failure mode.
