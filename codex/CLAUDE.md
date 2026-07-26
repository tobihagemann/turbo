# Codex Edition (Cross-Edition Lookup)

You are working in the Codex edition tree. The default Codex instructions in this directory live in [`AGENTS.md`](AGENTS.md), which Claude Code does not auto-load. Read it before editing.

## Read Before Editing

- [`AGENTS.md`](AGENTS.md) — Codex edition rules and overlay
- [`SKILL-CONVENTIONS.md`](SKILL-CONVENTIONS.md) — Codex skill conventions
- [`skills/create-skill/references/harness.md`](skills/create-skill/references/harness.md) — harness facts: tool names, sandbox and approval modes, sub-agent limits, skill and AGENTS.md hierarchies
- [`docs/harness-vocabulary.md`](docs/harness-vocabulary.md) — table translating Claude Code terms into Codex equivalents
- [`ADDITIONS.md`](ADDITIONS.md) — Codex-specific user instructions

## Vocabulary

Use Codex vocabulary in `codex/skills/`: `update_plan` instead of `TaskCreate`, `apply_patch` instead of Edit, `~/.agents/skills` instead of `~/.claude/skills`, `AGENTS.md` instead of `CLAUDE.md`, `$skill-name` invocation form. The full mapping is in [`docs/harness-vocabulary.md`](docs/harness-vocabulary.md). Do not introduce Claude Code primitives here.

## Cross-Edition Sync

When changing a skill, convention, addition, or setup/update/migration file here, check whether the parallel file in [`../claude/`](../claude/) needs the same change. The two editions track each other behaviorally; vocabulary differs but principles stay aligned. Drift between editions is the most common failure mode.
