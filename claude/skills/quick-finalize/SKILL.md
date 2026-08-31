---
name: quick-finalize
description: "Close out a change without the deep review loop: stage, simplify code and docs, run the project's checks, smoke test, update the changelog, self-improve, and ship. Use when the user asks to \"quick finalize\", \"quickly finalize\", \"finalize quickly\", \"light finalize\", \"wrap this up quickly\", \"close this out without the full review\", or \"ship this without the deep pass\"."
---

# Quick Finalize

## Task Tracking

At the start, use `TaskCreate` to create a task for each phase:

1. Run `/stage` skill
2. Run `/simplify-all` skill
3. Run `/run-checks` skill
4. Run `/smoke-test` skill
5. Run `/update-changelog` skill
6. Run `/self-improve` skill
7. Run `/ship` skill

## Phase 1: Run `/stage` Skill

Run the `/stage` skill.

## Phase 2: Run `/simplify-all` Skill

Run the `/simplify-all` skill on the staged changes (`git diff --cached`). Stage any edits it makes before continuing.

## Phase 3: Run `/run-checks` Skill

Run the `/run-checks` skill. Stage any edits it makes before continuing.

## Phase 4: Run `/smoke-test` Skill

Run the `/smoke-test` skill. It verifies without modifying code, so act on what it reports here: fix each failure and re-run it. When the same failure survives a fix attempt, run the `/investigate` skill; if investigation finds no root cause, stop and report with its findings. When a blocker cannot be cleared in this session (a path needing real credentials, an external service, or state unavailable here), carry it into Phase 7 so the hand-over names the cases still left to the user, rather than treating it as a failure. Stage any edits before continuing.

## Phase 5: Run `/update-changelog` Skill

Run the `/update-changelog` skill.

## Phase 6: Run `/self-improve` Skill

Run the `/self-improve` skill for the current session. Always run this phase even if the session seemed routine. Skip it only when the invocation passed `defer-self-improve`, meaning a parent workflow continues past this call and closes the session itself.

## Phase 7: Run `/ship` Skill

Run the `/ship` skill.

Then use the TaskList tool and proceed to any remaining task.

## Rules

- Diff size, number of files changed, passing tests, perceived user urgency, or context window concerns are not reasons to skip a phase. Each phase does work beyond what those signals cover. "The session was long" or "a prior phase was thorough" are never valid reasons to skip a later phase.
- Never stage or commit files containing secrets (`.env`, credentials, API keys). Warn if detected.
- Do not present diffs to the user — the user reviews diffs in an external git client. Use `git diff` internally as needed.
- If a non-test phase fails, stop and report the failure. Do not skip ahead.
