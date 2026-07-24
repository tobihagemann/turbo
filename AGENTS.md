# Turbo

Turbo is a modular collection of agentic coding skills with sibling editions for Claude Code and Codex. Skills connect into larger pipelines like `$finalize` and `$review-pr`. See [README.md](README.md) for the full overview and dependency graph.

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

- `~/.turbo/config.json` — User-level configuration. Top-level `repoMode` and `oracle` are shared. Per-edition state lives under `codex.{excludeSkills, lastUpdateHead, configVersion}`; the parallel `claude.*` object is present when the Claude edition is also installed.
- `~/.turbo/repo/` — Local clone or fork of the turbo repo (skill source for install/update)
- `~/.agents/skills/` — Installed Codex skills

When working inside `codex/`, also see [`codex/AGENTS.md`](codex/AGENTS.md) for edition-specific rules.
