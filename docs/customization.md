# Customization

[← Back to Turbo](../README.md) · [Workflow guide](workflows.md) · [Prompt examples](examples.md) · [Requirements](requirements.md)

## The Puzzle Piece Philosophy

Every skill is a self-contained piece. Pipeline skills like [`/finalize`](../claude/skills/finalize/SKILL.md) and [`/audit`](../claude/skills/audit/SKILL.md) compose them into workflows, but each piece works independently too.

Want to swap a piece? For example:

- Replace [`/peer-review`](../claude/skills/peer-review/SKILL.md) with your own review tool if you don't use the other coding agent
- Replace [`/consult-oracle`](../claude/skills/consult-oracle/SKILL.md) with your own setup (it drives ChatGPT through a browser and needs a one-time sign-in)
- Replace [`/commit-rules`](../claude/skills/commit-rules/SKILL.md) or [`/changelog-rules`](../claude/skills/changelog-rules/SKILL.md) with your team's conventions. The pipeline adapts.
- Replace [`/code-style`](../claude/skills/code-style/SKILL.md) with your team's style guide. The built-in one teaches general principles rather than opinionated rules, so it's a natural swap point.

Skills communicate through standard interfaces: git staging area, PR state, and file conventions.

## Harness Instructions

Beyond skills, each edition ships an `ADDITIONS.md` (e.g. [`claude/ADDITIONS.md`](../claude/ADDITIONS.md)), a small set of behavioral rules added to your harness's instruction file during setup. The most important one is **Skill Loading**: without it, the agent tends to skip reloading skills it has already seen in a session, which causes it to silently drop steps in nested pipelines like [`/finalize`](../claude/skills/finalize/SKILL.md). The additions are kept in sync by [`/update-turbo`](../claude/skills/update-turbo/SKILL.md). See [claude/docs/skill-loading-reasoning.md](../claude/docs/skill-loading-reasoning.md) for the full rationale (Claude-specific failure modes and mitigations; the Codex edition adapts the same rules in [`codex/ADDITIONS.md`](../codex/ADDITIONS.md)).

## Updating

Run [`/update-turbo`](../claude/skills/update-turbo/SKILL.md) (Claude Code) or [`$update-turbo`](../codex/skills/update-turbo/SKILL.md) (Codex) to update all skills. It fetches the latest update instructions from GitHub, builds a changelog, handles conflict detection for customized skills, and manages exclusions. The Claude Code edition's context-tracking scripts in `~/.claude/hooks/turbo/` are yours to edit too: `/update-turbo` updates untouched copies and asks before changing one you've customized.
