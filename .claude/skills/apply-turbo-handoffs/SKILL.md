---
name: apply-turbo-handoffs
description: "Audit the turbo skill lessons that /self-improve writes into this repo's .turbo/handoff/ from other projects, apply the ones the user approves, delete the consumed handoffs, commit and push, and update the installed Turbo skills. Use when the user asks to \"read .turbo/handoff and let me know what you think\", \"read the handoff files and let me know what you think\", \"review the lesson handoffs\", \"apply the self-improve handoffs\", or \"process the turbo handoffs\"."
---

# Apply Turbo Handoffs

## Task Tracking

At the start, use `TaskCreate` to create a task for each step:

1. Audit the handoffs
2. Act on the user's reply
3. Apply the approved changes
4. Close out the handoffs
5. Run `/stage-commit-push` skill
6. Run `/update-turbo` skill

## Step 1: Audit the Handoffs

Read every file in `.turbo/handoff/`. Audit the handoffs that propose lessons for turbo files. Name any handoff that instead carries a session's in-flight work, and leave it untouched. When no lesson handoff exists, present "No lesson handoffs in `.turbo/handoff/`." Mark Steps 2 through 6 completed, then use the TaskList tool and proceed to any remaining task.

Take each handoff's evidence as a record of the incident, and audit its remedy against the file it targets before recommending any of it:

- **Gap** — confirm the gap still exists in the current text, is not already handled elsewhere in the skill, its references, or `claude/SKILL-CONVENTIONS.md`, and was not already rejected by a decision recorded in auto memory or the target's git history.
- **Diagnosis** — ask whether the real finding is that the skill should not have run there, or that nothing was broken, rather than that the skill must handle the case.
- **Remedy** — check the proposed text against the conventions and against what the target skill's other steps depend on. Prefer generalizing an existing rule over adding one more special case to it.
- **Genericity** — strip anything tied to the originating project so the rule states the shared shape alone.
- **Weight** — weigh how often the new rule would fire against how often it would help.

Output a verdict per lesson as text: apply as proposed, apply adjusted (with the adjusted wording or placement), or drop, each with the reasoning that decided it. Name any lesson that should stay Claude-only, as an intentional divergence under `claude/CLAUDE.md`. Be willing to conclude that none of it should ship.

Close with how to reply: approve the verdicts as they stand, describe what to change, or hold a lesson back for a later session. Then end the turn.

## Step 2: Act on the User's Reply

- **Revise** — apply the user's corrections to the verdicts. When a correction raises a question the audit did not cover, investigate it first. Then re-present the changed verdicts, close with Step 1's reply guidance, and end the turn again.
- **Approve** — the verdicts are settled, and this approval covers the commit in Step 5. Continue to Step 3.

## Step 3: Apply the Approved Changes

Run the `/create-skill` skill once for every lesson approved to apply, in its approved form, following the edition-mirroring rules in `claude/CLAUDE.md`. Edit non-skill files such as docs directly.

When the applied edits depart materially from the approved verdicts, such as review findings rewriting an approved rule or a lesson turning out not to fit, present each departure and end the turn. Continue from the user's reply.

## Step 4: Close Out the Handoffs

Delete each audited handoff whose lessons were all applied or dropped. For a handoff that still holds a lesson the user held back, remove the resolved lessons from it and keep the file.

When no tracked file changed, present that nothing was committed. Mark Steps 5 and 6 completed, then use the TaskList tool and proceed to any remaining task.

## Step 5: Run `/stage-commit-push` Skill

Run the `/stage-commit-push` skill.

## Step 6: Run `/update-turbo` Skill

Run the `/update-turbo` skill.

Then use the TaskList tool and proceed to any remaining task.
