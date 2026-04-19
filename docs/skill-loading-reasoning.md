# Skill Loading Rules — Reasoning

## Problem

Failure modes observed fall into two categories: **skip** (a step doesn't run) and **stop** (the workflow ends before its remaining steps run).

### Skip problem

1. **Skipped sub-skills on re-run**: Running `/finalize` a second time caused Claude to skip all sub-skill invocations (e.g., `/code-style`, `/review-code`). It believed the skills were "already loaded" from the first run.

2. **Self-recursion never fires**: `/polish-code` is designed to re-run itself as its last step. Claude never actually did this — it saw `/polish-code` already in context and bailed out.

3. **Budget-driven skipping**: Claude skipped sub-skill invocations to "save context", treating the context window as its own problem to manage. Later broadened: saving time, tokens, or iterations is the same category, and `auto` mode plus `/loop` are where this rationalization shows up most.

4. **Child steps bypassed via arguments**: When `/resolve-pr-comments` invoked `/polish-code`, Claude passed an argument like *"Do NOT iterate into a polish loop. Just run the two gradle commands. Skip any `/simplify-code` review loop."* The invocation itself was technically compliant (Skill tool was used), but the argument instructed the child skill to abandon its own steps. The same effect as skipping, achieved through the argument channel.

### Stop problem

5. **Turn ends when a child skill finishes**: Workflow skills like `/finalize` and `/turboplan` chain multiple sub-skill invocations. After a child skill completed its own steps — especially with a clean "nothing to do" result like `/evaluate-findings` returning zero findings — Claude treated that as a turn boundary and stopped, even with a non-empty parent task list still in view.

This is structurally distinct from skipping. Skipping is "step didn't run"; stopping is "the workflow terminated early". Both manifest as missing work, but their root causes and fixes differ.

## Root Cause

### Skip problem

The re-run and self-recursion modes trace back to a single system prompt instruction:

> "Do not invoke a skill that is already running"

Claude over-generalizes this to mean "don't invoke a skill that was previously used in this conversation." The presence of prior skill output in context acts as a false signal that the skill is "already running."

Claude also sometimes substitutes by executing steps from memory rather than invoking the Skill tool — recalling what a skill did last time instead of loading it fresh. This is problematic because skills may have been updated, and a fresh invocation ensures the current version is used.

The budget-driven and argument-bypass modes have a different root cause: budget-driven rationalization. The agent wants to save context, time, tokens, or iterations; knows the "never skip" rule forbids skipping the invocation outright; and looks for a compliant-seeming workaround. Passing "skip the loop" as an argument feels like a loophole — the Skill tool is still called — but the effect is identical to a direct skip.

### Stop problem

Every skill load partially displaces continuation context: the child's instructions and output dominate the window, while the parent's unfinished task list fades into the background. When the child reaches the end of its own steps, there is no strong cue that the parent workflow still has work queued. The agent takes the path of least resistance and ends the turn.

Task tracking in the parent workflow is meant to counteract this, but it only helps if the agent actually re-reads the task list before responding. Web research at the time confirmed this is a widespread emergent behavior with no reliable prompt-level fix — only mitigations.

## Analysis

The system prompt's guard rail has a narrow intended meaning: don't call a skill *in the same turn* where its `<command-name>` tag already appeared (i.e., the CLI already injected it). But without clarification, Claude interprets it broadly as "once invoked, never again."

This breaks:

- **Pipelines**: `/finalize` invoking `/review-code`, `/simplify-code`, etc.
- **Parallel sub-reviews**: `/review-code` launching five type-specific review agents
- **Loops**: `/polish-code` re-invoking itself until stable
- **Routing**: `/self-improve` routing through `/create-skill`
- **Any second run**: Running the same top-level skill twice in one session

Separately, the stop problem breaks any workflow skill that chains multiple sub-skill invocations — `/finalize` and `/turboplan` are the canonical examples.

## Solution

Rules under the Skill Loading section of CLAUDE.md cover four concerns:

- **Invocation discipline** — every skill load goes through the Skill tool. No substitution by executing steps from memory, even if the skill was loaded earlier, including skills invoked by other skills or by themselves.
- **Scope of "already running"** — the phrase only means don't call a skill in the same turn where its `<command-name>` tag already appeared.
- **Closing skip loopholes** — skipping covers any path that prevents a step from running: not invoking the skill, rationalizing that context, time, tokens, or iterations need saving (including in `auto` mode or `/loop`), or passing arguments that instruct the child to shortcut its own steps. An argument is legitimate only when it matches the child skill's documented interface. The harness manages these budgets; the agent does not.
- **Stop-problem mitigation** — after following a skill's instructions to completion, check the task list before responding. Child skills may have their own task tracking, and completing all of a child's tasks does not mean the parent workflow is done.

The first three concerns address the skip problem from complementary angles. The last addresses the stop problem.

## Defense in depth

The task-list-check rule alone turned out to be insufficient. After it shipped, the stop problem still occurred in sessions where the rule was in context and the task list was visible. A single prose rule can't reliably override a strong emergent "turn-boundary" signal. The mitigation is layered:

- **Global rule in CLAUDE.md** — the task-list-check baseline applies to every skill completion, anywhere in the conversation.
- **Per-skill continuation line** — child skills with explicit numbered steps end their last step with: *"Then use the TaskList tool and proceed to any remaining task."* Placing the cue at the exact moment execution ends (not buried in a trailing Rules section) puts it where the stop-decision gets made. The tool call is a concrete required action that breaks the end-of-turn pull more reliably than the earlier prose phrasing *"check your task list for remaining tasks and proceed"* — with the prose form, the stop problem still occurred even when the rule was in context and the task list was visible. See the corresponding convention in `SKILL-CONVENTIONS.md`.
- **No handoff sentences in child skills** — sentences like *"Return findings to the caller"* or *"Return results for the main agent to act on"* read as end-of-turn signals and must not appear anywhere in the body, including intros. "Caller" and "main agent" framing is itself part of the problem: there is no caller in a function-call sense, only the same agent continuing through more prompting.

Removing any one layer regresses the behavior. The global rule was briefly removed in favor of the per-skill line alone, then restored — flakiness persisted without it.
