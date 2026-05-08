# Turbo

A composable dev process for agentic coding harnesses, packaged as modular skills. Turbo has sibling editions for [Claude Code](claude/) and [Codex](codex/).

The Claude Code edition is production-tested. The Codex edition is currently experimental: the skill set has reached parity, but it has seen less real-world use.

**TL;DR** — Three steps to ship:

1. **Plan** — Run [`/turboplan`](claude/skills/turboplan/SKILL.md) (or enter raw plan mode) and describe what you want to build
2. **Implement** — Run [`/implement-plan`](claude/skills/implement-plan/SKILL.md) on the plan, or [`/implement`](claude/skills/implement/SKILL.md) for ad-hoc changes
3. **Finalize** — [`/finalize`](claude/skills/finalize/SKILL.md) runs tests, code polishing, commit, and PR. It kicks in automatically after any `/implement*` skill; run it yourself if you built by hand.

This loop is the core. Two more pipelines run alongside it for work that does not fit the loop: [`/audit`](claude/skills/audit/SKILL.md) for project-wide health checks and [`/onboard`](claude/skills/onboard/SKILL.md) for ramping up on new projects. Beyond the four pipelines, Turbo ships [60+ skills](#all-skills) for debugging, reviewing, dependency upgrades, and self-improvement that makes each session teach the next. See the [prompt examples](#prompt-examples) for how they look in practice, or read on for the full picture.

## Editions

```text
claude/   # Claude Code edition
codex/    # Codex edition
```

Each edition is a self-contained tree with its own `SETUP.md`, `UPDATE.md`, `MIGRATION.md`, `ADDITIONS.md`, `SKILL-CONVENTIONS.md`, and `skills/`. The root-level `SETUP.md`, `MIGRATION.md`, and `SKILL-CONVENTIONS.md` are short routers that point at the per-edition files. The root `UPDATE.md` exists only to migrate users with pre-split installations onto the per-edition flow. `ADDITIONS.md` lives only under each edition since its content is injected into the harness's instruction file during setup.

## What Is This?

Turbo covers the full dev lifecycle: reviewing code, creating PRs, investigating bugs, self-improving from session learnings, and more.

Five ideas shape the design:

1. **Standardized process.** Skills capture dev workflows so you can run them directly instead of prompting from scratch. [`/turboplan`](claude/skills/turboplan/SKILL.md) analyzes complexity and routes to the right mode. [`/finalize`](claude/skills/finalize/SKILL.md) runs your entire post-implementation QA in one command. [`/investigate`](claude/skills/investigate/SKILL.md) follows a structured root cause analysis cycle. The skill is the prompt.
2. **Layered design.** Skills compose other skills to any depth. [`/review-code security`](claude/skills/review-code/SKILL.md) runs a single-concern scan. [`/review-code`](claude/skills/review-code/SKILL.md) with no argument runs all six types in parallel. [`/polish-code`](claude/skills/polish-code/SKILL.md) loops format → lint → test → review → evaluate → apply → smoke test until stable. [`/finalize`](claude/skills/finalize/SKILL.md) wraps the whole pipeline with self-improvement and commit. [`/audit`](claude/skills/audit/SKILL.md) fans out to all analysis skills in parallel, evaluates the combined findings, and produces a health report. Each pipeline composes with a natural, predictable interface. See [The Turboplan Pipeline](#the-turboplan-pipeline) and [The Finalize Pipeline](#the-finalize-pipeline) for worked examples.
3. **Swappable by design.** Every skill owns one concern and communicates through standard interfaces. Replace any piece with your own and the pipeline adapts. See [The Puzzle Piece Philosophy](#the-puzzle-piece-philosophy) for details.
4. **Works out of the box.** Install the skills and the full workflow is ready. Dependencies are standard dev tooling (GitHub CLI, Codex) that most teams already have.
5. **Just skills.** No framework, no custom runtime, no new memory system. Skills are plain markdown that use the harness's native primitives (git, filesystem, built-in tools). Remove an independent skill and the rest still work.

The one thing beyond skills is each edition's `ADDITIONS.md` (e.g. [`claude/ADDITIONS.md`](claude/ADDITIONS.md)), a small set of behavioral rules added to your harness's instruction file during setup. The most important one is **Skill Loading**: without it, the agent tends to skip reloading skills it has already seen in a session, which causes it to silently drop steps in nested pipelines like [`/finalize`](claude/skills/finalize/SKILL.md). The additions are kept in sync by [`/update-turbo`](claude/skills/update-turbo/SKILL.md). See [claude/docs/skill-loading-reasoning.md](claude/docs/skill-loading-reasoning.md) for the full rationale (Claude-specific failure modes and mitigations; the Codex edition adapts the same rules in [`codex/ADDITIONS.md`](codex/ADDITIONS.md)).

The other core piece is [`/self-improve`](claude/skills/self-improve/SKILL.md), which makes the whole system compound. After each session, it extracts lessons from the conversation and routes them to the right place: project `CLAUDE.md`/`AGENTS.md`, auto memory, or existing/new skills. Every session teaches the agent something, and future sessions benefit.

## Works Best With

Turbo amplifies your existing process. It shines when your project has the right infrastructure in place:

- **Tests** — [`/finalize`](claude/skills/finalize/SKILL.md) runs your test suite and reviews test coverage gaps. Without tests, there's no safety net. If your project doesn't have automated tests, [`/smoke-test`](claude/skills/smoke-test/SKILL.md) can fill the gap by launching your app and verifying changes manually (it's part of the [`/polish-code`](claude/skills/polish-code/SKILL.md) loop), but real tests are always better. See [Browser and UI Testing](#browser-and-ui-testing) for the tools that power browser and native app verification.
- **Linters and formatters** — [`/finalize`](claude/skills/finalize/SKILL.md) runs your formatter and linter before code review. If you don't have one, style issues slip through.
- **Pre-commit hooks** — [`/finalize`](claude/skills/finalize/SKILL.md) commits your changes, which triggers any pre-commit hooks you have configured. Claude Code respects hook failures and fixes issues before retrying. If your project uses tools like `husky`, `lint-staged`, or `pre-commit`, Turbo works with them automatically.
- **Dead code analysis** — [`/find-dead-code`](claude/skills/find-dead-code/SKILL.md) (standalone skill, not part of [`/finalize`](claude/skills/finalize/SKILL.md)) identifies unused code via parallel analysis, but it's even better when your project already has tools like `knip`, `vulture`, or `periphery` integrated.
- **Dependencies** — [GitHub CLI](https://cli.github.com/) powers PR operations. The Claude edition uses Codex for peer review; the Codex edition uses Claude for peer review. Everything works without peer review, but the full pipeline is better with it. See the edition setup guides for details.

## Who It's For

The target audience is experienced developers who want to move faster without sacrificing quality. That said, beginners are welcome too. Turbo is a great way to learn how a professional dev workflow looks. Just don't blindly trust outputs. Review what Claude produces, understand _why_ it made those choices, and build your own judgment alongside it.

If your plan is vague, your architecture is unclear, and you skip every review finding, Turbo won't save you. Garbage in, garbage out.

## The Puzzle Piece Philosophy

Every skill is a self-contained piece. Pipeline skills like [`/finalize`](claude/skills/finalize/SKILL.md) and [`/audit`](claude/skills/audit/SKILL.md) compose them into workflows, but each piece works independently too.

Want to swap a piece? For example:

- Replace [`/consult-oracle`](claude/skills/consult-oracle/SKILL.md) with your own setup (it's macOS-only and has a cookies workaround)
- Replace [`/commit-rules`](claude/skills/commit-rules/SKILL.md) or [`/changelog-rules`](claude/skills/changelog-rules/SKILL.md) with your team's conventions. The pipeline adapts.
- Replace [`/code-style`](claude/skills/code-style/SKILL.md) with your team's style guide. The built-in one teaches general principles rather than opinionated rules, so it's a natural swap point.

Skills communicate through standard interfaces: git staging area, PR state, and file conventions.

## Sponsorship

If Turbo has helped you ship faster and you're so inclined, I'd greatly appreciate it if you'd consider [sponsoring my open source work](https://github.com/sponsors/tobihagemann).

## Quick Start

### Prerequisites

Pick your edition: [`claude/SETUP.md`](claude/SETUP.md) for Claude Code, [`codex/SETUP.md`](codex/SETUP.md) for Codex. Both editions work best with their respective Max-tier plans (pipeline workflows are context-heavy). Additional tools are installed during setup.

**External services:** The Claude edition benefits from ChatGPT Plus or higher for Codex peer review. The Codex edition benefits from Claude Code access for Claude peer review. ChatGPT Pro or Business is useful for [`/consult-oracle`](claude/skills/consult-oracle/SKILL.md), where Pro models are the only ones that reliably solve very hard problems. [`/peer-review`](claude/skills/peer-review/SKILL.md) and [`/consult-oracle`](claude/skills/consult-oracle/SKILL.md) are designed as swappable puzzle pieces, so if you don't have access, replace them with alternatives that work for you.

### Automatic Setup (Recommended)

In Claude Code or Codex, prompt:

```
Walk me through the Turbo setup. Read SETUP.md from the tobihagemann/turbo repo and follow the guide for your edition.
```

The agent reads the root [`SETUP.md`](SETUP.md), picks the file that matches its harness ([`claude/SETUP.md`](claude/SETUP.md) or [`codex/SETUP.md`](codex/SETUP.md)), clones the repo, installs skills, configures the environment, and walks you through each step interactively.

### Updating

Run [`/update-turbo`](claude/skills/update-turbo/SKILL.md) (Claude Code) or [`$update-turbo`](codex/skills/update-turbo/SKILL.md) (Codex) to update all skills. It fetches the latest update instructions from GitHub, builds a changelog, handles conflict detection for customized skills, and manages exclusions.

## The Turboplan Pipeline

Claude Code's built-in plan mode is a starting point, but it tends to produce plans that miss existing patterns, skip edge cases, or propose approaches that don't hold up under scrutiny. It can also feel too restrictive for iterative planning. Turbo replaces raw plan mode with [`/turboplan`](claude/skills/turboplan/SKILL.md) as a universal entry point. You always start with `/turboplan` — whether your task is a single-session change or a multi-subsystem project. `/turboplan` analyzes the task, routes it through the right pipeline, and produces plans that survive contact with reality. `/turboplan` does not require plan mode to be active. Direct work chains straight through [`/implement`](claude/skills/implement/SKILL.md) to [`/finalize`](claude/skills/finalize/SKILL.md); plan-mode work halts once for a fresh [`/implement-plan`](claude/skills/implement-plan/SKILL.md) session, and spec-mode projects halt again after [`/pick-next-shell`](claude/skills/pick-next-shell/SKILL.md) before implementation.

![How Turboplan Connects](assets/how-turboplan-connects.svg)

[`/turboplan`](claude/skills/turboplan/SKILL.md) has three modes, named by what each one produces and selected automatically by its complexity analysis:

- **Direct mode** — Clear scope and a known approach. Hands off to [`/implement`](claude/skills/implement/SKILL.md), which loads [`/code-style`](claude/skills/code-style/SKILL.md), applies the change, and runs [`/finalize`](claude/skills/finalize/SKILL.md). No plan file is written.
- **Plan mode** — Single-session change whose approach warrants writing down before implementing. Runs [`/draft-plan`](claude/skills/draft-plan/SKILL.md) (survey + consult skills/docs + escalate + discuss + draft) → [`/refine-plan`](claude/skills/refine-plan/SKILL.md) → [`/self-improve`](claude/skills/self-improve/SKILL.md). Halts after self-improve; you run [`/implement-plan`](claude/skills/implement-plan/SKILL.md) in a fresh session.
- **Spec mode** — Multi-subsystem project with architectural decisions. Routes to [`/draft-spec`](claude/skills/draft-spec/SKILL.md) for a guided spec discussion, then [`/refine-plan`](claude/skills/refine-plan/SKILL.md) to iteratively review and revise the spec, then [`/draft-shells`](claude/skills/draft-shells/SKILL.md) to decompose the spec into shells with YAML frontmatter, then [`/refine-plan`](claude/skills/refine-plan/SKILL.md) to review and revise the shells, then [`/self-improve`](claude/skills/self-improve/SKILL.md) to compound planning learnings before context is cleared. Halts after self-improve; you run [`/pick-next-shell`](claude/skills/pick-next-shell/SKILL.md) in fresh sessions to plan each shell, then [`/implement-plan`](claude/skills/implement-plan/SKILL.md) to implement it.

Every sub-skill works standalone too. Run [`/draft-plan`](claude/skills/draft-plan/SKILL.md) directly if you want to draft a plan without the rest of the pipeline. Run [`/refine-plan`](claude/skills/refine-plan/SKILL.md) on a plan you wrote yourself. Run [`/implement-plan`](claude/skills/implement-plan/SKILL.md) in a fresh session on any plan file. Run [`/draft-spec`](claude/skills/draft-spec/SKILL.md) to write a spec without committing to the full pipeline.

### Shells and the Spec-Mode Flow

In spec mode, [`/draft-shells`](claude/skills/draft-shells/SKILL.md) decomposes the spec into **shells**: structured decomposition artifacts that capture the wiring invariants (Produces, Consumes, Covers spec requirements) and high-level Implementation Steps. Shells lock in the decomposition — what each session builds, what it depends on, what spec requirements it covers — without committing to concrete file paths. [`/refine-plan`](claude/skills/refine-plan/SKILL.md) reviews and tightens the shells until stable.

You then drive implementation one shell at a time. [`/pick-next-shell`](claude/skills/pick-next-shell/SKILL.md) picks the next shell whose dependencies are satisfied and chains into [`/expand-shell`](claude/skills/expand-shell/SKILL.md), which adds a fresh pattern survey and concrete references against the current codebase, then refine → self-improve → halt. You run [`/implement-plan`](claude/skills/implement-plan/SKILL.md) in a fresh session. Each implementation session gets fresh pattern surveys, so decisions from earlier sessions naturally inform later ones.

## The Finalize Pipeline

[`/finalize`](claude/skills/finalize/SKILL.md) is the QA and commit side of the loop. Run it when you're done implementing, or let [`/implement`](claude/skills/implement/SKILL.md) / [`/implement-plan`](claude/skills/implement-plan/SKILL.md) chain into it automatically. One command runs tests, iterative code polishing, changelog updates, self-improvement, and commit.

![How Finalize Connects](assets/how-finalize-connects.svg)

`/finalize` runs through these phases automatically:

1. **Polish Code** — Iterative loop: stage → format → lint → test → review → evaluate → apply → smoke test → re-run until stable
2. **Update Changelog** — Add entries to the Unreleased section of CHANGELOG.md (skipped if no changelog exists)
3. **Self-Improve** — Extract learnings, route to CLAUDE.md / AGENTS.md / memory / skills
4. **Ship It** — Branch if needed, commit, push, create or update PR

## Self-Improvement

[`/self-improve`](claude/skills/self-improve/SKILL.md) is a core skill that makes each session teach the next. Run it anytime before ending your session (it's also part of [`/finalize`](claude/skills/finalize/SKILL.md) Phase 3). It scans the conversation for corrections, repeated guidance, failure modes, and preferences, then routes each lesson to the right place: project `CLAUDE.md`/`AGENTS.md`, auto memory, or existing/new skills. Over time, Turbo gets better at your specific project.

[`/note-improvement`](claude/skills/note-improvement/SKILL.md) captures improvement opportunities that come up during work but are out of scope: code review findings you chose to skip, refactoring ideas, missing tests. These get tracked in `.turbo/improvements.md` so they don't get lost. Since `.turbo/` is gitignored, it doesn't clutter the repo. Each entry is tagged with a type — `direct`, `investigate`, or `plan` — so it can be routed correctly later. When you're ready to act on them, [`/implement-improvements`](claude/skills/implement-improvements/SKILL.md) validates each entry against the current codebase, filters stale items, and runs one lane per session: direct entries go through [`/implement`](claude/skills/implement/SKILL.md) for a clear-scope fix, investigate entries run [`/investigate`](claude/skills/investigate/SKILL.md) with [`/consult-codex`](claude/skills/consult-codex/SKILL.md) and then [`/implement`](claude/skills/implement/SKILL.md), and plan entries go through [`/turboplan`](claude/skills/turboplan/SKILL.md).

## Out-of-Loop Pipelines

Two pipelines run alongside the main loop instead of inside it. They are not part of plan-implement-finalize, but they share the same composition style.

### Project-Wide Audit

[`/audit`](claude/skills/audit/SKILL.md) fans out to all analysis skills in parallel (correctness, security, API usage, consistency, simplicity, test coverage, dependencies, tooling, dead code), evaluates the combined findings, and produces a health report at `.turbo/audit.md` with a dashboard and an interactive HTML version. Run it to assess codebase health before a major release, after onboarding to a new project, or on a regular cadence.

[`/audit`](claude/skills/audit/SKILL.md) is analysis-only: it produces the report and stops there. When you're ready to act on findings, use [`/apply-findings`](claude/skills/apply-findings/SKILL.md) or address them manually.

### Developer Onboarding

[`/onboard`](claude/skills/onboard/SKILL.md) generates a comprehensive onboarding guide for new developers joining a project. It composes [`/map-codebase`](claude/skills/map-codebase/SKILL.md) (architecture), [`/review-tooling`](claude/skills/review-tooling/SKILL.md) (development workflow), and [`/review-agentic-setup`](claude/skills/review-agentic-setup/SKILL.md) (AI coding infrastructure) with inline agents for prerequisites, troubleshooting, and next steps (top GitHub issues). The result is `.turbo/onboarding.md` with an interactive HTML version.

The guide covers both traditional onboarding (setup, build commands, tooling) and agentic onboarding (what CLAUDE.md/AGENTS.md cover, installed skills, MCP servers, Claude Code vs Codex CLI compatibility). If a [threat model](#project-wide-audit) exists, security considerations are included too.

[`/map-codebase`](claude/skills/map-codebase/SKILL.md) also works standalone when you just need the architecture report without the full onboarding guide.

## Browser and UI Testing

[`/smoke-test`](claude/skills/smoke-test/SKILL.md) and [`/exploratory-test`](claude/skills/exploratory-test/SKILL.md) (Claude) / [`$smoke-test`](codex/skills/smoke-test/SKILL.md) and [`$exploratory-test`](codex/skills/exploratory-test/SKILL.md) (Codex) automate manual testing — the kind of hands-on verification you'd normally do yourself. The underlying tools differ per edition:

**Claude Code:**

- **[`/agent-browser`](https://github.com/vercel-labs/agent-browser) skill** — Browser automation with the most control for web app testing.
- **`claude-in-chrome` MCP** — Built-in Claude Code browser automation using your real Chrome browser. Falls back to this when `/agent-browser` is not installed.
- **`computer-use` MCP** — Built-in Claude Code screen control for native app and UI testing on macOS.

**Codex:**

- **`browser-use@openai-bundled` plugin** — Browser automation for web app testing. Bundled in Codex's `openai-bundled` marketplace.
- **`computer-use@openai-bundled` plugin** — Screen control for native app and UI testing on macOS. Bundled in Codex's `openai-bundled` marketplace.

## Prompt Examples

These are prompts you can type directly into Claude Code or Codex (use `$skill-name` in Codex). Skill names work as natural words in your sentences.

```
# Planning a change (single entry — /turboplan routes based on complexity)
/turboplan add a caching layer to the image pipeline  ← plan mode → draft → refine → halt; run /implement-plan after
/turboplan build a notification system with backend, API, and UI  ← spec mode → spec → shells → halt
/survey-patterns  ← pattern-ground an approach without drafting a plan
/implement-plan  ← execute the latest plan in .turbo/plans/ in a fresh session

# Continuing a spec-mode project
/pick-next-shell  ← pick next shell → expand → refine → halt; run /implement-plan after

# Investigating bugs
tests are failing in the auth module, can you please /investigate?
/investigate the app crashes when i click "save" after editing a profile

# Reviewing code
/review-code
/review-pr for PR #42

# Auditing project health
/audit
read @.turbo/audit.md and /apply-findings  ← follow-up session

# Onboarding to a new project
/onboard
/map-codebase  ← architecture report only

# Resolving PR feedback
/resolve-pr-comments

# Updating dependencies
/update-dependencies

# Working through the improvements backlog
the error messages in this module are inconsistent, /note-improvement
/implement-improvements  ← dedicated session

# Testing manually
/smoke-test
/exploratory-test

# Picking the next issue to work on
/pick-next-issue

# Extracting session learnings
/self-improve

# Creating a new skill
/create-skill for a skill that <description>
```

## All Skills

For the full skill listing with descriptions and dependencies, see the per-edition index:

- **Claude Code** — [`claude/SKILL-INDEX.md`](claude/SKILL-INDEX.md) (`/skill-name` invocations)
- **Codex** — [`codex/SKILL-INDEX.md`](codex/SKILL-INDEX.md) (`$skill-name` invocations)

## License

Distributed under the MIT License. See the [LICENSE](LICENSE) file for details.
