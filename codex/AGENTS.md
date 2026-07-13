# Codex Edition

This directory is the Codex edition of Turbo. The root [`AGENTS.md`](../AGENTS.md) covers project-wide context; this file adds edition-specific rules.

- Read [`SKILL-CONVENTIONS.md`](SKILL-CONVENTIONS.md) before editing any skill or doc in this tree — it has the prescriptive rules and the harness reference.
- Use Codex-native vocabulary and tool contracts. Do not introduce Claude Code control primitives such as `TaskCreate`, `TaskList`, `AskUserQuestion`, or Claude Agent tool instructions except inside explicit mapping docs.
- Install/update paths point at `codex/skills/` (source) and `~/.agents/skills/` (user-scope install location per Codex's `core-skills` loader).
- `$peer-review` is the stable abstraction; in this edition it delegates to Claude through `$claude-print`.
- Claude-specific changes belong under [`../claude/`](../claude/), not here.
- When changing a skill, convention, addition, or setup/update/migration file here, mirror the change to the parallel file in [`../claude/`](../claude/). Translate vocabulary via the Harness Vocabulary table in [`../claude/SKILL-CONVENTIONS.md`](../claude/SKILL-CONVENTIONS.md). The two editions track each other behaviorally; vocabulary differs but principles stay aligned. Drift between editions is the most common failure mode.
- After mirroring, run [`$claude-print`](skills/claude-print/SKILL.md) to have Claude review the Claude sibling against `../claude/SKILL-CONVENTIONS.md` and `../claude/CLAUDE.md`. Independent cross-edition eyes catch vocabulary leaks and behavioral drift the same-edition reviewer cannot see. Treat findings the same as a same-edition review (evaluate, apply).
- **Intentional divergence — loop autonomy:** `$polish-code` and `$refine-plan` run their re-run loops to natural convergence, without the iteration hard cap or the skip/continue `request_user_input` gates the Claude edition keeps; `skills/create-skill/references/best-practices.md` teaches the autonomous form to match. This is deliberate — `request_user_input` does not reliably reach the user in Codex's non-interactive modes, so these loops rely on their own convergence signal instead. Do not "resync" them to the capped/gated Claude form when mirroring.
