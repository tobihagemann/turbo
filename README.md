<p align="center">
  <img src="assets/logo/thunderbolt-icon-256.png" width="128" height="128" alt="Turbo lightning hammer">
</p>

<h1 align="center">Turbo</h1>

<p align="center">
  A human-gated agentic software factory for Claude Code and Codex.
</p>

---

Turbo turns your coding agent into a one-person software factory. You decide what to build before any code exists and judge the result at the end. In between, skills shape the change, build it, polish it, and ship it. Each session teaches the next. A human holds both gates, so nothing ships that nobody looked at.

**[Claude Code](claude/SKILL-INDEX.md):** production-tested · **[Codex](codex/SKILL-INDEX.md):** experimental, with skill parity but less real-world use

[Get started](#get-started) · [The factory](#the-factory) · [What you can do](#what-you-can-do) · [Browse the guides](#go-deeper)

## The Factory

Start with a change you want to make:

```text
/turbo:plan add password reset to the app
```

The change moves through six stages. You decide at Shape and judge at Try and Ship. The skills run the rest.

| Stage | What happens | Skill |
|---|---|---|
| **Shape** | Settle what to build and how. You approve the shape or the plan before any code is written. | [`/turbo:plan`](claude/skills/plan/SKILL.md) |
| **Build** | Make the change and verify it runs, with a smoke test in the live app for user-facing changes. | [`/turbo:implement`](claude/skills/implement/SKILL.md) |
| **Try** | You try a user-facing change in the live app and say whether it's right. | [`/turbo:preview`](claude/skills/preview/SKILL.md) |
| **Polish** | Run the project's checks, review with a second agent as peer reviewer, fix, and repeat until stable. | [`/turbo:polish-code`](claude/skills/polish-code/SKILL.md) |
| **Learn** | Carry corrections and conventions into instructions, memory, and skills. | [`/turbo:self-improve`](claude/skills/self-improve/SKILL.md) |
| **Ship** | Commit, push, and open the pull request once you approve. | [`/turbo:ship`](claude/skills/ship/SKILL.md) |

Examples use Claude Code's `/turbo:skill-name` syntax. In Codex, use `$turbo:skill-name`:

```text
$turbo:plan add password reset to the app
```

## Get Started

What you'll need:

- A Claude Code or Codex plan with headroom. Pipeline workflows are context-heavy, so higher-tier plans work best.
- Codex (for the Claude Code edition) or Claude Code (for the Codex edition), which `/finalize` uses for peer review. You can swap in your own review setup.
- The [GitHub CLI](https://cli.github.com/).

See [requirements](docs/requirements.md) for what setup changes on your machine and what your project should have.

**Claude Code:** install the plugin, then open `/plugin` → Marketplaces and switch on auto-update for `turbo`.

```text
/plugin marketplace add tobihagemann/turbo
/plugin install turbo@turbo
```

**Codex:** install the plugin, then trust Turbo's hook when Codex asks at its next start.

```bash
codex plugin marketplace add tobihagemann/turbo
codex plugin add turbo@turbo
```

Then paste this into Claude Code or Codex for the remaining one-time steps (prerequisites, settings, and optional extras):

```text
Walk me through the Turbo setup. Read SETUP.md from the tobihagemann/turbo repo and follow the guide for your edition.
```

Prefer to read the steps first? Open the **[Claude Code setup](claude/SETUP.md)** or **[Codex setup](codex/SETUP.md)** guide.

Installed Turbo before it shipped as a plugin? Run `/update-turbo` (or `$update-turbo`) once. It moves you to the plugin and keeps your edited skills unless you choose otherwise.

## What You Can Do

You can start with any of these skills; you don't need to learn the whole pipeline first.

| I want to… | Claude Code | Codex |
|---|---|---|
| Plan and build a change | `/turbo:plan` | `$turbo:plan` |
| Understand a failing test or bug | `/turbo:investigate` | `$turbo:investigate` |
| Review a pull request | `/turbo:review-pr` | `$turbo:review-pr` |
| Finish and ship a change | `/turbo:finalize` | `$turbo:finalize` |

Skills also work naturally in a request: `tests are failing in the auth module, can you please /turbo:investigate?`

See [more prompt examples](docs/examples.md) for dependency updates, UI testing, PR feedback, and other everyday tasks.

## Why Turbo

- **A process you can repeat.** Planning, investigation, review, and shipping workflows are written down as skills, so you can invoke them without rebuilding the prompt each time. They use your project's existing tests, linters, formatters, and hooks.
- **Pieces you can swap.** Use individual skills or compose them into larger workflows. A skill of your own with the same name takes over that piece, inside Claude Code pipelines too. The skills are plain Markdown using the harness's native tools.
- **Lessons carried forward.** `/self-improve` captures corrections and project conventions in instructions, memory, and skills, so future sessions can build on what you've learned.

You stay involved in choosing the approach and reviewing the result. Turbo works best alongside the checks and engineering judgment you already bring to a project.

## Go Deeper

- **[Workflow guide](docs/workflows.md)** — the six stages from your side, then the plan and finalize pipelines, self-improvement, and browser testing.
- **[Prompt examples](docs/examples.md)** — requests you can copy into your next session.
- **[Requirements](docs/requirements.md)** — accounts, what setup changes, and the project infrastructure Turbo builds on.
- **[Claude Code mod](docs/claude-code-mod.md)** — open items above the prompt, the status line, and compaction that continues on its own.
- **[Customization](docs/customization.md)** — override skills, update the plugin, and work on Turbo or a fork.
- **All skills:** [Claude Code index](claude/SKILL-INDEX.md) · [Codex index](codex/SKILL-INDEX.md) — descriptions and dependencies for every skill.

---

If Turbo helps you ship, consider [sponsoring my open source work](https://github.com/sponsors/tobihagemann).

Distributed under the [MIT License](LICENSE).
