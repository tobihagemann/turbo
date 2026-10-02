# Turbo

Turbo is a modular collection of agentic coding skills with sibling editions for Claude Code and Codex. Skills connect into larger pipelines like `/finalize` and `/review-pr`. See [README.md](README.md) for an introduction and [docs/workflows.md](docs/workflows.md) for workflow details and diagrams.

Each `docs/` guide answers one reader question: `workflows.md` (how it works), `examples.md` (what to type), `requirements.md` (what you need and what setup changes), `customization.md` (how to adapt and update). Place new doc content by the question it answers.

## Project Structure

```
claude/                   # Claude Code edition (canonical Claude tree)
├── skills/<skill-name>/
│   ├── SKILL.md          # Skill definition (YAML frontmatter + markdown body)
│   ├── scripts/          # Optional supporting scripts
│   ├── references/       # Optional reference documentation
│   ├── assets/           # Optional templates or boilerplate
│   ├── .claude-plugin/   # Optional plugin manifest; makes the folder load as a mod
│   ├── hooks/            # Optional mod: function hooks listed in hooks.json
│   └── tests/            # Optional mod tests
├── SETUP.md
├── UPDATE.md
├── MIGRATION.md
├── ADDITIONS.md
└── SKILL-CONVENTIONS.md
codex/                    # Codex edition (parallel tree)
```

Each skill is self-contained. Skills compose other skills to any depth via `/skill-name` invocations. The key distinction is between analysis skills (return structured findings without acting) and workflow skills (compose analysis skills and act on results).

After editing a skill's bundled mod, run `claude plugin validate claude/skills/<name>` and `claude plugin test claude/skills/<name>`.

`/smoke-test`, `/create-test-plan`, and `/exploratory-test` share one testing domain. An execution rule (launching and driving the running app, and cleaning up after it) goes into `/test-run-rules` alone, which both test-running skills load. A scenario-design rule (what a test covers and what counts as a pass) that lands in `/smoke-test` also goes into `/create-test-plan`.

@claude/SKILL-CONVENTIONS.md

## Key Files

- `~/.turbo/config.json` — User-level configuration. Top-level `oracle` is shared. Per-edition state lives under `claude.{excludeSkills, lastUpdateHead, configVersion}`; the parallel `codex.*` object is present when the Codex edition is also installed.
- `~/.turbo/repo/` — Local clone of the upstream turbo repo (skill source for install/update)
- `~/.claude/skills/` — Installed Claude Code skills

A change that leaves a `~/.turbo/config.json` key with no effect carries its own cleanup: add a `MIGRATION.md` entry deleting the key in each edition and bump the `Current version` in `UPDATE.md`. Dropping the key from `SETUP.md` only stops new installs from writing it, leaving it behind everywhere it was already written.

The same holds for a `settings.json` entry that `SETUP.md` Step 4 writes. Adding, changing, or retiring one takes the `SETUP.md` change plus a `MIGRATION.md` entry that rewires existing installs, with a `Current version` bump.

When working inside `claude/`, also see [`claude/CLAUDE.md`](claude/CLAUDE.md) for edition-specific rules.
