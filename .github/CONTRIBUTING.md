# Contributing

Turbo skills improve through daily use. When Claude learns something that would make a skill better, `/self-improve` detects it and offers to submit the change upstream via `/contribute-turbo`.

## Setup

During [Turbo setup](../SETUP.md), choose **Contribute (fork)** when asked your relationship to Turbo. This sets `repoMode: "fork"` in `~/.turbo/config.json` and configures the remotes so PRs target the upstream repo.

If you already set up with clone mode, `/contribute-turbo` will offer to help convert your clone to a fork.

## How It Works

1. **Use Turbo normally.** Work on your project, run `/finalize`, let `/self-improve` extract lessons.
2. **`/self-improve` detects skill improvements.** When a lesson would improve a turbo skill's instructions, it applies the change to your installed copy and asks if you want to contribute it upstream.
3. **`/contribute-turbo` handles the rest.** It stages the changes in `~/.turbo/repo/`, drafts a commit message and PR description with project-specific details scrubbed (no repo names, file paths, or business logic), and creates a PR after your approval.

You can also run `/contribute-turbo` (Claude) or `$contribute-turbo` (Codex) directly if you've manually edited a skill in `~/.turbo/repo/claude/skills/` or `~/.turbo/repo/codex/skills/`.

## Privacy

Contribution messages go through a privacy filter before submission. They describe *what* changed and *why* in general terms, without revealing anything about your project.

## Guidelines

- One concern per PR. If you improved multiple unrelated skills, `/contribute-turbo` creates separate branches.
- The "why" matters. Contributions include context about what was missing or wrong so the maintainer can evaluate the change.
- Skill conventions apply. See [CLAUDE.md](../CLAUDE.md) for project-wide context, and the per-edition [`claude/SKILL-CONVENTIONS.md`](../claude/SKILL-CONVENTIONS.md) or [`codex/SKILL-CONVENTIONS.md`](../codex/SKILL-CONVENTIONS.md) for the edition you're contributing to.
