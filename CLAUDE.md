# Turbo

Turbo is a modular collection of Claude Code skills — each skill teaches Claude a specific dev workflow. Skills connect into larger pipelines via orchestrator skills like `/finalize` and `/review-feature-branch`. See [README.md](README.md) for the full overview and dependency graph.

## Project Structure

```
skills/<skill-name>/
├── SKILL.md              # Skill definition (YAML frontmatter + markdown body)
├── scripts/              # Optional supporting scripts
├── references/           # Optional reference documentation
└── assets/               # Optional templates or boilerplate
```

Each skill is self-contained. Orchestrators compose skills by invoking them via `/skill-name`, not by importing code.

## Skill Conventions

- SKILL.md frontmatter has `name` and `description` — description includes trigger phrases
- Skills should not reference which orchestrators call them (stay self-contained)
- Orchestrator skills use `TaskCreate` for phase tracking
- Skills communicate through standard interfaces: git staging area, PR state, file conventions at `.turbo/`
- Read `skills/create-skill/references/best-practices.md` before writing or editing skills

## Key Files

- `skills/create-skill/references/best-practices.md` — Authoritative guide for skill authoring
- `skills/create-skill/references/skill-reviewer.md` — Review checklist for skills
- `~/.turbo/config.json` — User-level configuration (e.g., oracle skill settings)
