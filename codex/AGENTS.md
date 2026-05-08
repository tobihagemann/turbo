# Codex Edition

This directory is the Codex edition of Turbo. The root [`AGENTS.md`](../AGENTS.md) covers project-wide context; this file adds edition-specific rules.

- Read [`SKILL-CONVENTIONS.md`](SKILL-CONVENTIONS.md) before editing any skill or doc in this tree — it has the prescriptive rules and the harness reference.
- Use Codex-native vocabulary and tool contracts. Do not introduce Claude Code control primitives such as `TaskCreate`, `TaskList`, `AskUserQuestion`, or Claude Agent tool instructions except inside explicit mapping docs.
- Install/update paths point at `codex/skills/` (source) and `~/.agents/skills/` (user-scope install location per Codex's `core-skills` loader).
- `$peer-review` is the stable abstraction; in this edition it delegates to Claude through `$claude-print`.
- Claude-specific changes belong under [`../claude/`](../claude/), not here.
- When changing a skill, convention, addition, or setup/update/migration file here, check whether the parallel file in [`../claude/`](../claude/) needs the same change. The two editions track each other behaviorally; vocabulary differs but principles stay aligned. Drift between editions is the most common failure mode.
