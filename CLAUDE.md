# Turbo

Turbo is a modular collection of agentic coding skills with sibling editions for Claude Code and Codex. Skills connect into larger pipelines like `/finalize` and `/review-pr`. See [README.md](README.md) for the full overview and dependency graph.

## Project Structure

```
claude/                   # Claude Code edition (canonical Claude tree)
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
codex/                    # Codex edition (parallel tree)
```

Each skill is self-contained. Skills compose other skills to any depth via `/skill-name` invocations. The key distinction is between analysis skills (return structured findings without acting) and workflow skills (compose analysis skills and act on results).

@claude/SKILL-CONVENTIONS.md

## Key Files

- `~/.turbo/config.json` — User-level configuration. Top-level `oracle` is shared. Per-edition state lives under `claude.{excludeSkills, lastUpdateHead, configVersion}`; the parallel `codex.*` object is present when the Codex edition is also installed.
- `~/.turbo/repo/` — Local clone of the upstream turbo repo (skill source for install/update)
- `~/.claude/skills/` — Installed Claude Code skills

When working inside `claude/`, also see [`claude/CLAUDE.md`](claude/CLAUDE.md) for edition-specific rules.
