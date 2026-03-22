# Turbo

A composable dev process for [Claude Code](https://docs.anthropic.com/en/docs/claude-code), packaged as modular skills. Each skill encodes a dev workflow so you can run it instead of prompting from scratch. Battle-tested with the Opus model.

**TL;DR** — Three steps to ship:

1. **Plan** — Enter plan mode and describe what you want to build
2. **Implement** — Build it with Claude
3. **Run [`/finalize`](skills/finalize/SKILL.md)** — Tests, iterative code polishing, commit, and PR. One command.

Everything else in Turbo builds on this loop: planning pipelines for large projects, debugging tools for when things break, and self-improvement that makes each session teach the next. There are [40+ skills](#all-skills) beyond [`/finalize`](skills/finalize/SKILL.md). Read on for the full picture.

## What Is This?

Turbo covers the full dev lifecycle: reviewing code, creating PRs, investigating bugs, self-improving from session learnings, and more.

Five ideas shape the design:

1. **Standardized process.** Skills capture dev workflows so you can run them directly instead of prompting from scratch. [`/finalize`](skills/finalize/SKILL.md) runs your entire post-implementation QA in one command. [`/investigate`](skills/investigate/SKILL.md) follows a structured root cause analysis cycle. The skill is the prompt.
2. **Layered design.** Skills range from focused tools ([`/code-review`](skills/code-review/SKILL.md) analyzes a diff) to orchestrators that compose them ([`/review-code`](skills/review-code/SKILL.md) chains code review, peer review, security review, API usage review, and evaluation; [`/polish-code`](skills/polish-code/SKILL.md) loops simplify → review → test → lint until stable). They [work together](#how-skills-connect) with a natural, predictable interface.
3. **Swappable by design.** Every skill owns one concern and communicates through standard interfaces. Replace any piece with your own and the pipeline adapts. See [The Puzzle Piece Philosophy](#the-puzzle-piece-philosophy) for details.
4. **Works out of the box.** Install the skills and the full workflow is ready. Dependencies are standard dev tooling (GitHub CLI, Codex) that most teams already have.
5. **Just skills.** No framework, no custom runtime, no new memory system. Skills are plain markdown that use Claude Code's native primitives (git, filesystem, built-in tools). Remove an independent skill and the rest still work.

The one thing beyond skills is [`CLAUDE-ADDITIONS.md`](CLAUDE-ADDITIONS.md), a small set of behavioral rules added to `~/.claude/CLAUDE.md` during setup. The most important one is **Skill Loading**: without it, Claude tends to skip reloading skills it has already seen in a session, which causes it to silently drop steps in nested pipelines like [`/finalize`](skills/finalize/SKILL.md). The additions are kept in sync by [`/update-turbo`](skills/update-turbo/SKILL.md). See [docs/skill-loading-reasoning.md](docs/skill-loading-reasoning.md) for the full rationale.

The other core piece is [`/self-improve`](skills/self-improve/SKILL.md), which makes the whole system compound. After each session, it extracts lessons from the conversation and routes them to the right place: project CLAUDE.md, auto memory, or existing/new skills. Every session teaches Claude something, and future sessions benefit.

## How Skills Connect

This diagram shows how [`/finalize`](skills/finalize/SKILL.md) orchestrates its pipeline and how the key sub-skills compose. It covers the core workflow, not every skill in Turbo. See [All Skills](#all-skills) for the full list.

![How Skills Connect](assets/how-skills-connect.svg)

## Works Best With

Turbo amplifies your existing process. It shines when your project has the right infrastructure in place:

- **Tests** — [`/finalize`](skills/finalize/SKILL.md) runs your test suite and writes missing tests. Without tests, there's no safety net. If your project doesn't have automated tests, [`/smoke-test`](skills/smoke-test/SKILL.md) (standalone skill, not part of [`/finalize`](skills/finalize/SKILL.md)) can fill the gap by launching your app and verifying changes manually, but real tests are always better.
- **Linters and formatters** — [`/finalize`](skills/finalize/SKILL.md) runs your linter after code review fixes. If you don't have one, style issues slip through.
- **Dead code analysis** — [`/find-dead-code`](skills/find-dead-code/SKILL.md) (standalone skill, not part of [`/finalize`](skills/finalize/SKILL.md)) identifies unused code via parallel analysis, but it's even better when your project already has tools like `knip`, `vulture`, or `periphery` integrated.
- **Dependencies** — [GitHub CLI](https://cli.github.com/) and [Codex CLI](https://github.com/openai/codex) power PR operations and peer review. Everything works without them, but the full pipeline is better with them. See the [manual setup guide](docs/manual-setup.md#5-install-prerequisites) for details.

## Who It's For

The target audience is experienced developers who want to move faster without sacrificing quality. That said, beginners are welcome too. Turbo is a great way to learn how a professional dev workflow looks. Just don't blindly trust outputs. Review what Claude produces, understand _why_ it made those choices, and build your own judgment alongside it.

If your plan is vague, your architecture is unclear, and you skip every review finding, Turbo won't save you. Garbage in, garbage out.

## The Puzzle Piece Philosophy

Every skill is a self-contained piece. Orchestrator skills like [`/finalize`](skills/finalize/SKILL.md) compose them into workflows, but each piece works independently too.

Want to swap a piece? For example:

- Replace [`/oracle`](skills/oracle/SKILL.md) with your own setup (it's macOS-only and has a cookies workaround)
- Replace [`/commit-rules`](skills/commit-rules/SKILL.md) with your team's commit convention. The pipeline adapts.
- Replace [`/code-style`](skills/code-style/SKILL.md) with your team's style guide. The built-in one teaches general principles rather than opinionated rules, so it's a natural swap point.

This is also why similar-sounding skills like [`/code-review`](skills/code-review/SKILL.md) and [`/review-code`](skills/review-code/SKILL.md) both exist. [`/code-review`](skills/code-review/SKILL.md) analyzes a diff and returns structured findings. [`/review-code`](skills/review-code/SKILL.md) is an orchestrator that composes [`/code-review`](skills/code-review/SKILL.md), [`/peer-review`](skills/peer-review/SKILL.md), [`/security-review`](skills/security-review/SKILL.md), and [`/api-usage-review`](skills/api-usage-review/SKILL.md) into a full pipeline with evaluation. Run the piece when you want a scan. Run the orchestrator when you want the whole review.

Skills communicate through standard interfaces: git staging area, PR state, and file conventions.

## Sponsorship

If Turbo has helped you ship faster and you're so inclined, I'd greatly appreciate it if you'd consider [sponsoring my open source work](https://github.com/sponsors/tobihagemann).


## Quick Start

### Prerequisites

Turbo requires [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Works best with Claude Code Max 5x, Max 20x, or Team plan with Premium seats (orchestrator workflows are context-heavy). Additional tools are installed during setup.

**External services:** ChatGPT Plus or higher (for codex review), and ChatGPT Pro or Business (for [`/oracle`](skills/oracle/SKILL.md), where Pro models are the only ones that reliably solve very hard problems). That said, [`/peer-review`](skills/peer-review/SKILL.md) and [`/oracle`](skills/oracle/SKILL.md) are designed as swappable puzzle pieces, so if you don't have access, replace them with alternatives that work for you.

### Automatic Setup (Recommended)

Open Claude Code and prompt:

```
Walk me through the Turbo setup. Read SETUP.md from the tobihagemann/turbo repo and guide me through each step.
```

Claude will clone the repo, copy the skills, configure your environment, and walk you through each step interactively.

### Updating

Run [`/update-turbo`](skills/update-turbo/SKILL.md) in Claude Code to update all skills. It fetches the latest update instructions from GitHub, builds a changelog, handles conflict detection for customized skills, and manages exclusions.

### Manual Setup

See the [manual setup guide](docs/manual-setup.md) for step-by-step instructions.

## The Main Workflow

The recommended way to use Turbo:

1. **Enter plan mode** and plan the implementation
2. **Approve the plan**
3. **Run [`/finalize`](skills/finalize/SKILL.md)** when you're done implementing

[`/finalize`](skills/finalize/SKILL.md) runs through these phases automatically:

1. **Write Missing Tests** — Analyze changes and write tests matching project conventions
2. **Polish Code** — Iterative loop: stage → simplify → review + fix → test → lint → re-run until stable
3. **Self-Improve** — Extract learnings, route to CLAUDE.md / memory / skills
4. **Commit and PR** — Branch if needed, commit, push, create or update PR

### Self-Improvement

[`/self-improve`](skills/self-improve/SKILL.md) is another core skill. Run it anytime before ending your session (it's also part of [`/finalize`](skills/finalize/SKILL.md) Phase 4). It scans the conversation for corrections, repeated guidance, failure modes, and preferences, then routes each lesson to the right place: project CLAUDE.md, auto memory, or existing/new skills. It routes lessons through Claude Code's built-in knowledge layers and, over time, makes Claude better at your specific project.

[`/note-improvement`](skills/note-improvement/SKILL.md) captures improvement opportunities that come up during work but are out of scope: code review findings you chose to skip, refactoring ideas, missing tests. These get tracked in `.turbo/improvements.md` so they don't get lost. Since `.turbo/` is gitignored, it doesn't clutter the repo. When you're ready to act on them, [`/implement-improvements`](skills/implement-improvements/SKILL.md) validates each entry against the current codebase (filtering out stale items), then plans and implements the remaining ones.

## The Planning Pipeline (Optional)

For larger projects, Turbo offers a full spec-to-implementation pipeline. You can skip this entirely and jump straight to implementation + [`/finalize`](skills/finalize/SKILL.md).

1. **Run [`/create-spec`](skills/create-spec/SKILL.md)** — Guided discussion that produces a spec at `.turbo/spec.md`
2. **Run [`/create-prompt-plan`](skills/create-prompt-plan/SKILL.md)** — Breaks the spec into context-sized prompts at `.turbo/prompts.md`
3. **For each prompt, open a new session:** enter plan mode and run [`/pick-next-prompt`](skills/pick-next-prompt/SKILL.md), then approve the plan

[`/pick-next-prompt`](skills/pick-next-prompt/SKILL.md) uses [`/plan-style`](skills/plan-style/SKILL.md), which includes implementation and [`/finalize`](skills/finalize/SKILL.md) in the plan.

Each session handles one prompt to keep context focused.

## All Skills

### Workflows

| Skill | What it does | Uses |
|---|---|---|
| [`/finalize`](skills/finalize/SKILL.md) | Post-implementation QA: test, polish, commit, PR | [`/write-tests`](skills/write-tests/SKILL.md), [`/polish-code`](skills/polish-code/SKILL.md), [`/self-improve`](skills/self-improve/SKILL.md), [`/commit-staged`](skills/commit-staged/SKILL.md), [`/create-pr`](skills/create-pr/SKILL.md), [`/update-pr`](skills/update-pr/SKILL.md), [`/resolve-pr-comments`](skills/resolve-pr-comments/SKILL.md) |

### Planning

| Skill | What it does | Uses |
|---|---|---|
| [`/create-spec`](skills/create-spec/SKILL.md) | Guided discussion that produces a spec at `.turbo/spec.md` | |
| [`/create-prompt-plan`](skills/create-prompt-plan/SKILL.md) | Break a spec into context-sized implementation prompts | [`/evaluate-findings`](skills/evaluate-findings/SKILL.md) |
| [`/pick-next-prompt`](skills/pick-next-prompt/SKILL.md) | Pick the next prompt from `.turbo/prompts.md` and plan it | [`/plan-style`](skills/plan-style/SKILL.md) |
| [`/pick-next-issue`](skills/pick-next-issue/SKILL.md) | Pick the most popular open GitHub issue and plan it | [`/plan-style`](skills/plan-style/SKILL.md) |
| [`/plan-style`](skills/plan-style/SKILL.md) | Planning conventions for task tracking, skill loading, and finalization | |
| [`/capture-context`](skills/capture-context/SKILL.md) | Capture session knowledge into the plan file before clearing context | |

### Code Quality

| Skill | What it does | Uses |
|---|---|---|
| [`/polish-code`](skills/polish-code/SKILL.md) | Iterative quality loop: stage → simplify → review + fix → test → lint → re-run until stable | [`/stage`](skills/stage/SKILL.md), [`/simplify-code`](skills/simplify-code/SKILL.md), [`/review-code`](skills/review-code/SKILL.md), [`/investigate`](skills/investigate/SKILL.md) |
| [`/code-style`](skills/code-style/SKILL.md) | Enforce mirror, reuse, and symmetry principles | |
| [`/frontend-design`](skills/frontend-design/SKILL.md) | Design guidelines for distinctive, production-grade frontend interfaces | |
| [`/simplify-code`](skills/simplify-code/SKILL.md) | Multi-agent review for reuse, quality, efficiency, clarity | |
| [`/write-tests`](skills/write-tests/SKILL.md) | Write missing tests matching project conventions | [`/investigate`](skills/investigate/SKILL.md) |

### Review

| Skill | What it does | Uses |
|---|---|---|
| [`/review-code`](skills/review-code/SKILL.md) | AI code review: 4 parallel reviewers + evaluation | [`/code-review`](skills/code-review/SKILL.md), [`/peer-review`](skills/peer-review/SKILL.md), [`/security-review`](skills/security-review/SKILL.md), [`/api-usage-review`](skills/api-usage-review/SKILL.md), [`/evaluate-findings`](skills/evaluate-findings/SKILL.md) |
| [`/review-pr`](skills/review-pr/SKILL.md) | PR review: fetch comments, detect base branch, run code review | [`/fetch-pr-comments`](skills/fetch-pr-comments/SKILL.md), [`/review-code`](skills/review-code/SKILL.md) |
| [`/code-review`](skills/code-review/SKILL.md) | AI code review analysis with structured findings | |
| [`/security-review`](skills/security-review/SKILL.md) | Security-focused code review with threat model integration | |
| [`/peer-review`](skills/peer-review/SKILL.md) | AI code review interface that delegates to [`/codex`](skills/codex/SKILL.md) by default | [`/codex`](skills/codex/SKILL.md) |
| [`/api-usage-review`](skills/api-usage-review/SKILL.md) | Check API/library usage against official documentation | |
| [`/evaluate-findings`](skills/evaluate-findings/SKILL.md) | Confidence-based triage of review feedback | |
| [`/find-dead-code`](skills/find-dead-code/SKILL.md) | Identify unused code via parallel analysis | [`/evaluate-findings`](skills/evaluate-findings/SKILL.md), [`/investigate`](skills/investigate/SKILL.md) |
| [`/create-threat-model`](skills/create-threat-model/SKILL.md) | Analyze a codebase and produce a threat model at `.turbo/threat-model.md` | |

### Git & GitHub

| Skill | What it does | Uses |
|---|---|---|
| [`/stage`](skills/stage/SKILL.md) | Stage implementation changes with precise file selection | |
| [`/stage-commit`](skills/stage-commit/SKILL.md) | Stage files and commit in one step | [`/stage`](skills/stage/SKILL.md), [`/commit-staged`](skills/commit-staged/SKILL.md) |
| [`/stage-commit-push`](skills/stage-commit-push/SKILL.md) | Stage, commit, and push in one step | [`/stage-commit`](skills/stage-commit/SKILL.md) |
| [`/commit-staged`](skills/commit-staged/SKILL.md) | Commit already-staged files with good message | [`/commit-rules`](skills/commit-rules/SKILL.md) |
| [`/commit-staged-push`](skills/commit-staged-push/SKILL.md) | Commit already-staged files and push | [`/commit-staged`](skills/commit-staged/SKILL.md) |
| [`/commit-rules`](skills/commit-rules/SKILL.md) | Shared commit message rules and technical constraints | |
| [`/create-pr`](skills/create-pr/SKILL.md) | Draft and create a GitHub PR | [`/github-voice`](skills/github-voice/SKILL.md) |
| [`/update-pr`](skills/update-pr/SKILL.md) | Update existing PR title and description | [`/github-voice`](skills/github-voice/SKILL.md) |
| [`/fetch-pr-comments`](skills/fetch-pr-comments/SKILL.md) | Read-only summary of unresolved PR comments | |
| [`/resolve-pr-comments`](skills/resolve-pr-comments/SKILL.md) | Evaluate, fix, and reply to PR comments | [`/evaluate-findings`](skills/evaluate-findings/SKILL.md), [`/self-improve`](skills/self-improve/SKILL.md), [`/stage-commit-push`](skills/stage-commit-push/SKILL.md), [`/github-voice`](skills/github-voice/SKILL.md) |

### External AI

| Skill | What it does | Uses |
|---|---|---|
| [`/codex`](skills/codex/SKILL.md) | AI code review and task execution via codex CLI | [Codex CLI](https://github.com/openai/codex) |
| [`/oracle`](skills/oracle/SKILL.md) | Consult ChatGPT when completely stuck (requires setup) | [ChatGPT Pro](https://chatgpt.com/) |

### Debugging

| Skill | What it does | Uses |
|---|---|---|
| [`/investigate`](skills/investigate/SKILL.md) | Systematic root cause analysis for bugs and failures | [`/codex`](skills/codex/SKILL.md), [`/evaluate-findings`](skills/evaluate-findings/SKILL.md), [`/oracle`](skills/oracle/SKILL.md) |
| [`/smoke-test`](skills/smoke-test/SKILL.md) | Launch the app and verify changes manually | [`/investigate`](skills/investigate/SKILL.md) |

### Knowledge & Maintenance

| Skill | What it does | Uses |
|---|---|---|
| [`/self-improve`](skills/self-improve/SKILL.md) | Extract session learnings to CLAUDE.md, memory, or skills | |
| [`/note-improvement`](skills/note-improvement/SKILL.md) | Capture out-of-scope improvement ideas to `.turbo/improvements.md` | |
| [`/implement-improvements`](skills/implement-improvements/SKILL.md) | Validate and implement improvements from the backlog | [`/plan-style`](skills/plan-style/SKILL.md) |
| [`/create-skill`](skills/create-skill/SKILL.md) | Create or update a skill with proper structure | |
| [`/update-deps`](skills/update-deps/SKILL.md) | Smart dependency upgrades with breaking change research | |
| [`/update-turbo`](skills/update-turbo/SKILL.md) | Update Turbo skills with always-latest instructions fetched from GitHub | |
| [`/contribute-turbo`](skills/contribute-turbo/SKILL.md) | Submit turbo skill improvements back to upstream | [`/commit-rules`](skills/commit-rules/SKILL.md), [`/github-voice`](skills/github-voice/SKILL.md) |

## License

Distributed under the MIT License. See the [LICENSE](LICENSE) file for details.
