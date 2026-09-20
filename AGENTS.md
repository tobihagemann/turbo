# Turbo

Turbo is a modular collection of agentic coding skills with sibling editions for Claude Code and Codex. Skills connect into larger pipelines like `$finalize` and `$review-pr`. See [README.md](README.md) for an introduction and [docs/workflows.md](docs/workflows.md) for workflow details and diagrams.

## Project Structure

```
codex/                    # Codex edition (canonical Codex tree)
├── skills/<skill-name>/
│   ├── SKILL.md          # Skill definition (YAML frontmatter + markdown body)
│   ├── scripts/          # Optional supporting scripts
│   ├── references/       # Optional reference documentation
│   └── assets/           # Optional templates or boilerplate
├── SETUP.md
├── UPDATE.md
├── MIGRATION.md
├── ADDITIONS.md
└── SKILL-CONVENTIONS.md
claude/                   # Claude Code edition (parallel tree)
```

Each skill is self-contained. Skills compose other skills to any depth via `$skill-name` invocations. The key distinction is between analysis skills (return structured findings without acting) and workflow skills (compose analysis skills and act on results).

For Codex skill conventions, see [`codex/SKILL-CONVENTIONS.md`](codex/SKILL-CONVENTIONS.md). General skill-authoring principles live in [`codex/skills/create-skill/references/`](codex/skills/create-skill/references/), split by topic and indexed in that skill's SKILL.md.

## Key Files

- `~/.turbo/config.json` — User-level configuration. Top-level `oracle` is shared. Per-edition state lives under `codex.{excludeSkills, lastUpdateHead, configVersion, sharedClaudeAutoMemory}`; the parallel `claude.*` object is present when the Claude edition is also installed.
- `~/.turbo/repo/` — Local clone of the upstream turbo repo (skill source for install/update)
- `~/.agents/skills/` — Installed Codex skills

A change that leaves a `~/.turbo/config.json` key with no effect carries its own cleanup: add a `MIGRATION.md` entry deleting the key in each edition and bump the `Current version` in `UPDATE.md`. Dropping the key from `SETUP.md` only stops new installs from writing it, leaving it behind everywhere it was already written.

When working inside `codex/`, also see [`codex/AGENTS.md`](codex/AGENTS.md) for edition-specific rules.
