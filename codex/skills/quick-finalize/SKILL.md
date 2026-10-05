---
name: quick-finalize
description: "Close out a change without the deep review loop: stage, simplify code and docs, run the project's checks, smoke test, update the changelog, self-improve, and ship. Use when the user asks to \"quick finalize\", \"quickly finalize\", \"finalize quickly\", \"light finalize\", \"wrap this up quickly\", \"close this out without the full review\", or \"ship this without the deep pass\"."
---

# Quick Finalize

## Task Tracking

At the start, use `update_plan` to track each phase, restating any remaining steps of a parent workflow alongside them:

1. Run `$stage` skill
2. Run `$simplify-all` skill
3. Run `$run-checks` skill
4. Run `$smoke-test` skill
5. Run `$update-changelog` skill
6. Run `$self-improve` skill
7. Ship It

Workflow state lives at `.turbo/workflows/<slug>.md` — slug from the governing plan when one is in context, otherwise the current branch name with non-alphanumerics replaced by hyphens. It pairs one-to-one with the thread's goal. When this run's `create_goal` attempt succeeds, write the file fresh: `Status: active` plus this invocation's `update_plan` list as a checkbox list. When an unfinished goal already exists, mirror into the workflow file its objective names; when it names none, continue without workflow state. Mirror every `update_plan` call into the file; it holds the pipeline's remaining steps and their statuses. When this run created the goal, run the terminal step in order: mark the final entry completed and mirror it, set `Status: closed`, mark the goal complete with `update_goal`, then emit any halt message.

Then attempt `create_goal` with the objective: "Run `$quick-finalize` on the current changes through Phase 7 (Ship It). Workflow state: `.turbo/workflows/<slug>.md`; mirror every `update_plan` call into it. After any context compaction, re-read the workflow file and continue from the first unfinished entry. Mark this goal complete when Phase 7 finishes." If an unfinished goal already exists, an outer workflow owns it; continue without creating one.

## Phase 1: Run `$stage` Skill

Run the `$stage` skill.

## Phase 2: Run `$simplify-all` Skill

Run the `$simplify-all` skill on the staged changes (`git diff --cached`). Stage any edits it makes before continuing.

## Phase 3: Run `$run-checks` Skill

Run the `$run-checks` skill. Stage any edits it makes before continuing.

## Phase 4: Run `$smoke-test` Skill

Run the `$smoke-test` skill. It verifies without modifying code, so act on what it reports here: fix each failure and re-run it. When the same failure survives a fix attempt, run the `$investigate` skill; if investigation finds no root cause, stop and report with its findings. When a blocker cannot be cleared in this session (a path needing real credentials, an external service, or state unavailable here), carry it to the end of the run and name it in the closing report as a case still left to the user, rather than treating it as a failure. Write it into the workflow file too, as a `Left to the user:` line below the checklist, and keep that line through every later mirror. When a fix made here edited code, run the `$run-checks` skill again once no failure remains. Stage any edits before continuing.

## Phase 5: Run `$update-changelog` Skill

Run the `$update-changelog` skill. Stage any edits it makes before continuing.

## Phase 6: Run `$self-improve` Skill

Run the `$self-improve` skill for the current session. Always run this phase even if the session seemed routine.

## Phase 7: Ship It

### Step 1: Analyze Split

Examine the staged changes and evaluate whether they form a single reviewable unit or several independently reviewable units. This step decides only whether to split; the chosen ship skill owns all repository-state detection and the commit, push, branch, and PR intent.

Run `git diff --cached --stat` and `git diff --cached` to understand the scope. Categorize changes along three dimensions:

- **Concern type**: refactoring, bug fix, new feature, cleanup, dependency update
- **Layer/domain**: backend, frontend, database migrations, i18n, tests, configuration
- **Logical unit**: files that form a coherent, independently reviewable change

A split is warranted when the staged changes contain multiple reviewable units. Each unit should be independently understandable, testable, and revertable. When deciding group boundaries, consider whether a reviewer could evaluate each group without needing context from the others.

### Step 2: Present Analysis and Choose Path

Output the split analysis as text.

If changes form a single cohesive unit, note this and run the `$ship` skill.

If changes span multiple reviewable units, propose an ordered list of groups. For each group, specify:

- Name and one-line description
- File list (flag files with mixed-concern hunks)
- Dependencies: which earlier groups, if any, this group builds on

Use `request_user_input` to let the user choose whether to ship the changes together or split them up.

- **Ship together** — ship all staged changes as one unit; run the `$ship` skill
- **Split up** — ship each group as its own unit; run the `$split-and-ship` skill

If this run created a goal, follow the closing `update_plan` call below by mirroring it into the workflow file, setting `Status: closed`, and marking the goal complete with `update_goal`, in that order. Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

## Rules

- Diff size, number of files changed, passing tests, perceived user urgency, or context window concerns are not reasons to skip a phase. Each phase does work beyond what those signals cover. "The session was long" or "a prior phase was thorough" are never valid reasons to skip a later phase.
- Never stage or commit files containing secrets (`.env`, credentials, API keys). Warn if detected.
- Do not present diffs to the user — the user reviews diffs in an external git client. Use `git diff` internally as needed.
- If a non-test phase fails, stop and report the failure. Do not skip ahead.
