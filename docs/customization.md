# Customization

[← Back to Turbo](../README.md) · [Workflow guide](workflows.md) · [Prompt examples](examples.md) · [Requirements](requirements.md)

## The Puzzle Piece Philosophy

Every skill is a self-contained piece. Pipeline skills like [`/turboplan`](../claude/skills/turboplan/SKILL.md) and [`/finalize`](../claude/skills/finalize/SKILL.md) compose them into workflows, but each piece works independently too.

Want to swap a piece? For example:

- Replace [`/peer-review`](../claude/skills/peer-review/SKILL.md) with your own review tool if you don't use the other coding agent
- Replace [`/consult-oracle`](../claude/skills/consult-oracle/SKILL.md) with your own setup (it drives ChatGPT through a browser and needs a one-time sign-in)
- Replace [`/commit-rules`](../claude/skills/commit-rules/SKILL.md) or [`/changelog-rules`](../claude/skills/changelog-rules/SKILL.md) with your team's conventions. The pipeline adapts.
- Replace [`/code-style`](../claude/skills/code-style/SKILL.md) with your team's style guide. The built-in one teaches general principles rather than opinionated rules, so it's a natural swap point.

Skills communicate through standard interfaces: git staging area, PR state, and file conventions.

## Overriding a Skill

To replace one piece, create a skill with the same name in your personal skills folder (`~/.claude/skills/<name>/SKILL.md`, or `~/.agents/skills/<name>/SKILL.md` for Codex) or in a project's skills folder. In Claude Code it takes over that name everywhere, including when a Turbo pipeline invokes it. In Codex it takes over the name you type; whether a pipeline's nested call reaches it is unverified. Start from Turbo's version in this repo if you only want to adjust it. Your copy stops receiving Turbo's updates to that skill, so compare it with the upstream version now and then.

For changes across many skills, fork the repo and install your fork as its own marketplace in place of `tobihagemann/turbo`.

## Harness Instructions

Beyond skills, each edition ships an `ADDITIONS.md` (e.g. [`claude/ADDITIONS.md`](../claude/ADDITIONS.md)), a small set of behavioral rules the plugin injects into every session. The most important one is **Skill Loading**: without it, the agent tends to skip reloading skills it has already seen in a session, which causes it to silently drop steps in nested pipelines like [`/finalize`](../claude/skills/finalize/SKILL.md). See [claude/docs/skill-loading-reasoning.md](../claude/docs/skill-loading-reasoning.md) for the full rationale (Claude-specific failure modes and mitigations; the Codex edition adapts the same rules in [`codex/ADDITIONS.md`](../codex/ADDITIONS.md)).

## Updating

**Claude Code:** switch on auto-update for the `turbo` marketplace under `/plugin` → Marketplaces, and new versions arrive as Turbo changes. Without it, run `/plugin marketplace update turbo` and restart.

**Codex:** refresh the marketplace, then reinstall the plugin so Codex copies the new version:

```bash
codex plugin marketplace upgrade
codex plugin remove turbo@turbo
codex plugin add turbo@turbo
```

## Working on Turbo or a Fork

Clone the repo (or your fork) and use the clone as the plugin, so your edits take effect without a copy step:

1. Remove the GitHub marketplace if you added it, since both are named `turbo`: `/plugin marketplace remove turbo` (Claude Code) or `codex plugin marketplace remove turbo` (Codex).
2. Add the clone and install from it: `/plugin marketplace add <clone>` and `/plugin install turbo@turbo` (Claude Code), or `codex plugin marketplace add <clone>` and `codex plugin add turbo@turbo` (Codex).
3. Set the top-level `checkout` key in `~/.turbo/config.json` to the clone's absolute path, creating the file when it does not exist.

Claude Code loads the plugin from the clone in place: an edit applies at the next session, or right away after `/reload-plugins`. Codex runs a copy, so re-run the Codex update commands above after editing.

With `checkout` set, `/self-improve` in any project writes lessons for Turbo's skills into `<clone>/.turbo/handoff/` instead of proposing them upstream, ready to apply in a session inside the clone.
