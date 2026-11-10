---
name: refine-plan
description: "Iteratively review and revise a plan until no new findings survive evaluation. Use when the user asks to \"refine the plan\", \"iterate on the plan\", \"tighten the plan\", or \"improve the plan\"."
---

# Refine Plan

Loop the review pipeline over a plan until no new findings are accepted. Writes back to the plan file in place.

## Task Tracking

At the start of every invocation (including re-runs from Step 5), use `TaskCreate` to create a task for each step:

1. Resolve the plan
2. Run `/review-plan` skill
3. Run `/evaluate-findings` skill
4. Run `/apply-findings` skill
5. Re-run `/refine-plan` skill if changed

## Step 1: Resolve the Plan

1. **Explicit path** — use it
2. **Explicit slug** — resolve to `.turbo/plans/<slug>.md`
3. **Single file** — Glob `.turbo/plans/*.md`. If exactly one file exists, use it
4. **Most recent** — most recently modified file
5. **Legacy fallback** — `.turbo/plan.md` if `.turbo/plans/` does not exist
6. **Nothing found** — tell the user to run `/turbo:plan` and stop

If multiple candidates exist and the choice is non-obvious, use `AskUserQuestion`.

State the resolved path before continuing.

Unless an explicit path or slug was passed, confirm the resolved plan still describes work that remains to be done. The signal is a frontmatter `status:` of `done`.

When the signal fires, output it as text. Then use `AskUserQuestion` to offer:

- **Refine anyway** — the marker is stale
- **Pick another plan** — resolve to a different file under `.turbo/plans/`, then confirm that plan against this same signal
- **Leave the plan alone** — skip refining

On **Leave the plan alone**, mark the remaining refine steps deleted, then use the TaskList tool and proceed to any remaining task.

Once the plan is settled, resolve the ledger as Loop State describes.

## Loop State

Loop state lives in a ledger at `.turbo/loops/refine-plan-<label>-<tag>.md`. The label is the resolved plan's slug, or the file's basename for a legacy single-file fallback. The tag is the output of `head -c 4 /dev/urandom | xxd -p`, minted once when the loop starts. The ledger records `Branch:` (the unmodified branch name, or `(detached)`), `Plan:` (the resolved plan path), a one-line purpose, and per iteration an `Iteration <N>: <state>` line, its verdicts, and Step 5's classification. A ledger that exists belongs to an active loop.

Resolve the ledger:

- **Carried path:** this invocation was passed a ledger path, by the re-run Step 5 starts or by a handoff. Continue that ledger. A carried path whose file no longer exists falls through to discovery. Take a carried path only from those two sources, never from a task another invocation left behind.
- **Discovery:** with nothing carried, list the ledgers in `.turbo/loops/` that git does not track whose name starts with `refine-plan-` and whose `Plan:` is the resolved plan, on any branch. Output each one's purpose, last iteration and its state, and file modification time as text. When any are listed, use `AskUserQuestion` to offer resuming a ledger, discarding a ledger, or starting fresh, naming the ledger in each resume and discard option; when more ledgers are listed than options fit, first ask which ledger to act on, offering the most recently modified ones and leaving the rest to the free-text answer. Starting fresh mints a new path and deletes nothing. Discarding deletes the named ledger, then discovery runs again.
- **Fresh:** mint a new path and write the ledger with `Iteration 1: open`.

Once the ledger resolves, use `TaskUpdate` to write its path into this invocation's Step 5 task description. After a compaction, this invocation reads its ledger path back from that task.

**Iteration state.** The current iteration's state line reads `open` until Step 5 reaches a gate, `awaiting <gate>` while Step 5 waits on the user at one (the prose-only round, the skip permission, the hard cap, the context-signal question recorded with the gate it wraps, or a hands-on check), and `classified` once Step 5 has settled whether another iteration runs. On a continued ledger, read the last iteration's state:

- `classified`: carry out the decision recorded with the classification. On another iteration, this invocation is the next one: append `Iteration <N+1>: open`. On an escalation to `/consult-oracle`, resume that escalation, and once the oracle answers, record the decision its answer leads to (another iteration, or a stop that deletes the ledger) in place of the escalation.
- `awaiting <gate>`: the interrupted iteration already ran Steps 2-4, so mark this invocation's Step 2-4 tasks completed. Ask that gate again before anything else; for the context-signal question, ask only the gate it wraps, since this session starts with fresh context. When it wrapped an automatic re-run, offer run another iteration, marked recommended, or stop iterating; when it wrapped a run that left the plan unchanged, the loop has ended, so delete the ledger. For `awaiting hands-on check`, ask for the check's result, or read the log the ledger names. Then proceed by the answer as Step 5 does.
- `open`: the iteration was interrupted. Rerun it under its own number from Step 2. The verdicts it already recorded stand: Step 3 keeps them rather than recording them again.

A compaction in flight is not a resume: this invocation continues its own iteration.

**Recording.** Have the ledger path in context when Steps 2 and 3 run, so recorded verdicts are honored. Append each Skip, Escalate, and Apply verdict with its reason under the current iteration as Steps 3-4 reach it, along with the user's resolution of an Escalate.

**Closing the loop.** Delete the ledger at a convergence stop, at a stop the user chooses at a gate, and at a stop granted at the skip gate. Keep it when escalating to `/consult-oracle`, since the oracle's answer decides what follows.

## Step 2: Run `/review-plan` Skill

Run the `/review-plan` skill on the resolved plan. Supply every Skip and Escalate verdict the ledger records, across all iterations, as the already-adjudicated list, one line each: the finding, its verdict, and the recorded reason. An Escalate the user resolved carries their resolution. A finding that re-proposes a design an earlier round left behind stays in scope regardless of the list: the alternatives having since failed on their own grounds is evidence the earlier reason did not account for, and Step 5's rule for a loop that arrives back at a design it left behind depends on that signal.

Always run this step even if the plan looks polished.

## Step 3: Run `/evaluate-findings` Skill

Run the `/evaluate-findings` skill on the review findings from Step 2.

## Step 4: Run `/apply-findings` Skill

Run the `/apply-findings` skill on the evaluated results.

## Step 5: Re-run `/refine-plan` Skill if Changed

Check whether the plan file was edited during Step 4. Any edit counts.

The iteration number below is the ledger's number for the `/refine-plan` run currently executing Step 5. It is not the iteration number of a prospective re-run. Iteration 1 is the initial run; iteration 2 is the first auto-re-run; iteration 3 is the second auto-re-run; iteration 4 and beyond exist only when the user opts in at the hard-cap ask. Iterations 1 and 2 always follow the classification gate (they never trigger the hard cap at their own Step 5, even when the auto-re-run they spawn would be iteration 3). The hard cap fires at the end of iteration 3 and every iteration thereafter.

**Iterations 1 and 2, if changes were made**, classify what Step 4 edited:

- **Structural edits** — run `/refine-plan` again via the Skill tool, passing the resolved path and the ledger path. If the round contains both structural and prose-only edits, treat it as structural and re-run automatically.
- **Prose-only edits only** (reworded sentences in place, fixed stale examples, clarified existing text without changing meaning) — output a summary of what changed, then use `AskUserQuestion` to ask whether to run one more round or stop here. Do not silently continue or silently stop.

**Iterations 1 and 2, if changes were made but you believe re-running is unnecessary**, use `AskUserQuestion` to ask for skip permission. Do not skip silently.

Judge whether another round is worthwhile by the trend across iterations: when rounds have stopped surfacing defects (contradictions, infeasible steps, missing requirements) and keep surfacing improvements of kinds earlier rounds already applied, the loop has converged even though the edits were structural — recommend stopping. A round that surfaces no defects is the termination signal; never add a confirmation round, an extra reviewer, or review steps beyond this skill's own.

Judge the kind of surviving defect as well as the trend. Once earlier rounds have drained the design- and requirement-level defects and a round's findings are dominated by claims that a named identifier does not exist or does not match its declaration, the plan has passed the point where reviewing it as text pays, even when the count is rising and every finding is genuine. Implementation surfaces that class immediately, so recommend stopping. Expect any round that adds mechanism to seed defects at the seams it creates.

When a round's findings turn on behavior nobody has observed, either how a platform, framework, or dependency behaves, or what a plan-specified algorithm produces on its inputs, prefer a cheap instrumented experiment to another review round. Run it in a temp directory outside the repo, confirm that each setting it varies took effect, and record what it shows in the plan before judging whether another round is warranted. For a plan-specified algorithm, write it as a script there, assert the plan's stated postconditions over randomized and degenerate inputs, and rewrite its rule only from what that run shows. Keep in the sample the inputs on which a postcondition is hard or impossible to meet, and judge each of their outcomes against that postcondition. Measure each postcondition on the outcome the algorithm produces, never by reading back a value it set in order to meet that postcondition, and count how often the condition of each conditional postcondition arose in the sample. A postcondition that could not fail on the sample was not tested: measure it on the outcome, or add inputs that reach its condition, and record the count. Pair a postcondition that holds only once a state is reached, such as "once nothing is pending", with one asserting that the state is reached whenever it should be. Check each postcondition at the moment it must hold, such as when the operation it describes completes. When only a person's real input can show the behavior, such as keyboard focus or a gesture, use `AskUserQuestion` to ask the user for a short hands-on check in place of the experiment, and record what they report the same way. When the check needs the user to act outside this session, such as in another terminal, output its numbered steps, with the exact commands and what to reply once done, as text in place of `AskUserQuestion`, record the pending check in the ledger with its steps and the log it writes, mark the iteration `awaiting hands-on check`, and end the turn; read the result from the user's reply or from a log the check writes. Mark a behavior that could not be observed as unobserved.

**Iteration 3 or later, if Step 4 of this run made changes**, the hard cap is reached. This replaces the classification gate above for iteration 3 and every iteration after it. Output a summary of what is still changing and whether it is structural or prose-only. Then use `AskUserQuestion` to offer three options: run another iteration; stop iterating, accepting the plan as-is so the workflow moves on; or escalate to `/consult-oracle` for a different perspective on the remaining issues.

Before each `AskUserQuestion` call this step makes, mark the current iteration `awaiting <gate>` in the ledger, naming the gate, and for the context-signal question the gate it wraps. Once this step has settled what follows, by a gate's answer or by an automatic re-run, mark the iteration `classified` and append the classification and the decision (another iteration, a stop, or an escalation to `/consult-oracle`). Write these before starting the re-run or the escalation, writing a handoff, or deleting the ledger. When an escalation's answer settles what follows, record that decision in place of the escalation before acting on it.

**Before acting on any gate above, check for a context signal.** Call the `mcp__turbo__context-level` tool: a reading of 25% or less remaining is one. A request from the user to compact, arriving since the session last compacted, is the other. When either is present, turn whatever this step reached, including an automatic re-run and a run that left the plan unchanged, into one `AskUserQuestion` call. Its first question asks whether to compact before what comes next: "Handoff, then compact", marked recommended, or keep going in this session, which acts on the gate's answer here. Leave it out when the user asked to compact. Its second question offers the choices of the gate this step reached, with the recommendation that gate would make; in place of an automatic re-run, it offers run another iteration, marked recommended, or stop iterating. Leave it out when Step 4 left the plan unchanged. Make no `AskUserQuestion` call when both are left out. When the plan is unchanged and TaskList shows no pending task that no `/refine-plan` iteration created, nothing remains to resume: ignore the signal and let the loop end.

**On "Handoff, then compact", or when the user asked to compact**, check first whether the gate's answer is stop iterating while TaskList shows no pending task that no `/refine-plan` iteration created. Then nothing remains to resume: tell the user so and close this step without a handoff. Otherwise run the `/handoff` skill, or, when this session already wrote a handoff, edit that file. Point its next step at what the gate's answer leads to, and once the handoff is written, update this step's task as that branch says:

- **Run another iteration** — the re-run. The handoff names the ledger path and the resolved plan path; the iteration number and the already-adjudicated list stay in the ledger. Use `TaskUpdate` to set this step's task description to the re-run: run `/refine-plan` on that plan path with ledger `<path>`. Leave the task in progress.
- **Escalate to `/consult-oracle`** — the escalation. The handoff carries the summary above and names the ledger path, which the escalation keeps, and the resolved plan path. Use `TaskUpdate` to set this step's task description to that escalation, reading the summary from the handoff at its path. Leave the task in progress.
- **Stop iterating, or the plan is unchanged** — the first pending task that no `/refine-plan` iteration created. Mark this step's task completed, along with every Step 5 task earlier iterations left in progress.

Then call the `mcp__turbo__compact-and-continue` tool with the handoff's path. End the turn in place of the TaskList call that closes this step, telling the user that the session compacts and continues on its own, and that if it does not, they should run `/compact` and then reply "continue".

**When the same class of defect recurs across iterations**, stop patching the individual instance. Count as the same class recurring a defect that swings to the opposite failure after its fix, such as a check found too strict in one round and too lax in the next. Count a design- or requirement-level defect in the mechanism an earlier round's fix added the same way. First weigh whether the plan can do without what carries the class, such as a stored value that could be read where it is used. When it can, remove it and fix every part of the plan that relied on it, unless the user chose it: then surface it as Escalate, naming the original decision and this evidence beside it. Otherwise write the root-cause invariant into the plan itself, enumerating the worked failures it must prevent. In the same pass, re-read the whole plan against the new invariant and fix every instance it catches, including text written before the invariant existed. Treat recurrence on a new axis of the same invariant as a signal that the invariant is incomplete: widen it to cover the new axis rather than assuming the latest fix failed. When the recurring defect turns on behavior nobody has observed, run that experiment, or ask for that hands-on check, before writing the invariant: an invariant derived from reasoning can be wrong in exactly the way the mechanism it replaces was wrong, and every later round is measured against it.

**When successive rounds move away from each alternative in turn on a different ground and the loop arrives back at a design an earlier round left behind**, treat that as evidence the first finding's severity was misjudged against the alternatives' failure modes. Re-examine that finding rather than inventing another mechanism: when the earlier design survives the comparison, adopt it and record that finding as Skip, citing the alternatives' failure modes; when the user chose the direction that displaced it, surface it as Escalate, naming the original decision and this evidence beside it.

**When a round has adopted a scope narrowing to limit blast radius**, check that the narrowing is derivable. The narrow case is implementable only when the fact distinguishing it from the broad case is available to the implementation at the point the rule runs, whether from persisted state, the request, configuration, or data already at hand; when nothing supplies that fact, the two cases are indistinguishable at runtime and the rule silently strands whatever it excludes. Widen back to the broad case rather than carrying a rule nothing can evaluate, unless the user chose the narrowing: then surface it as Escalate, naming the original decision and this evidence beside it.

The re-invocation is a full, fresh run of this skill, always passing the resolved path and the ledger path. Every step (1-5) executes with its own task tracking and skill invocations.

Then use the TaskList tool and proceed to any remaining task.

### Structural Edit Examples

Added or removed steps, new or removed design decisions, rewired dependencies between steps, changed acceptance criteria, changed the deployment's stated bounds, changed testing strategy.

## Rules

- Every step must run in every iteration. `/evaluate-findings` is a judgment gate that must run before `/apply-findings` touches the plan. Each step must invoke its designated skill via the Skill tool.
- Re-invocations from Step 5 are full runs with fresh task tracking and complete skill invocations.
- An invocation resuming a ledger whose last iteration is `awaiting <gate>` starts at that gate, the one exception to the rules above.
- Besides the loop ledger under `.turbo/`, the plan file is the only file that should change.
