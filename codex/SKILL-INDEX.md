# Codex Skill Index

Full listing of skills in the Codex edition of Turbo, grouped by category. Skill descriptions are summarized; see each `SKILL.md` for the full description and trigger phrases.

## Pipelines

| Skill | What It Does | Uses |
|---|---|---|
| [`$turboplan`](skills/turboplan/SKILL.md) | Universal planning entry: analyzes complexity and routes to direct, plan, or spec mode | [`$implement`](skills/implement/SKILL.md), [`$draft-plan`](skills/draft-plan/SKILL.md), [`$refine-plan`](skills/refine-plan/SKILL.md), [`$self-improve`](skills/self-improve/SKILL.md), [`$implement-plan`](skills/implement-plan/SKILL.md), [`$draft-spec`](skills/draft-spec/SKILL.md), [`$draft-shells`](skills/draft-shells/SKILL.md), [`$pick-next-shell`](skills/pick-next-shell/SKILL.md) |
| [`$finalize`](skills/finalize/SKILL.md) | Post-implementation QA: polish, changelog, self-improve, commit, PR | [`$polish-code`](skills/polish-code/SKILL.md), [`$update-changelog`](skills/update-changelog/SKILL.md), [`$self-improve`](skills/self-improve/SKILL.md), [`$ship`](skills/ship/SKILL.md), [`$split-and-ship`](skills/split-and-ship/SKILL.md) |
| [`$audit`](skills/audit/SKILL.md) | Project-wide health audit: all analysis skills, evaluation, markdown and HTML report | [`$review-code`](skills/review-code/SKILL.md), [`$peer-review`](skills/peer-review/SKILL.md), [`$review-dependencies`](skills/review-dependencies/SKILL.md), [`$review-tooling`](skills/review-tooling/SKILL.md), [`$review-agentic-setup`](skills/review-agentic-setup/SKILL.md), [`$find-dead-code`](skills/find-dead-code/SKILL.md), [`$create-threat-model`](skills/create-threat-model/SKILL.md), [`$evaluate-findings`](skills/evaluate-findings/SKILL.md), [`$frontend-design`](skills/frontend-design/SKILL.md) |
| [`$onboard`](skills/onboard/SKILL.md) | Developer onboarding guide: architecture, tooling, agentic setup, prerequisites, troubleshooting, next steps | [`$map-codebase`](skills/map-codebase/SKILL.md), [`$review-tooling`](skills/review-tooling/SKILL.md), [`$review-agentic-setup`](skills/review-agentic-setup/SKILL.md), [`$frontend-design`](skills/frontend-design/SKILL.md) |

## Planning

| Skill | What It Does | Uses |
|---|---|---|
| [`$draft-plan`](skills/draft-plan/SKILL.md) | Produces a plan at `.turbo/plans/<slug>.md`: guided discussion then draft | [`$survey-patterns`](skills/survey-patterns/SKILL.md) |
| [`$draft-spec`](skills/draft-spec/SKILL.md) | Guided discussion that produces a spec at `.turbo/specs/<slug>.md` | |
| [`$draft-shells`](skills/draft-shells/SKILL.md) | Decompose a spec into shells with YAML frontmatter and structured wiring invariants (Produces, Consumes, Covers) | |
| [`$expand-shell`](skills/expand-shell/SKILL.md) | Expand a shell with fresh pattern survey, concrete references, and verification | [`$survey-patterns`](skills/survey-patterns/SKILL.md) |
| [`$refine-plan`](skills/refine-plan/SKILL.md) | Iterative review loop over a planning artifact (plan, shells, or spec) until stable: review → evaluate → apply → re-run | [`$review-plan`](skills/review-plan/SKILL.md), [`$evaluate-findings`](skills/evaluate-findings/SKILL.md), [`$apply-findings`](skills/apply-findings/SKILL.md) |
| [`$review-plan`](skills/review-plan/SKILL.md) | Review planning artifacts (plan, shells, or spec): internal review and peer review in parallel | [`$peer-review`](skills/peer-review/SKILL.md) |
| [`$implement-plan`](skills/implement-plan/SKILL.md) | Execute a plan file: pre-implementation prep, hand off to `$implement` | [`$implement`](skills/implement/SKILL.md) |
| [`$pick-next-shell`](skills/pick-next-shell/SKILL.md) | Pick the next shell and carry it through planning and implementation: expand, refine, self-improve, implement | [`$expand-shell`](skills/expand-shell/SKILL.md), [`$refine-plan`](skills/refine-plan/SKILL.md), [`$self-improve`](skills/self-improve/SKILL.md), [`$implement-plan`](skills/implement-plan/SKILL.md) |
| [`$pick-next-issue`](skills/pick-next-issue/SKILL.md) | Pick the most popular open GitHub issue and plan it | [`$turboplan`](skills/turboplan/SKILL.md) |
| [`$survey-patterns`](skills/survey-patterns/SKILL.md) | Survey the codebase for analogous features, reusable utilities, and convention anchors | |

## Code

| Skill | What It Does | Uses |
|---|---|---|
| [`$map-codebase`](skills/map-codebase/SKILL.md) | Deep architecture report: parallel inspections across structure, stack, APIs, patterns, data flow, dependencies, testing | [`$frontend-design`](skills/frontend-design/SKILL.md) |
| [`$create-threat-model`](skills/create-threat-model/SKILL.md) | Analyze a codebase and produce a threat model at `.turbo/threat-model.md` | |
| [`$review-code`](skills/review-code/SKILL.md) | Review code for bugs, security, API usage, consistency, simplicity, or test coverage: internal review(s) and peer review in parallel | [`$peer-review`](skills/peer-review/SKILL.md) |
| [`$find-dead-code`](skills/find-dead-code/SKILL.md) | Identify unused code via parallel analysis | [`$evaluate-findings`](skills/evaluate-findings/SKILL.md), [`$investigate`](skills/investigate/SKILL.md) |
| [`$polish-code`](skills/polish-code/SKILL.md) | Iterative quality loop: stage → format → lint → test → review → evaluate → apply → smoke test → re-run until stable | [`$stage`](skills/stage/SKILL.md), [`$review-code`](skills/review-code/SKILL.md), [`$evaluate-findings`](skills/evaluate-findings/SKILL.md), [`$apply-findings`](skills/apply-findings/SKILL.md), [`$smoke-test`](skills/smoke-test/SKILL.md), [`$investigate`](skills/investigate/SKILL.md) |
| [`$simplify-code`](skills/simplify-code/SKILL.md) | Review code quality and fix issues | |
| [`$simplify-docs`](skills/simplify-docs/SKILL.md) | Review code comments and markdown docs for unnecessary content and fix issues | |
| [`$implement`](skills/implement/SKILL.md) | Standard implementation flow: load code-style rules, make the change, run `$finalize` | [`$code-style`](skills/code-style/SKILL.md), [`$finalize`](skills/finalize/SKILL.md) |
| [`$investigate`](skills/investigate/SKILL.md) | Systematic root cause analysis for bugs and failures | [`$consult-claude`](skills/consult-claude/SKILL.md), [`$evaluate-findings`](skills/evaluate-findings/SKILL.md), [`$consult-oracle`](skills/consult-oracle/SKILL.md) |

## Testing

| Skill | What It Does | Uses |
|---|---|---|
| [`$create-test-plan`](skills/create-test-plan/SKILL.md) | Generate a structured test plan at `.turbo/test-plan.md` with four escalating levels | |
| [`$smoke-test`](skills/smoke-test/SKILL.md) | Launch the app and verify changes manually | `browser-use@openai-bundled` plugin, [`$investigate`](skills/investigate/SKILL.md) |
| [`$exploratory-test`](skills/exploratory-test/SKILL.md) | Multi-level exploratory testing: basic, complex, adversarial, and cross-cutting scenarios | [`$create-test-plan`](skills/create-test-plan/SKILL.md), `browser-use@openai-bundled` plugin, [`$investigate`](skills/investigate/SKILL.md) |

## Dependencies and Tooling

| Skill | What It Does | Uses |
|---|---|---|
| [`$review-dependencies`](skills/review-dependencies/SKILL.md) | Detect outdated or vulnerable dependencies | |
| [`$update-dependencies`](skills/update-dependencies/SKILL.md) | Smart dependency upgrades with breaking change research | [`$review-dependencies`](skills/review-dependencies/SKILL.md) |
| [`$review-tooling`](skills/review-tooling/SKILL.md) | Detect dev tooling gaps across linters, formatters, hooks, test runners, and CI/CD | |
| [`$review-agentic-setup`](skills/review-agentic-setup/SKILL.md) | Detect agentic coding infrastructure: CLAUDE.md, AGENTS.md, skills, MCP, hooks, cross-tool compatibility | |

## Findings

| Skill | What It Does | Uses |
|---|---|---|
| [`$interpret-feedback`](skills/interpret-feedback/SKILL.md) | Parallel internal + Claude interpretation of third-party feedback | [`$peer-review`](skills/peer-review/SKILL.md) |
| [`$evaluate-findings`](skills/evaluate-findings/SKILL.md) | Triage review feedback with adversarial verification | |
| [`$apply-findings`](skills/apply-findings/SKILL.md) | Apply findings from evaluations or reviews | [`$note-improvement`](skills/note-improvement/SKILL.md) |
| [`$resolve-findings`](skills/resolve-findings/SKILL.md) | Choose implementation path (direct or plan) for evaluated findings and dispatch | [`$code-style`](skills/code-style/SKILL.md), [`$apply-findings`](skills/apply-findings/SKILL.md), [`$finalize`](skills/finalize/SKILL.md), [`$turboplan`](skills/turboplan/SKILL.md) |

## Git and GitHub

| Skill | What It Does | Uses |
|---|---|---|
| [`$stage`](skills/stage/SKILL.md) | Stage implementation changes with precise file selection | |
| [`$stage-commit`](skills/stage-commit/SKILL.md) | Stage files and commit in one step | [`$stage`](skills/stage/SKILL.md), [`$commit-staged`](skills/commit-staged/SKILL.md) |
| [`$stage-commit-push`](skills/stage-commit-push/SKILL.md) | Stage, commit, and push in one step | [`$stage-commit`](skills/stage-commit/SKILL.md) |
| [`$commit-staged`](skills/commit-staged/SKILL.md) | Commit already-staged files with good message | [`$commit-rules`](skills/commit-rules/SKILL.md) |
| [`$commit-staged-push`](skills/commit-staged-push/SKILL.md) | Commit already-staged files and push | [`$commit-staged`](skills/commit-staged/SKILL.md) |
| [`$ship`](skills/ship/SKILL.md) | Commit, push, and optionally create or update a PR | [`$commit-staged-push`](skills/commit-staged-push/SKILL.md), [`$create-pr`](skills/create-pr/SKILL.md), [`$update-pr`](skills/update-pr/SKILL.md) |
| [`$split-and-ship`](skills/split-and-ship/SKILL.md) | Ship split plan as separate branches, commits, and PRs | [`$commit-staged-push`](skills/commit-staged-push/SKILL.md), [`$create-pr`](skills/create-pr/SKILL.md), [`$update-pr`](skills/update-pr/SKILL.md) |
| [`$review-pr`](skills/review-pr/SKILL.md) | PR review: fetch comments, detect base branch, run code review, evaluate findings, dispatch to implementation | [`$fetch-pr-comments`](skills/fetch-pr-comments/SKILL.md), [`$review-code`](skills/review-code/SKILL.md), [`$evaluate-findings`](skills/evaluate-findings/SKILL.md), [`$resolve-findings`](skills/resolve-findings/SKILL.md) |
| [`$create-pr`](skills/create-pr/SKILL.md) | Draft and create a GitHub PR | [`$github-voice`](skills/github-voice/SKILL.md) |
| [`$update-pr`](skills/update-pr/SKILL.md) | Update existing PR title and description | [`$github-voice`](skills/github-voice/SKILL.md) |
| [`$fetch-pr-comments`](skills/fetch-pr-comments/SKILL.md) | Read-only summary of unresolved PR comments | |
| [`$resolve-pr-comments`](skills/resolve-pr-comments/SKILL.md) | Evaluate, fix, answer, and reply to PR comments (including reviewer questions) | [`$interpret-feedback`](skills/interpret-feedback/SKILL.md), [`$evaluate-findings`](skills/evaluate-findings/SKILL.md), [`$resolve-findings`](skills/resolve-findings/SKILL.md), [`$answer-reviewer-questions`](skills/answer-reviewer-questions/SKILL.md), [`$reply-to-pr-threads`](skills/reply-to-pr-threads/SKILL.md), [`$reply-to-pr-conversation`](skills/reply-to-pr-conversation/SKILL.md) |
| [`$answer-reviewer-questions`](skills/answer-reviewer-questions/SKILL.md) | Recall implementation reasoning and compose raw answers to reviewer questions | [`$recall-reasoning`](skills/recall-reasoning/SKILL.md) |
| [`$reply-to-pr-threads`](skills/reply-to-pr-threads/SKILL.md) | Draft, confirm, and post PR thread replies; re-fetches resolution state to skip auto-resolved threads | [`$github-voice`](skills/github-voice/SKILL.md) |
| [`$reply-to-pr-conversation`](skills/reply-to-pr-conversation/SKILL.md) | Draft, confirm, and post a single conversational reply to PR issue comments, addressing tracked items as natural prose | [`$github-voice`](skills/github-voice/SKILL.md) |

## External Tools

| Skill | What It Does | Uses |
|---|---|---|
| [`$peer-review`](skills/peer-review/SKILL.md) | Independent peer review via Claude (code, plans, specs, shells, feedback) | [`$claude-print`](skills/claude-print/SKILL.md) |
| [`$consult-claude`](skills/consult-claude/SKILL.md) | Multi-turn consultation with Claude Code | [Claude Code](https://github.com/anthropics/claude-code) |
| [`$consult-oracle`](skills/consult-oracle/SKILL.md) | Consult ChatGPT Pro when completely stuck (requires setup) | [ChatGPT Pro](https://chatgpt.com/) |
| [`$claude-print`](skills/claude-print/SKILL.md) | Non-interactive Claude Code print-mode call from Codex | [Claude Code](https://github.com/anthropics/claude-code) |

## Rules and Style

| Skill | What It Does | Uses |
|---|---|---|
| [`$code-style`](skills/code-style/SKILL.md) | Enforce mirror, reuse, and symmetry principles | |
| [`$frontend-design`](skills/frontend-design/SKILL.md) | Design guidelines for distinctive, production-grade frontend interfaces | |
| [`$github-voice`](skills/github-voice/SKILL.md) | Shared writing style rules for GitHub-facing output (PR comments, descriptions, titles) | |
| [`$commit-rules`](skills/commit-rules/SKILL.md) | Shared commit message rules and technical constraints | |
| [`$changelog-rules`](skills/changelog-rules/SKILL.md) | Shared changelog conventions and formatting rules | |

## Knowledge and Maintenance

| Skill | What It Does | Uses |
|---|---|---|
| [`$self-improve`](skills/self-improve/SKILL.md) | Extract session learnings to CLAUDE.md/AGENTS.md, memory, or skills | |
| [`$note-improvement`](skills/note-improvement/SKILL.md) | Capture out-of-scope improvement ideas to `.turbo/improvements.md` | |
| [`$implement-improvements`](skills/implement-improvements/SKILL.md) | Validate improvements and run one lane per session (direct, investigate, or plan) | [`$implement`](skills/implement/SKILL.md), [`$investigate`](skills/investigate/SKILL.md), [`$turboplan`](skills/turboplan/SKILL.md) |
| [`$recall-reasoning`](skills/recall-reasoning/SKILL.md) | Recall implementation reasoning from past Codex session history for a commit or file location | |
| [`$create-handoff`](skills/create-handoff/SKILL.md) | Write a handoff file at `.turbo/handoff/<YYYY-MM-DD>-<slug>.md` capturing task, status, open decisions, in-flight changes, and next step | |
| [`$explain-this`](skills/explain-this/SKILL.md) | Explain whatever the user is pointing at in plain language: a pending question, code, an error, output, or an artifact | |
| [`$create-skill`](skills/create-skill/SKILL.md) | Create or update a skill with proper structure | [`$evaluate-findings`](skills/evaluate-findings/SKILL.md), [`$apply-findings`](skills/apply-findings/SKILL.md) |
| [`$create-project-skills`](skills/create-project-skills/SKILL.md) | Scan the codebase and generate project-specific skills that capture inferred conventions | [`$create-skill`](skills/create-skill/SKILL.md) |
| [`$update-turbo`](skills/update-turbo/SKILL.md) | Update Turbo Codex skills with always-latest instructions fetched from GitHub | |
| [`$migrate-turbo-files`](skills/migrate-turbo-files/SKILL.md) | Migrate legacy files in `.turbo/` to current formats (plans/shells layout, improvements.md Type values) | |
| [`$contribute-turbo`](skills/contribute-turbo/SKILL.md) | Submit turbo skill improvements back to upstream | [`$commit-rules`](skills/commit-rules/SKILL.md), [`$github-voice`](skills/github-voice/SKILL.md) |
| [`$create-changelog`](skills/create-changelog/SKILL.md) | Create a CHANGELOG.md with version history backfilled from GitHub releases or git tags | [`$changelog-rules`](skills/changelog-rules/SKILL.md) |
| [`$update-changelog`](skills/update-changelog/SKILL.md) | Update the Unreleased section of CHANGELOG.md based on current changes (no-op if no changelog) | [`$changelog-rules`](skills/changelog-rules/SKILL.md) |
