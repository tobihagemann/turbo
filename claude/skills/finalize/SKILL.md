---
name: finalize
description: "Run the post-implementation QA workflow: tests, code polishing, review, and commit. Use when the user asks to \"finalize changes\", \"wrap up implementation\", \"finish up\", or \"ready to commit\"."
---

# Finalize Implementation

Post-implementation QA workflow: tests, code polishing, commit, self-improvement, and landing the pull request.

## Task Tracking

At the start, use `TaskCreate` to create a task for each phase:

1. Run `/polish-code` skill
2. Run `/simplify-docs` skill
3. Run `/update-changelog` skill
4. Run `/self-improve` skill
5. Ship It
6. Run `/land-pr` skill

## Phase 1: Run `/polish-code` Skill

Run the `/polish-code` skill for the current changes.

## Phase 2: Run `/simplify-docs` Skill

Run the `/simplify-docs` skill on the staged changes (`git diff --cached`). Stage any edits it makes before continuing.

## Phase 3: Run `/update-changelog` Skill

Run the `/update-changelog` skill. Stage any edits it makes before continuing.

## Phase 4: Run `/self-improve` Skill

Run the `/self-improve` skill for the current session. Always run this phase even if the session seemed routine.

## Phase 5: Ship It

### Step 1: Analyze Split

Examine the staged changes and evaluate whether they form a single reviewable unit or several independently reviewable units. This step decides only whether to split; the chosen ship skill owns all repository-state detection and the commit, push, branch, and PR intent.

Run `git diff --cached --stat` and `git diff --cached` to understand the scope. Categorize changes along three dimensions:

- **Concern type**: refactoring, bug fix, new feature, cleanup, dependency update
- **Layer/domain**: backend, frontend, database migrations, i18n, tests, configuration
- **Logical unit**: files that form a coherent, independently reviewable change

A split is warranted when the staged changes contain multiple reviewable units. Each unit should be independently understandable, testable, and revertable. When deciding group boundaries, consider whether a reviewer could evaluate each group without needing context from the others.

### Step 2: Present Analysis and Choose Path

Output the split analysis as text.

If changes form a single cohesive unit, note this and run the `/ship` skill.

If changes span multiple reviewable units, propose an ordered list of groups. For each group, specify:

- Name and one-line description
- File list (flag files with mixed-concern hunks)
- Dependencies: which earlier groups, if any, this group builds on

Use `AskUserQuestion` to let the user choose whether to ship the changes together or split them up.

- **Ship together** — ship all staged changes as one unit; run the `/ship` skill
- **Split up** — ship each group as its own unit; run the `/split-and-ship` skill

## Phase 6: Run `/land-pr` Skill

Skip this phase when Phase 5 neither opened a pull request nor pushed to the branch of an open one. When Phase 5 left a pull request's body with the user instead of opening it, present `/turbo:land-pr` to run once it is posted, and skip the skill.

When Phase 5 opened or pushed to several pull requests, present `/turbo:land-pr <number>` for each, to run from that pull request's checkout, and skip the skill.

Otherwise, run the `/land-pr` skill for that pull request.

Then use the TaskList tool and proceed to any remaining task.

## Rules

- Diff size, number of files changed, passing tests, perceived user urgency, or context window concerns are not reasons to skip a phase. Each phase does work beyond what those signals cover. "The session was long" or "a prior phase was thorough" are never valid reasons to skip a later phase.
- Never stage or commit files containing secrets (`.env`, credentials, API keys). Warn if detected.
- Do not present diffs to the user — the user reviews diffs in an external git client. Use `git diff` internally as needed.
- If a non-test step fails (polish, review), stop and report the failure. Do not skip ahead.
