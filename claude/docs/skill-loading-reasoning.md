# Skill Loading Rules — Reasoning

## Problem

Failure modes observed fall into two categories: **skip** (a step doesn't run) and **stop** (the workflow ends before its remaining steps run).

### Skip problem

1. **Skipped sub-skills on re-run**: Running `/finalize` a second time caused Claude to skip all sub-skill invocations (e.g., `/code-style`, `/review-code`). It believed the skills were "already loaded" from the first run.

2. **Self-recursion never fires**: `/polish-code` is designed to re-run itself as its last step. Claude never actually did this — it saw `/polish-code` already in context and bailed out.

3. **Budget-driven skipping**: Claude skipped sub-skill invocations to "save context", treating the context window as its own problem to manage. Later broadened: saving time, tokens, or iterations is the same category, and `auto` mode plus `/loop` are where this rationalization shows up most.

4. **Child steps bypassed via arguments**: When `/resolve-pr-comments` invoked `/polish-code`, Claude passed an argument like *"Do NOT iterate into a polish loop. Just run the two gradle commands. Skip any `/simplify-code` review loop."* The invocation itself was technically compliant (Skill tool was used), but the argument instructed the child skill to abandon its own steps. The same effect as skipping, achieved through the argument channel.

5. **Branch merging**: `/review-code` specifies seven parallel agents (six internal — one per review type — plus one peer). On a small diff, Claude collapsed the six internal agents into a single subagent told to apply all six criteria sequentially, reasoning that six agents each re-reading the same 25-line diff would duplicate work. All six criteria were still applied, so from the agent's view nothing was "dropped" — only merged. But context independence and parallelism were destroyed, which are the properties the skill's fan-out exists to provide. This is a budget-driven variant that looks like efficiency rather than skipping, which is why the "never skip" rule didn't fire.

### Stop problem

6. **Turn ends when a child skill finishes**: Workflow skills like `/finalize` and `/turboplan` chain multiple sub-skill invocations. After a child skill completed its own steps — especially with a clean "nothing to do" result like `/evaluate-findings` returning zero findings — Claude treated that as a turn boundary and stopped, even with a non-empty parent task list still in view.

7. **Stops cascade within a session**: Once Claude has ended a turn at one skill boundary — typically after composing a prose "completion" summary — it tends to repeat the pattern at subsequent skill boundaries, even when those downstream skills are well-behaved. A single unmitigated stall can trigger a chain. Continuation framing at the earliest leaf skill in a chain therefore tends to prevent stalls downstream. Transcript review bears this out: in two separate sessions a stalled `/apply-findings` was followed by a stall at a downstream skill that does not stall on its own.

8. **Long runs stall where short ones don't**: `/apply-findings` stalls only after heavy runs. Across 306 recorded runs, none under 60 tool calls stalled (0/283), while 4 of 23 longer runs did. Stalled runs had a median of 142 tool calls against 12 for clean ones. The work itself was irreducible — applying dozens of findings across dozens of files — so the run length was not a symptom of the skill doing anything wrong.

This is structurally distinct from skipping. Skipping is "step didn't run"; stopping is "the workflow terminated early". Both manifest as missing work, but their root causes and fixes differ.

## Root Cause

### Skip problem

The re-run and self-recursion modes trace back to a single system prompt instruction:

> "Do not invoke a skill that is already running"

Claude over-generalizes this to mean "don't invoke a skill that was previously used in this conversation." The presence of prior skill output in context acts as a false signal that the skill is "already running."

Claude also sometimes substitutes by executing steps from memory rather than invoking the Skill tool — recalling what a skill did last time instead of loading it fresh. This is problematic because skills may have been updated, and a fresh invocation ensures the current version is used.

The budget-driven, argument-bypass, and branch-merging modes share a root cause: budget-driven rationalization. The agent wants to save context, time, tokens, or iterations; knows "never skip" forbids skipping outright; and looks for a compliant-seeming workaround. The argument-bypass variant uses the child's argument channel — the Skill tool is still called, so it doesn't feel like skipping. The branch-merging variant preserves the skill's criteria in one subagent — no criterion was dropped, so it doesn't feel like skipping either. Both are still skipping; the rationalization obscures it.

### Stop problem

Every skill load partially displaces continuation context: the child's instructions and output dominate the window, while the parent's unfinished task list fades into the background. When the child reaches the end of its own steps, there is no strong cue that the parent workflow still has work queued. The agent takes the path of least resistance and ends the turn.

Two separate displacements are at work. A skill load displaces the parent's task list, as above. A long run additionally displaces the child's own continuation line: by the time execution reaches the last step, that instruction sits hundreds of intervening tool results back. The two compound, which is why a long child skill is the most reliable place to observe a stall.

What the agent emits at that moment matters as much as what it can still see. Where the last step calls for a prose summary, the agent composes a formatted report, and that block becomes its final output — occupying the same position the continuation cue needs. Item 7's observation that stalls follow a prose "completion" summary is this effect seen from the outside.

Task tracking in the parent workflow is meant to counteract this, but it only helps if the agent actually re-reads the task list before responding. Web research at the time confirmed this is a widespread emergent behavior with no reliable prompt-level fix — only mitigations.

## Analysis

The system prompt's guard rail has a narrow intended meaning: don't call a skill *in the same turn* where its `<command-name>` tag already appeared (i.e., the CLI already injected it). But without clarification, Claude interprets it broadly as "once invoked, never again."

This breaks:

- **Pipelines**: `/finalize` invoking `/review-code`, `/simplify-code`, etc.
- **Parallel sub-reviews**: `/review-code` launching six type-specific review agents plus a peer-review agent
- **Loops**: `/polish-code` re-invoking itself until stable
- **Routing**: `/self-improve` routing through `/create-skill`
- **Any second run**: Running the same top-level skill twice in one session

Separately, the stop problem breaks any workflow skill that chains multiple sub-skill invocations — `/finalize` and `/turboplan` are the canonical examples.

## Solution

Rules under the Skill Loading section of CLAUDE.md cover six concerns:

- **Invocation discipline** — every skill load goes through the Skill tool. No substitution by executing steps from memory, even if the skill was loaded earlier, including skills invoked by other skills or by themselves.
- **Scope of "already running"** — the phrase only means don't call a skill in the same turn where its `<command-name>` tag already appeared.
- **No budget-driven skipping** — skipping a step, invocation, or parallel branch to save context, time, tokens, or iterations is always the wrong trade-off, including in `auto` mode or `/loop`. The harness manages these budgets; the agent does not.
- **Legitimate arguments only** — arguments to a child skill must match its documented interface. Ad-hoc overrides that instruct the child to shortcut its own steps or loop are skipping through a different channel.
- **No branch merging** — collapsing N parallel calls into fewer that sequentially cover the same work destroys context independence and parallelism, even when all criteria are preserved. The branch count a skill specifies is a floor, not a ceiling.
- **Stop-problem mitigation** — after following a skill's instructions to completion, check the task list before responding. Child skills may have their own task tracking, and completing all of a child's tasks does not mean the parent workflow is done.

The first five concerns address the skip problem from complementary angles. The last addresses the stop problem.

## Defense in depth

The task-list-check rule alone turned out to be insufficient. After it shipped, the stop problem still occurred in sessions where the rule was in context and the task list was visible. A single prose rule can't reliably override a strong emergent "turn-boundary" signal. The mitigation is layered:

- **Global rule in CLAUDE.md** — the task-list-check baseline applies to every skill completion, anywhere in the conversation.
- **Per-skill continuation line** — child skills with explicit numbered steps end their last step with: *"Then use the TaskList tool and proceed to any remaining task."* Placing the cue at the exact moment execution ends (not buried in a trailing Rules section) puts it where the stop-decision gets made. The tool call is a concrete required action that breaks the end-of-turn pull more reliably than the earlier prose phrasing *"check your task list for remaining tasks and proceed"* — with the prose form, the stop problem still occurred even when the rule was in context and the task list was visible. See the corresponding convention in `SKILL-CONVENTIONS.md`.
- **Continuation framing in child skills** — child skills frame the body in second-person, agent-facing voice: the same agent continuing through more prompting. Third-party framing like *"Return findings to the caller"* or *"Return results for the main agent to act on"* reads as an end-of-turn signal — "caller" and "main agent" are themselves part of the problem, since there is no caller in a function-call sense, only the same agent continuing.
- **Bounded terminal output** — where the last step produces a report, it specifies a table with stated row and cell bounds rather than a prose summary. A large prose deliverable reads as the turn's product and competes for the position the continuation cue occupies; a bounded table does not. This layer addresses what the agent emits; the other three address where the cue sits.

Removing any one layer regresses the behavior. The global rule was briefly removed in favor of the per-skill line alone, then restored — flakiness persisted without it.
