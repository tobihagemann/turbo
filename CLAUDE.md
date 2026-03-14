# Turbo

Turbo is a modular collection of Claude Code skills — each skill teaches Claude a specific dev workflow. Skills connect into larger pipelines via orchestrator skills like `/finalize` and `/review-pr`. See [README.md](README.md) for the full overview and dependency graph.

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
- Skills should be context-agnostic: accept caller-specified context but determine their own when called standalone (from conversation context or git state). See `/simplify-code` as the model.
- Skills should avoid side effects outside their domain. Let the caller or a dedicated skill handle cross-cutting concerns (e.g., staging files).
- Run `/create-skill` when creating or editing skills

## Key Files

- `~/.turbo/config.json` — User-level configuration (repoMode, excludeSkills, lastUpdateHead, oracle settings)
- `~/.turbo/repo/` — Local clone or fork of the turbo repo (skill source for install/update)
