<h1 align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/logo/thunderbolt-readme-dark-1440.png">
    <img src="assets/logo/thunderbolt-readme-light-1440.png" alt="Turbo" width="600">
  </picture>
</h1>

**Reusable workflows for planning, building, reviewing, and shipping with AI coding agents.**

Turbo gives Claude Code and Codex a repeatable development process, packaged as Markdown skills. Use a skill for a single task, or combine them into a workflow that takes a change from idea to pull request.

**[Claude Code](claude/):** production-tested · **[Codex](codex/):** experimental, with skill parity but less real-world use

[Get started](#get-started) · [What you can do](#what-you-can-do) · [Browse the guides](#go-deeper)

## From Idea to Pull Request

```text
Plan  →  Implement  →  Finalize
```

Start with a change you want to make:

```text
/turboplan add password reset to the app
```

Turbo assesses the scope and helps you settle the approach. Clear-scope changes proceed to implementation after you agree on the shape. When the approach needs a written plan, Turbo drafts and reviews one; you then run `/implement-plan` in a fresh session.

Once a plan's steps are complete, `/finalize` runs checks, reviews and polishes the changes, updates documentation and the changelog, captures lessons, and takes you through shipping. For work without a plan file, `/implement` offers full finalization, a quicker close, or stopping. You can also run `/finalize` on work you built yourself.

Examples use Claude Code's `/skill-name` syntax. In Codex, use `$skill-name`:

```text
$turboplan add password reset to the app
```

## Get Started

Paste this into Claude Code or Codex:

```text
Walk me through the Turbo setup. Read SETUP.md from the tobihagemann/turbo repo and follow the guide for your edition.
```

The agent selects your edition, installs the skills, and walks you through tools and configuration interactively.

Prefer to read the steps first? Open the **[Claude Code setup](claude/SETUP.md)** or **[Codex setup](codex/SETUP.md)** guide.

Pipeline workflows are context-heavy. Peer review uses the other coding agent, so access to both gives you the full workflow. You can replace those review skills to suit your setup. See [access and prerequisites](docs/customization.md#access-and-prerequisites) for details.

## What You Can Do

You can start with any of these skills; you don't need to learn the whole pipeline first.

| I want to… | Claude Code | Codex |
|---|---|---|
| Plan and build a change | `/turboplan` | `$turboplan` |
| Understand a failing test or bug | `/investigate` | `$investigate` |
| Review a pull request | `/review-pr` | `$review-pr` |
| Finish and ship a change | `/finalize` | `$finalize` |
| Check project health | `/audit` | `$audit` |
| Get oriented in a new codebase | `/onboard` | `$onboard` |

Skills also work naturally in a request: `tests are failing in the auth module, can you please /investigate?`

See [more prompt examples](docs/examples.md) for dependency updates, UI testing, PR feedback, and other everyday tasks.

## Why Turbo

- **A process you can repeat.** Planning, investigation, review, and shipping workflows are written down as skills, so you can invoke them without rebuilding the prompt each time. They use your project's existing tests, linters, formatters, and hooks.
- **Pieces you can replace.** Use individual skills or compose them into larger workflows. Swap review tools, commit conventions, or code-style guidance for your own. The skills are plain Markdown using the harness's native tools.
- **Lessons carried forward.** `/self-improve` captures corrections and project conventions in instructions, memory, and skills, so future sessions can build on what you've learned.

You stay involved in choosing the approach and reviewing the result. Turbo works best alongside the checks and engineering judgment you already bring to a project.

## Go Deeper

- <a id="the-turboplan-pipeline"></a><a id="the-finalize-pipeline"></a>**[Workflow guide](docs/workflows.md)** — planning and finalization diagrams, self-improvement, audits, and onboarding.
- <a id="browser-and-ui-testing"></a>**[Browser and UI testing](docs/workflows.md#browser-and-ui-testing)** — hands-on verification and trying changes yourself.
- **[Customization and setup details](docs/customization.md)** — swap skills, understand harness instructions, and update your installation.
- **[Prompt examples](docs/examples.md)** — requests you can copy into your next session.
- <a id="all-skills"></a>**All skills:** [Claude Code index](claude/SKILL-INDEX.md) · [Codex index](codex/SKILL-INDEX.md) — descriptions and dependencies for every skill.

---

If Turbo helps you ship, consider [sponsoring my open source work](https://github.com/sponsors/tobihagemann).

Distributed under the [MIT License](LICENSE).
