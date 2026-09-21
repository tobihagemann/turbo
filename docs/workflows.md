# Workflows

[← Back to Turbo](../README.md) · [Prompt examples](examples.md) · [Requirements](requirements.md) · [Customization](customization.md)

Start with `/turboplan`, implement the agreed change, then finalize. The sections below explain the routes, review loops, and supporting workflows. Examples use Claude Code syntax; use `$skill-name` in Codex. Each edition’s skill index ([Claude Code](../claude/SKILL-INDEX.md), [Codex](../codex/SKILL-INDEX.md)) links to its implementation.

## The Turboplan Pipeline

Claude Code's built-in plan mode tends to produce plans that miss existing patterns, skip edge cases, or propose approaches that don't hold up under scrutiny, and it can feel too restrictive for iterative planning. Turbo replaces it with [`/turboplan`](../claude/skills/turboplan/SKILL.md) as a universal entry point: whatever the size of the task, you start there. It analyzes the task, routes it through the right pipeline, and produces plans that survive contact with reality, with no need for plan mode to be active. Direct work chains through [`/discuss-change`](../claude/skills/discuss-change/SKILL.md) and [`/implement`](../claude/skills/implement/SKILL.md) to [`/finalize`](../claude/skills/finalize/SKILL.md); plan-mode work halts once for a fresh [`/implement-plan`](../claude/skills/implement-plan/SKILL.md) session.

![How Turboplan Connects](../assets/how-turboplan-connects.svg)

[`/turboplan`](../claude/skills/turboplan/SKILL.md) has two modes, named by what each one produces. Its complexity analysis recommends a mode, then you confirm the route:

- **Direct mode** — Clear scope, with any remaining decisions small enough to settle in conversation. Hands off to [`/discuss-change`](../claude/skills/discuss-change/SKILL.md), which escalates open product decisions, agrees the implementation shape with you, then runs [`/implement`](../claude/skills/implement/SKILL.md), which loads [`/code-style`](../claude/skills/code-style/SKILL.md) plus any task-specific skills, applies the change, smoke tests any UI/UX change and previews it for you to try, and offers [`/finalize`](../claude/skills/finalize/SKILL.md), a quick close, or stopping. No plan file is written.
- **Plan mode** — The approach warrants writing down before implementing, however large the work turns out to be. Runs [`/draft-plan`](../claude/skills/draft-plan/SKILL.md) (survey + consult skills/docs + escalate + discuss + draft) → [`/refine-plan`](../claude/skills/refine-plan/SKILL.md) → [`/self-improve`](../claude/skills/self-improve/SKILL.md). Halts after self-improve; you run [`/implement-plan`](../claude/skills/implement-plan/SKILL.md) in a fresh session.

A plan states the deployment's bounds and, where the change has observable behavior, its acceptance criteria alongside the implementation steps. That gives [`/review-plan`](../claude/skills/review-plan/SKILL.md) something concrete to judge proportionality against, so it can tell machinery the system needs from machinery it doesn't. [`/draft-plan`](../claude/skills/draft-plan/SKILL.md) also takes a background document — a design doc, an issue, a written proposal — and treats decisions that document already settles as answered, while still confirming the deployment's bounds with you.

Some questions can't be settled in prose: what a surface looks like, whether an interaction reads the way you expect. Both lanes offer [`/prototype`](../claude/skills/prototype/SKILL.md) when a discussion question turns on one of those. It builds a self-contained page under `.turbo/prototypes/`, drives every control itself, and hands you the file to try, so the decisions that follow rest on something you've used instead of on faith. The approval gates in [`/draft-plan`](../claude/skills/draft-plan/SKILL.md) and [`/discuss-change`](../claude/skills/discuss-change/SKILL.md) offer the same path for an unknown you only spot when you read the summary.

Every sub-skill works standalone too. Run [`/draft-plan`](../claude/skills/draft-plan/SKILL.md) directly if you want to draft a plan without the rest of the pipeline. Run [`/refine-plan`](../claude/skills/refine-plan/SKILL.md) on a plan you wrote yourself. Run [`/implement-plan`](../claude/skills/implement-plan/SKILL.md) in a fresh session on any plan file.

## The Finalize Pipeline

[`/finalize`](../claude/skills/finalize/SKILL.md) is the QA and commit side of the loop. Run it when you're done implementing, or let [`/implement`](../claude/skills/implement/SKILL.md) / [`/implement-plan`](../claude/skills/implement-plan/SKILL.md) chain into it automatically once a plan file's steps are done. Without a plan file, `/implement` asks first, offering [`/quick-finalize`](../claude/skills/quick-finalize/SKILL.md) as a quick close or stopping instead. One command runs tests, iterative code polishing, documentation cleanup, changelog updates, self-improvement, and commit.

![How Finalize Connects](../assets/how-finalize-connects.svg)

`/finalize` runs through these phases automatically:

1. **Polish Code** — Iterative loop: stage → format → lint → test → review → evaluate → apply → smoke test → re-run until stable
2. **Simplify Docs** — Strip unnecessary comments and documentation noise from the changed files
3. **Update Changelog** — Add entries to the Unreleased section of CHANGELOG.md (skipped if no changelog exists)
4. **Self-Improve** — Extract learnings, route to CLAUDE.md / AGENTS.md / memory / skills
5. **Ship It** — Branch if needed, commit, push, create or update PR

[`/quick-finalize`](../claude/skills/quick-finalize/SKILL.md) is the sibling for changes that don't warrant the deep review loop. It stages, simplifies code and docs, runs the project's checks via [`/run-checks`](../claude/skills/run-checks/SKILL.md), smoke tests, updates the changelog, self-improves, and ships. Same close-out, without the iterative bug hunt.

## Self-Improvement

[`/self-improve`](../claude/skills/self-improve/SKILL.md) makes each session teach the next. Run it anytime before ending your session (it's also part of [`/finalize`](../claude/skills/finalize/SKILL.md) Phase 4). It scans the conversation for corrections, repeated guidance, failure modes, and preferences, then routes each lesson to the right place: project `CLAUDE.md`/`AGENTS.md`, auto memory, or existing/new skills. Ask it to distill past sessions and it sweeps the project's earlier transcripts instead, skipping what a previous run already covered and treating guidance repeated across sessions as a documentation gap rather than one-off steering. Over time, Turbo gets better at your specific project.

[`/note-improvement`](../claude/skills/note-improvement/SKILL.md) captures improvement opportunities that surface during work but fall out of scope: review findings you skipped, refactoring ideas, missing tests, and deliberate simplifications that accept a known ceiling. They're tracked in `.turbo/improvements.md` (gitignored, so they don't clutter the repo), each tagged `direct`, `investigate`, or `plan` for later routing.

When you're ready to act, [`/implement-improvements`](../claude/skills/implement-improvements/SKILL.md) validates each entry against the current codebase, drops stale ones, and runs one lane per session:

- **`direct`** → [`/implement`](../claude/skills/implement/SKILL.md) for a clear-scope fix
- **`investigate`** → [`/investigate`](../claude/skills/investigate/SKILL.md), then [`/implement`](../claude/skills/implement/SKILL.md)
- **`plan`** → [`/turboplan`](../claude/skills/turboplan/SKILL.md)

## Out-of-Loop Pipelines

Two pipelines run alongside the main loop rather than inside it. They share the same composition style as the plan-implement-finalize core.

### Project-Wide Audit

[`/audit`](../claude/skills/audit/SKILL.md) fans out to all analysis skills in parallel (correctness, security, API usage, consistency, simplicity, test coverage, dependencies, tooling, dead code, agentic setup), evaluates the combined findings, and produces a health report at `.turbo/audit.md` with a dashboard and an interactive HTML version. Run it to assess codebase health before a major release, after onboarding to a new project, or on a regular cadence.

[`/audit`](../claude/skills/audit/SKILL.md) is analysis-only: it produces the report and stops there. When you're ready to act on findings, use [`/apply-findings`](../claude/skills/apply-findings/SKILL.md) or address them manually.

### Developer Onboarding

[`/onboard`](../claude/skills/onboard/SKILL.md) generates a comprehensive onboarding guide for new developers joining a project. It composes [`/map-codebase`](../claude/skills/map-codebase/SKILL.md) (architecture), [`/review-tooling`](../claude/skills/review-tooling/SKILL.md) (development workflow), and [`/review-agentic-setup`](../claude/skills/review-agentic-setup/SKILL.md) (AI coding infrastructure) with inline agents for prerequisites, troubleshooting, and next steps (top GitHub issues). The result is `.turbo/onboarding.md` with an interactive HTML version.

The guide covers both traditional onboarding (setup, build commands, tooling) and agentic onboarding (what CLAUDE.md/AGENTS.md cover, installed skills, MCP servers, Claude Code vs Codex CLI compatibility). If a [threat model](../claude/skills/create-threat-model/SKILL.md) exists, security considerations are included too.

[`/map-codebase`](../claude/skills/map-codebase/SKILL.md) also works standalone when you just need the architecture report without the full onboarding guide.

## Browser and UI Testing

[`/smoke-test`](../claude/skills/smoke-test/SKILL.md) and [`/exploratory-test`](../claude/skills/exploratory-test/SKILL.md) (Claude) / [`$smoke-test`](../codex/skills/smoke-test/SKILL.md) and [`$exploratory-test`](../codex/skills/exploratory-test/SKILL.md) (Codex) automate manual testing — the kind of hands-on verification you'd normally do yourself. See [Browser and UI Testing Tools](requirements.md#browser-and-ui-testing-tools) for what drives them in each edition.

For changes where you want to judge the feel yourself, [`/preview`](../claude/skills/preview/SKILL.md) / [`$preview`](../codex/skills/preview/SKILL.md) stands up the live app and hands it to you to try a UI/UX change firsthand, then waits for your verdict before continuing. `/implement` runs it automatically before `/finalize` when a change touches a user-facing surface, after `/smoke-test` has driven the flow and cleared what it could, so the app is already working when it reaches you. You can run it standalone any time you want to poke at the running app.
