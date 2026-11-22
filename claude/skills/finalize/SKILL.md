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
5. Run `/ship` skill
6. Run `/land-pr` skill

## Phase 1: Run `/polish-code` Skill

Run the `/polish-code` skill for the current changes.

## Phase 2: Run `/simplify-docs` Skill

Run the `/simplify-docs` skill on the staged changes (`git diff --cached`). Stage any edits it makes before continuing.

## Phase 3: Run `/update-changelog` Skill

Run the `/update-changelog` skill. Stage any edits it makes before continuing.

## Phase 4: Run `/self-improve` Skill

Run the `/self-improve` skill for the current session. Always run this phase even if the session seemed routine.

## Phase 5: Run `/ship` Skill

Run the `/ship` skill.

## Phase 6: Run `/land-pr` Skill

Count each PR Phase 5 opened, pushed to, or left with the user to post. For each unposted body, present `/turbo:land-pr` to run once posted. For a multi-PR result, present `/turbo:land-pr <number>` for each open PR from its checkout and skip the skill. Also skip it when there is no open PR to land.

Otherwise, run the `/land-pr` skill for that pull request.

Then use the TaskList tool and proceed to any remaining task.

## Rules

- Diff size, number of files changed, passing tests, perceived user urgency, or context window concerns are not reasons to skip a phase. Each phase does work beyond what those signals cover. "The session was long" or "a prior phase was thorough" are never valid reasons to skip a later phase.
- Never stage or commit files containing secrets (`.env`, credentials, API keys). Warn if detected.
- Do not present diffs to the user — the user reviews diffs in an external git client. Use `git diff` internally as needed.
- If a non-test step fails (polish, review), stop and report the failure. Do not skip ahead.
