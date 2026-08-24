# Codex Skill Index

Full listing of skills in the Codex edition of Turbo, grouped by category. Skill descriptions are summarized; see each `SKILL.md` for the full description and trigger phrases.

## Pipelines

| Skill | What It Does | Uses | Used By |
|---|---|---|---|
| [`$turboplan`](skills/turboplan/SKILL.md) | Universal planning entry: analyzes complexity and routes to direct or plan mode | [`$discuss-change`](skills/discuss-change/SKILL.md), [`$draft-plan`](skills/draft-plan/SKILL.md), [`$refine-plan`](skills/refine-plan/SKILL.md), [`$self-improve`](skills/self-improve/SKILL.md), [`$implement-plan`](skills/implement-plan/SKILL.md), [`$consult-claude`](skills/consult-claude/SKILL.md) | [`$pick-next-issue`](skills/pick-next-issue/SKILL.md), [`$resolve-findings`](skills/resolve-findings/SKILL.md), [`$implement-improvements`](skills/implement-improvements/SKILL.md) |
| [`$finalize`](skills/finalize/SKILL.md) | Post-implementation QA: polish, changelog, self-improve, commit, PR | [`$polish-code`](skills/polish-code/SKILL.md), [`$simplify-docs`](skills/simplify-docs/SKILL.md), [`$update-changelog`](skills/update-changelog/SKILL.md), [`$self-improve`](skills/self-improve/SKILL.md), [`$ship`](skills/ship/SKILL.md), [`$split-and-ship`](skills/split-and-ship/SKILL.md) | [`$implement`](skills/implement/SKILL.md), [`$resolve-findings`](skills/resolve-findings/SKILL.md) |
| [`$audit`](skills/audit/SKILL.md) | Project-wide health audit: all analysis skills, evaluation, markdown and HTML report | [`$review-code`](skills/review-code/SKILL.md), [`$peer-review`](skills/peer-review/SKILL.md), [`$review-dependencies`](skills/review-dependencies/SKILL.md), [`$review-tooling`](skills/review-tooling/SKILL.md), [`$review-agentic-setup`](skills/review-agentic-setup/SKILL.md), [`$find-dead-code`](skills/find-dead-code/SKILL.md), [`$create-threat-model`](skills/create-threat-model/SKILL.md), [`$evaluate-findings`](skills/evaluate-findings/SKILL.md), [`$frontend-design`](skills/frontend-design/SKILL.md) | |
| [`$onboard`](skills/onboard/SKILL.md) | Developer onboarding guide: architecture, tooling, agentic setup, prerequisites, troubleshooting, next steps | [`$map-codebase`](skills/map-codebase/SKILL.md), [`$review-tooling`](skills/review-tooling/SKILL.md), [`$review-agentic-setup`](skills/review-agentic-setup/SKILL.md), [`$frontend-design`](skills/frontend-design/SKILL.md) | |

## Planning

| Skill | What It Does | Uses | Used By |
|---|---|---|---|
| [`$discuss-change`](skills/discuss-change/SKILL.md) | Short alignment interview with no plan file: escalate open decisions, confirm the shape, then implement | [`$implement`](skills/implement/SKILL.md), [`$prototype`](skills/prototype/SKILL.md), [`$consult-claude`](skills/consult-claude/SKILL.md) | [`$turboplan`](skills/turboplan/SKILL.md) |
| [`$draft-plan`](skills/draft-plan/SKILL.md) | Produces a plan at `.turbo/plans/<slug>.md`: guided discussion then draft | [`$survey-patterns`](skills/survey-patterns/SKILL.md), [`$prototype`](skills/prototype/SKILL.md), [`$consult-claude`](skills/consult-claude/SKILL.md) | [`$turboplan`](skills/turboplan/SKILL.md) |
| [`$refine-plan`](skills/refine-plan/SKILL.md) | Iterative review loop over a plan until stable: review → evaluate → apply → re-run | [`$review-plan`](skills/review-plan/SKILL.md), [`$evaluate-findings`](skills/evaluate-findings/SKILL.md), [`$apply-findings`](skills/apply-findings/SKILL.md) | [`$turboplan`](skills/turboplan/SKILL.md) |
| [`$review-plan`](skills/review-plan/SKILL.md) | Review a plan: internal reviews and peer review in parallel | [`$peer-review`](skills/peer-review/SKILL.md) | [`$refine-plan`](skills/refine-plan/SKILL.md) |
| [`$implement-plan`](skills/implement-plan/SKILL.md) | Execute a plan file: pre-implementation prep, hand off to `$implement` | [`$implement`](skills/implement/SKILL.md) | [`$turboplan`](skills/turboplan/SKILL.md) |
| [`$pick-next-issue`](skills/pick-next-issue/SKILL.md) | Pick the most popular open GitHub issue and plan it | [`$turboplan`](skills/turboplan/SKILL.md) | |
| [`$survey-patterns`](skills/survey-patterns/SKILL.md) | Survey the codebase and any named external source for analogous features, reusable utilities, and convention anchors | | [`$draft-plan`](skills/draft-plan/SKILL.md) |
| [`$prototype`](skills/prototype/SKILL.md) | Build a self-contained prototype at `.turbo/prototypes/<slug>.html`, drive it, and hand it over to settle what prose cannot | `browser-use@openai-bundled` plugin | [`$draft-plan`](skills/draft-plan/SKILL.md), [`$discuss-change`](skills/discuss-change/SKILL.md) |

## Code

| Skill | What It Does | Uses | Used By |
|---|---|---|---|
| [`$map-codebase`](skills/map-codebase/SKILL.md) | Deep architecture report: parallel inspections across structure, stack, APIs, patterns, data flow, dependencies, testing | [`$frontend-design`](skills/frontend-design/SKILL.md) | [`$onboard`](skills/onboard/SKILL.md) |
| [`$create-threat-model`](skills/create-threat-model/SKILL.md) | Analyze a codebase and produce a threat model at `.turbo/threat-model.md` | | [`$audit`](skills/audit/SKILL.md) |
| [`$review-code`](skills/review-code/SKILL.md) | Review code for bugs, security, API usage, consistency, simplicity, or test coverage: internal review(s) and peer review in parallel | [`$peer-review`](skills/peer-review/SKILL.md) | [`$audit`](skills/audit/SKILL.md), [`$polish-code`](skills/polish-code/SKILL.md), [`$review-pr`](skills/review-pr/SKILL.md) |
| [`$find-dead-code`](skills/find-dead-code/SKILL.md) | Identify unused code via parallel analysis | [`$evaluate-findings`](skills/evaluate-findings/SKILL.md), [`$investigate`](skills/investigate/SKILL.md) | [`$audit`](skills/audit/SKILL.md) |
| [`$assess-technical-debt`](skills/assess-technical-debt/SKILL.md) | Assess structural debt (complexity, deprecated APIs, duplication, architecture rot), ranked by impact and effort, markdown and HTML report | [`$evaluate-findings`](skills/evaluate-findings/SKILL.md), [`$frontend-design`](skills/frontend-design/SKILL.md) | |
| [`$polish-code`](skills/polish-code/SKILL.md) | Iterative quality loop: stage → format → lint → test → review → evaluate → apply → smoke test → re-run until stable | [`$stage`](skills/stage/SKILL.md), [`$review-code`](skills/review-code/SKILL.md), [`$evaluate-findings`](skills/evaluate-findings/SKILL.md), [`$apply-findings`](skills/apply-findings/SKILL.md), [`$smoke-test`](skills/smoke-test/SKILL.md), [`$investigate`](skills/investigate/SKILL.md) | [`$finalize`](skills/finalize/SKILL.md) |
| [`$simplify-code`](skills/simplify-code/SKILL.md) | Review code quality and fix issues | [`$consult-claude`](skills/consult-claude/SKILL.md), [`$note-improvement`](skills/note-improvement/SKILL.md) | [`$simplify-all`](skills/simplify-all/SKILL.md) |
| [`$simplify-docs`](skills/simplify-docs/SKILL.md) | Review code comments and markdown docs for unnecessary content and fix issues | | [`$simplify-all`](skills/simplify-all/SKILL.md), [`$finalize`](skills/finalize/SKILL.md) |
| [`$simplify-all`](skills/simplify-all/SKILL.md) | Run the code and docs simplification passes over one scope: every review sub-agent concurrently, then a single round of fixes | [`$simplify-code`](skills/simplify-code/SKILL.md), [`$simplify-docs`](skills/simplify-docs/SKILL.md) | [`$implement`](skills/implement/SKILL.md) |
| [`$implement`](skills/implement/SKILL.md) | Standard implementation flow: load code-style rules, make the change, smoke test and preview UI/UX changes, choose post-implementation QA | [`$code-style`](skills/code-style/SKILL.md), [`$smoke-test`](skills/smoke-test/SKILL.md), [`$preview`](skills/preview/SKILL.md), [`$finalize`](skills/finalize/SKILL.md), [`$simplify-all`](skills/simplify-all/SKILL.md), [`$investigate`](skills/investigate/SKILL.md) | [`$discuss-change`](skills/discuss-change/SKILL.md), [`$implement-plan`](skills/implement-plan/SKILL.md), [`$implement-improvements`](skills/implement-improvements/SKILL.md) |
| [`$investigate`](skills/investigate/SKILL.md) | Systematic root cause analysis for bugs and failures | [`$consult-claude`](skills/consult-claude/SKILL.md), [`$evaluate-findings`](skills/evaluate-findings/SKILL.md), [`$consult-oracle`](skills/consult-oracle/SKILL.md) | [`$find-dead-code`](skills/find-dead-code/SKILL.md), [`$polish-code`](skills/polish-code/SKILL.md), [`$smoke-test`](skills/smoke-test/SKILL.md), [`$exploratory-test`](skills/exploratory-test/SKILL.md), [`$implement`](skills/implement/SKILL.md), [`$implement-improvements`](skills/implement-improvements/SKILL.md) |

## Testing

| Skill | What It Does | Uses | Used By |
|---|---|---|---|
| [`$create-test-plan`](skills/create-test-plan/SKILL.md) | Generate a structured test plan at `.turbo/test-plans/<slug>.md` with four escalating levels | | [`$exploratory-test`](skills/exploratory-test/SKILL.md) |
| [`$smoke-test`](skills/smoke-test/SKILL.md) | Launch the app and verify changes manually | `browser-use@openai-bundled` plugin, [`$investigate`](skills/investigate/SKILL.md) | [`$polish-code`](skills/polish-code/SKILL.md), [`$implement`](skills/implement/SKILL.md) |
| [`$preview`](skills/preview/SKILL.md) | Stand up the live app and hand it to the user to judge a UI/UX change firsthand | | [`$implement`](skills/implement/SKILL.md) |
| [`$exploratory-test`](skills/exploratory-test/SKILL.md) | Multi-level exploratory testing: basic, complex, adversarial, and cross-cutting scenarios, plus usability observations | [`$create-test-plan`](skills/create-test-plan/SKILL.md), `browser-use@openai-bundled` plugin, [`$investigate`](skills/investigate/SKILL.md), [`$user-experience`](skills/user-experience/SKILL.md) | |

## Dependencies and Tooling

| Skill | What It Does | Uses | Used By |
|---|---|---|---|
| [`$review-dependencies`](skills/review-dependencies/SKILL.md) | Detect outdated or vulnerable dependencies | | [`$audit`](skills/audit/SKILL.md), [`$update-dependencies`](skills/update-dependencies/SKILL.md) |
| [`$update-dependencies`](skills/update-dependencies/SKILL.md) | Smart dependency upgrades with breaking change research | [`$review-dependencies`](skills/review-dependencies/SKILL.md), [`$consult-claude`](skills/consult-claude/SKILL.md) | |
| [`$review-tooling`](skills/review-tooling/SKILL.md) | Detect dev tooling gaps across linters, formatters, hooks, test runners, and CI/CD | | [`$audit`](skills/audit/SKILL.md), [`$onboard`](skills/onboard/SKILL.md) |
| [`$review-agentic-setup`](skills/review-agentic-setup/SKILL.md) | Detect agentic coding infrastructure: CLAUDE.md, AGENTS.md, skills, MCP, hooks, cross-tool compatibility | | [`$audit`](skills/audit/SKILL.md), [`$onboard`](skills/onboard/SKILL.md) |

## Findings

| Skill | What It Does | Uses | Used By |
|---|---|---|---|
| [`$interpret-feedback`](skills/interpret-feedback/SKILL.md) | Parallel internal + Claude interpretation of third-party feedback | [`$peer-review`](skills/peer-review/SKILL.md) | [`$resolve-pr-comments`](skills/resolve-pr-comments/SKILL.md) |
| [`$evaluate-findings`](skills/evaluate-findings/SKILL.md) | Triage review feedback with adversarial verification | | [`$audit`](skills/audit/SKILL.md), [`$refine-plan`](skills/refine-plan/SKILL.md), [`$find-dead-code`](skills/find-dead-code/SKILL.md), [`$assess-technical-debt`](skills/assess-technical-debt/SKILL.md), [`$polish-code`](skills/polish-code/SKILL.md), [`$investigate`](skills/investigate/SKILL.md), [`$review-pr`](skills/review-pr/SKILL.md), [`$resolve-pr-comments`](skills/resolve-pr-comments/SKILL.md), [`$create-skill`](skills/create-skill/SKILL.md) |
| [`$apply-findings`](skills/apply-findings/SKILL.md) | Apply findings from evaluations or reviews | [`$note-improvement`](skills/note-improvement/SKILL.md), [`$consult-claude`](skills/consult-claude/SKILL.md) | [`$refine-plan`](skills/refine-plan/SKILL.md), [`$polish-code`](skills/polish-code/SKILL.md), [`$resolve-findings`](skills/resolve-findings/SKILL.md), [`$create-skill`](skills/create-skill/SKILL.md) |
| [`$resolve-findings`](skills/resolve-findings/SKILL.md) | Choose implementation path (direct or plan) for evaluated findings and dispatch | [`$code-style`](skills/code-style/SKILL.md), [`$apply-findings`](skills/apply-findings/SKILL.md), [`$finalize`](skills/finalize/SKILL.md), [`$turboplan`](skills/turboplan/SKILL.md), [`$consult-claude`](skills/consult-claude/SKILL.md) | [`$review-pr`](skills/review-pr/SKILL.md), [`$resolve-pr-comments`](skills/resolve-pr-comments/SKILL.md) |

## Git and GitHub

| Skill | What It Does | Uses | Used By |
|---|---|---|---|
| [`$stage`](skills/stage/SKILL.md) | Stage implementation changes with precise file selection | | [`$polish-code`](skills/polish-code/SKILL.md), [`$stage-commit`](skills/stage-commit/SKILL.md) |
| [`$stage-commit`](skills/stage-commit/SKILL.md) | Stage files and commit in one step | [`$stage`](skills/stage/SKILL.md), [`$commit-staged`](skills/commit-staged/SKILL.md) | [`$stage-commit-push`](skills/stage-commit-push/SKILL.md) |
| [`$stage-commit-push`](skills/stage-commit-push/SKILL.md) | Stage, commit, and push in one step | [`$stage-commit`](skills/stage-commit/SKILL.md) | |
| [`$commit-staged`](skills/commit-staged/SKILL.md) | Commit already-staged files with good message | [`$commit-rules`](skills/commit-rules/SKILL.md) | [`$stage-commit`](skills/stage-commit/SKILL.md), [`$commit-staged-push`](skills/commit-staged-push/SKILL.md) |
| [`$commit-staged-push`](skills/commit-staged-push/SKILL.md) | Commit already-staged files and push | [`$commit-staged`](skills/commit-staged/SKILL.md) | |
| [`$ship`](skills/ship/SKILL.md) | Commit, push, and optionally create or update a PR | [`$commit-rules`](skills/commit-rules/SKILL.md), [`$create-pr`](skills/create-pr/SKILL.md), [`$update-pr`](skills/update-pr/SKILL.md) | [`$finalize`](skills/finalize/SKILL.md) |
| [`$split-and-ship`](skills/split-and-ship/SKILL.md) | Ship split plan as separate branches and PRs or sequential commits on the current branch | [`$commit-rules`](skills/commit-rules/SKILL.md), [`$create-pr`](skills/create-pr/SKILL.md), [`$update-pr`](skills/update-pr/SKILL.md) | [`$finalize`](skills/finalize/SKILL.md) |
| [`$review-pr`](skills/review-pr/SKILL.md) | PR review: fetch comments, resolve base branch, run code review, evaluate findings, dispatch to implementation | [`$fetch-pr-comments`](skills/fetch-pr-comments/SKILL.md), [`$review-code`](skills/review-code/SKILL.md), [`$evaluate-findings`](skills/evaluate-findings/SKILL.md), [`$resolve-findings`](skills/resolve-findings/SKILL.md) | |
| [`$create-pr`](skills/create-pr/SKILL.md) | Draft and create a GitHub PR | [`$github-voice`](skills/github-voice/SKILL.md) | [`$ship`](skills/ship/SKILL.md), [`$split-and-ship`](skills/split-and-ship/SKILL.md) |
| [`$update-pr`](skills/update-pr/SKILL.md) | Update existing PR title and description | [`$github-voice`](skills/github-voice/SKILL.md) | [`$ship`](skills/ship/SKILL.md), [`$split-and-ship`](skills/split-and-ship/SKILL.md) |
| [`$create-issue`](skills/create-issue/SKILL.md) | Draft and file a GitHub issue, honoring repo templates and labels | [`$github-voice`](skills/github-voice/SKILL.md) | [`$contribute-turbo`](skills/contribute-turbo/SKILL.md) |
| [`$fetch-pr-comments`](skills/fetch-pr-comments/SKILL.md) | Read-only summary of unresolved PR comments | | [`$review-pr`](skills/review-pr/SKILL.md) |
| [`$resolve-pr-comments`](skills/resolve-pr-comments/SKILL.md) | Evaluate, fix, answer, and reply to PR comments (including reviewer questions) | [`$interpret-feedback`](skills/interpret-feedback/SKILL.md), [`$evaluate-findings`](skills/evaluate-findings/SKILL.md), [`$resolve-findings`](skills/resolve-findings/SKILL.md), [`$answer-reviewer-questions`](skills/answer-reviewer-questions/SKILL.md), [`$reply-to-pr-threads`](skills/reply-to-pr-threads/SKILL.md), [`$reply-to-pr-conversation`](skills/reply-to-pr-conversation/SKILL.md), [`$consult-claude`](skills/consult-claude/SKILL.md) | |
| [`$answer-reviewer-questions`](skills/answer-reviewer-questions/SKILL.md) | Recall implementation reasoning and compose raw answers to reviewer questions | [`$recall-reasoning`](skills/recall-reasoning/SKILL.md) | [`$resolve-pr-comments`](skills/resolve-pr-comments/SKILL.md) |
| [`$reply-to-pr-threads`](skills/reply-to-pr-threads/SKILL.md) | Draft, confirm, and post PR thread replies; re-fetches resolution state to skip auto-resolved threads | [`$github-voice`](skills/github-voice/SKILL.md) | [`$resolve-pr-comments`](skills/resolve-pr-comments/SKILL.md) |
| [`$reply-to-pr-conversation`](skills/reply-to-pr-conversation/SKILL.md) | Draft, confirm, and post a single conversational reply to PR issue comments, addressing tracked items as natural prose | [`$github-voice`](skills/github-voice/SKILL.md) | [`$resolve-pr-comments`](skills/resolve-pr-comments/SKILL.md) |

## External Tools

| Skill | What It Does | Uses | Used By |
|---|---|---|---|
| [`$peer-review`](skills/peer-review/SKILL.md) | Independent peer review via Claude (code, plans, feedback) | [`$claude-print`](skills/claude-print/SKILL.md) | [`$audit`](skills/audit/SKILL.md), [`$review-plan`](skills/review-plan/SKILL.md), [`$review-code`](skills/review-code/SKILL.md), [`$interpret-feedback`](skills/interpret-feedback/SKILL.md) |
| [`$consult-claude`](skills/consult-claude/SKILL.md) | Multi-turn consultation with Claude Code | [Claude Code](https://github.com/anthropics/claude-code) | [`$investigate`](skills/investigate/SKILL.md), [`$apply-findings`](skills/apply-findings/SKILL.md), [`$resolve-findings`](skills/resolve-findings/SKILL.md), [`$turboplan`](skills/turboplan/SKILL.md), [`$discuss-change`](skills/discuss-change/SKILL.md), [`$draft-plan`](skills/draft-plan/SKILL.md), [`$resolve-pr-comments`](skills/resolve-pr-comments/SKILL.md), [`$create-project-skills`](skills/create-project-skills/SKILL.md), [`$update-dependencies`](skills/update-dependencies/SKILL.md), [`$simplify-code`](skills/simplify-code/SKILL.md) |
| [`$consult-oracle`](skills/consult-oracle/SKILL.md) | Consult ChatGPT Pro when completely stuck (requires setup) | [ChatGPT Pro](https://chatgpt.com/) | [`$investigate`](skills/investigate/SKILL.md) |
| [`$claude-print`](skills/claude-print/SKILL.md) | Non-interactive Claude Code print-mode call from Codex | [Claude Code](https://github.com/anthropics/claude-code) | [`$peer-review`](skills/peer-review/SKILL.md) |

## Rules and Style

| Skill | What It Does | Uses | Used By |
|---|---|---|---|
| [`$code-style`](skills/code-style/SKILL.md) | Enforce existence, reuse, mirror, and symmetry principles | | [`$implement`](skills/implement/SKILL.md), [`$resolve-findings`](skills/resolve-findings/SKILL.md) |
| [`$frontend-design`](skills/frontend-design/SKILL.md) | Design guidelines for distinctive, production-grade frontend interfaces | | [`$audit`](skills/audit/SKILL.md), [`$onboard`](skills/onboard/SKILL.md), [`$map-codebase`](skills/map-codebase/SKILL.md), [`$assess-technical-debt`](skills/assess-technical-debt/SKILL.md) |
| [`$user-experience`](skills/user-experience/SKILL.md) | UX lens: whether a change serves the user's goal and whether its flow holds together (Understanding, Bridging, Flowing) | | [`$exploratory-test`](skills/exploratory-test/SKILL.md) |
| [`$github-voice`](skills/github-voice/SKILL.md) | Shared writing style rules for GitHub-facing output (PR comments, descriptions, titles, issues, proposals) | | [`$create-pr`](skills/create-pr/SKILL.md), [`$update-pr`](skills/update-pr/SKILL.md), [`$create-issue`](skills/create-issue/SKILL.md), [`$reply-to-pr-threads`](skills/reply-to-pr-threads/SKILL.md), [`$reply-to-pr-conversation`](skills/reply-to-pr-conversation/SKILL.md) |
| [`$commit-rules`](skills/commit-rules/SKILL.md) | Shared commit message rules and technical constraints | | [`$commit-staged`](skills/commit-staged/SKILL.md), [`$ship`](skills/ship/SKILL.md), [`$split-and-ship`](skills/split-and-ship/SKILL.md) |
| [`$changelog-rules`](skills/changelog-rules/SKILL.md) | Shared changelog conventions and formatting rules | | [`$create-changelog`](skills/create-changelog/SKILL.md), [`$update-changelog`](skills/update-changelog/SKILL.md) |

## Knowledge and Maintenance

| Skill | What It Does | Uses | Used By |
|---|---|---|---|
| [`$self-improve`](skills/self-improve/SKILL.md) | Extract learnings from the current session, or sweep past sessions, to AGENTS.md, memory, or skills | [`$contribute-turbo`](skills/contribute-turbo/SKILL.md), [`$create-skill`](skills/create-skill/SKILL.md), [`$note-improvement`](skills/note-improvement/SKILL.md) | [`$turboplan`](skills/turboplan/SKILL.md), [`$finalize`](skills/finalize/SKILL.md) |
| [`$note-improvement`](skills/note-improvement/SKILL.md) | Capture out-of-scope improvement ideas to `.turbo/improvements.md` | | [`$apply-findings`](skills/apply-findings/SKILL.md), [`$self-improve`](skills/self-improve/SKILL.md), [`$simplify-code`](skills/simplify-code/SKILL.md) |
| [`$implement-improvements`](skills/implement-improvements/SKILL.md) | Validate improvements and run one lane per session (direct, investigate, or plan) | [`$implement`](skills/implement/SKILL.md), [`$investigate`](skills/investigate/SKILL.md), [`$turboplan`](skills/turboplan/SKILL.md) | |
| [`$recall-reasoning`](skills/recall-reasoning/SKILL.md) | Recall implementation reasoning from past Codex session history for a commit or file location | | [`$answer-reviewer-questions`](skills/answer-reviewer-questions/SKILL.md) |
| [`$create-handoff`](skills/create-handoff/SKILL.md) | Write a handoff file at `.turbo/handoff/<YYYY-MM-DD>-<slug>.md` capturing task, status, open decisions, in-flight changes, and next step | | |
| [`$explain-this`](skills/explain-this/SKILL.md) | Explain whatever the user is pointing at in plain language: a pending question, code, an error, output, or an artifact | | |
| [`$understand-change`](skills/understand-change/SKILL.md) | Teach the user to deeply understand a change through interactive tutoring: restate, drill why/what/how, and quiz until mastery | | |
| [`$create-skill`](skills/create-skill/SKILL.md) | Create or update a skill with proper structure | [`$evaluate-findings`](skills/evaluate-findings/SKILL.md), [`$apply-findings`](skills/apply-findings/SKILL.md) | [`$create-project-skills`](skills/create-project-skills/SKILL.md), [`$self-improve`](skills/self-improve/SKILL.md) |
| [`$create-project-skills`](skills/create-project-skills/SKILL.md) | Scan the codebase and generate project-specific skills that capture inferred conventions | [`$create-skill`](skills/create-skill/SKILL.md), [`$consult-claude`](skills/consult-claude/SKILL.md) | |
| [`$update-turbo`](skills/update-turbo/SKILL.md) | Update Turbo Codex skills with always-latest instructions fetched from GitHub | | |
| [`$contribute-turbo`](skills/contribute-turbo/SKILL.md) | Propose a turbo skill improvement upstream as a GitHub issue | [`$create-issue`](skills/create-issue/SKILL.md) | [`$self-improve`](skills/self-improve/SKILL.md) |
| [`$create-changelog`](skills/create-changelog/SKILL.md) | Create a CHANGELOG.md with version history backfilled from GitHub releases or git tags | [`$changelog-rules`](skills/changelog-rules/SKILL.md) | |
| [`$update-changelog`](skills/update-changelog/SKILL.md) | Update the Unreleased section of CHANGELOG.md based on current changes (no-op if no changelog) | [`$changelog-rules`](skills/changelog-rules/SKILL.md) | [`$finalize`](skills/finalize/SKILL.md) |
