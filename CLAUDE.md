# Turbo

Turbo is a human-gated agentic software factory, shipped as a plugin with sibling editions for Claude Code and Codex. The human decides what to build and judges the result, and skills shape, build, try, polish, learn, and ship in between. Skills connect into larger pipelines like `/finalize` and `/review-pr`. See [README.md](README.md) for an introduction and [docs/workflows.md](docs/workflows.md) for workflow details and diagrams.

Each `docs/` guide answers one reader question: `workflows.md` (how it works), `examples.md` (what to type), `requirements.md` (what you need and what setup changes), `claude-code-mod.md` (what the Claude Code mod adds while Turbo runs), `customization.md` (how to adapt and update). Place new doc content by the question it answers.

## Project Structure

```
.claude-plugin/           # Claude Code marketplace (one plugin, `turbo`, sourced from claude/)
.agents/plugins/          # Codex marketplace (one plugin, `turbo`, sourced from codex/)
claude/                   # Claude Code edition and plugin root (canonical Claude tree)
├── .claude-plugin/       # Plugin manifest
├── skills/<skill-name>/
│   ├── SKILL.md          # Skill definition (YAML frontmatter + markdown body)
│   ├── scripts/          # Optional supporting scripts
│   ├── references/       # Optional reference documentation
│   └── assets/           # Optional templates or boilerplate
├── hooks/                # Plugin mod: rules injection, status entry, startup checks, context and compact tools, open items
├── tests/                # Mod tests
├── types/                # Mod state contract, named in the plugin manifest
├── SETUP.md
├── UPDATE.md             # One-time migration from a copy install to the plugin
├── ADDITIONS.md          # Turbo rules the mod injects into every session
└── SKILL-CONVENTIONS.md
codex/                    # Codex edition and plugin root (parallel tree; hooks/ holds the SessionStart hook)
tests/                    # Tests for scripts both editions ship, outside both plugin roots
```

Each skill is self-contained. Skills compose other skills to any depth via `/skill-name` invocations. The key distinction is between analysis skills (return structured findings without acting) and workflow skills (compose analysis skills and act on results).

After editing `checkout-snapshot.sh`, keep its four copies (polish-code and evaluate-findings, both editions) identical and run `bash tests/checkout-snapshot-harness.sh`.

After editing the plugin mod, run `claude plugin validate claude` and `claude plugin test claude`. The test kit asserts the drawn tree and lays nothing out, so check a change to wrapping, alignment, or spacing in a live session before handing it over. When the edit changes what users see, update `docs/claude-code-mod.md` and re-capture the affected `assets/mod-*.svg` as `assets/CLAUDE.md` describes.

`/smoke-test`, `/create-test-plan`, and `/exploratory-test` share one testing domain. An execution rule (launching and driving the running app, and cleaning up after it) goes into `/test-run-rules` alone, which both test-running skills load. A scenario-design rule (what a test covers and what counts as a pass) that lands in `/smoke-test` also goes into `/create-test-plan`.

@claude/SKILL-CONVENTIONS.md

## Key Files

- `~/.turbo/config.json` — User-level configuration. Top-level `oracle` is shared, and top-level `checkout` names a Turbo clone or fork that `/self-improve` hands Turbo skill lessons to. `codex.sharedClaudeAutoMemory` is the Codex edition's shared-memory preference.

A setting Turbo requires goes into `SETUP.md`. When the harness lets the plugin observe it, as the Claude mod observes an environment variable, the mod or the Codex `SessionStart` hook also checks it at startup and tells the user what is missing. A setting the plugin cannot observe, such as a Codex `config.toml` key, lives in `SETUP.md` alone. A retired key or setting is dropped from `SETUP.md` and left behind on existing installs.

When working inside `claude/`, also see [`claude/CLAUDE.md`](claude/CLAUDE.md) for edition-specific rules.
