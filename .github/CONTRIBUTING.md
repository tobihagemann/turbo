# Contributing

Turbo skills improve through daily use. When Claude learns something that would make a skill better, `/self-improve` detects it and offers to propose the change upstream via `/contribute-turbo`.

Improvements start as issues. Open one so the change can be discussed before anyone writes it. Pull requests are welcome once an issue has established the direction.

## How It Works

1. **Use Turbo normally.** Work on your project, run `/finalize`, let `/self-improve` extract lessons.
2. **`/self-improve` detects skill improvements.** When a lesson would improve a turbo skill's instructions, it applies the change to your installed copy and asks whether to propose it upstream.
3. **`/contribute-turbo` files the issue.** It compares your installed skills against `~/.turbo/repo/`, separates upstream-worthy corrections from local customizations, drafts the "why" with project-specific details scrubbed (no repo names, file paths, or business logic), and files the issue after your approval.

You can also run `/contribute-turbo` (Claude) or `$contribute-turbo` (Codex) directly at any point.

## Privacy

Proposals go through a privacy filter before they are filed. They describe *what* changed and *why* in general terms, without revealing anything about your project.

## Guidelines

- One concern per issue. When several unrelated skills improved, file a separate issue for each.
- Include the concrete edit. Name the file, the step, and the exact text so the change can be applied as proposed.
- The "why" matters. Proposals carry context about what was missing or wrong so the maintainer can evaluate the change.
- Skill conventions apply. See [CLAUDE.md](../CLAUDE.md) for project-wide context, and the per-edition [`claude/SKILL-CONVENTIONS.md`](../claude/SKILL-CONVENTIONS.md) or [`codex/SKILL-CONVENTIONS.md`](../codex/SKILL-CONVENTIONS.md) for the edition you're contributing to.
