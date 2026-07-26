# Claude Edition (Cross-Edition Lookup)

You are working in the Claude Code edition tree. The default Claude Code instructions in this directory live in [`CLAUDE.md`](CLAUDE.md), which Codex does not auto-load. Read it before editing.

## Read Before Editing

- [`CLAUDE.md`](CLAUDE.md) — Claude edition rules and overlay
- [`SKILL-CONVENTIONS.md`](SKILL-CONVENTIONS.md) — Claude skill conventions
- [`skills/create-skill/references/harness.md`](skills/create-skill/references/harness.md) — harness facts: tool names, permission modes, skill and CLAUDE.md hierarchies
- [`docs/harness-vocabulary.md`](docs/harness-vocabulary.md) — table translating Codex terms into Claude Code equivalents
- [`ADDITIONS.md`](ADDITIONS.md) — Claude-specific user instructions

## Vocabulary

Use Claude Code vocabulary in `claude/skills/`: `TaskCreate` / `TaskList` for plan tracking, `AskUserQuestion` for user gates, the Skill tool for invoking skills, `~/.claude/skills` for the install path, `CLAUDE.md` for project instructions. The full Codex→Claude mapping is in [`docs/harness-vocabulary.md`](docs/harness-vocabulary.md). Do not introduce Codex primitives here.

## Cross-Edition Sync

When changing a skill, convention, addition, or setup/update/migration file here, check whether the parallel file in [`../codex/`](../codex/) needs the same change. The two editions track each other behaviorally; vocabulary differs but principles stay aligned. Drift between editions is the most common failure mode.
