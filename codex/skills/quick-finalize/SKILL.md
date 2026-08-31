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
7. Run `$ship` skill

Workflow state lives at `.turbo/workflows/<slug>.md` — slug from the governing plan when one is in context, otherwise the current branch name with non-alphanumerics replaced by hyphens. It pairs one-to-one with the thread's goal. When this run's `create_goal` attempt succeeds, write the file fresh: `Status: active` plus this invocation's `update_plan` list as a checkbox list. When an unfinished goal already exists, mirror into the workflow file its objective names; when it names none, continue without workflow state. Mirror every `update_plan` call into the file; it holds the pipeline's remaining steps and their statuses. When this run created the goal, run the terminal step in order: mark the final entry completed and mirror it, set `Status: closed`, mark the goal complete with `update_goal`, then emit any halt message.

Then attempt `create_goal` with the objective: "Run `$quick-finalize` on the current changes through Phase 7 (`$ship`). Workflow state: `.turbo/workflows/<slug>.md`; mirror every `update_plan` call into it. After any context compaction, re-read the workflow file and continue from the first unfinished entry. Mark this goal complete when Phase 7 finishes." If an unfinished goal already exists, an outer workflow owns it; continue without creating one.

## Phase 1: Run `$stage` Skill

Run the `$stage` skill.

## Phase 2: Run `$simplify-all` Skill

Run the `$simplify-all` skill on the staged changes (`git diff --cached`). Stage any edits it makes before continuing.

## Phase 3: Run `$run-checks` Skill

Run the `$run-checks` skill. Stage any edits it makes before continuing.

## Phase 4: Run `$smoke-test` Skill

Run the `$smoke-test` skill. It verifies without modifying code, so act on what it reports here: fix each failure and re-run it. When the same failure survives a fix attempt, run the `$investigate` skill; if investigation finds no root cause, stop and report with its findings. When a blocker cannot be cleared in this session (a path needing real credentials, an external service, or state unavailable here), carry it into Phase 7 so the hand-over names the cases still left to the user, rather than treating it as a failure. Stage any edits before continuing.

## Phase 5: Run `$update-changelog` Skill

Run the `$update-changelog` skill.

## Phase 6: Run `$self-improve` Skill

Run the `$self-improve` skill for the current session. Always run this phase even if the session seemed routine. Skip it only when the invocation passed `defer-self-improve`, meaning a parent workflow continues past this call and closes the session itself.

## Phase 7: Run `$ship` Skill

Run the `$ship` skill.

If this run created a goal, mark it complete with `update_goal`. Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

## Rules

- Diff size, number of files changed, passing tests, perceived user urgency, or context window concerns are not reasons to skip a phase. Each phase does work beyond what those signals cover. "The session was long" or "a prior phase was thorough" are never valid reasons to skip a later phase.
- Never stage or commit files containing secrets (`.env`, credentials, API keys). Warn if detected.
- Do not present diffs to the user — the user reviews diffs in an external git client. Use `git diff` internally as needed.
- If a non-test phase fails, stop and report the failure. Do not skip ahead.
