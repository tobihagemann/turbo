# Skill Loading Rules — Reasoning

## Problem

Three failure modes were observed:

1. **Skipped sub-skills on re-run**: Running `/finalize` a second time caused Claude to skip all sub-skill invocations (e.g., `/code-style`, `/review-code`). It believed the skills were "already loaded" from the first run.

2. **Self-recursion never fires**: `/polish-code` is designed to re-run itself as its last step. Claude never actually did this — it saw `/polish-code` already in context and bailed out.

3. **Child steps bypassed via arguments**: When `/resolve-pr-comments` invoked `/polish-code`, Claude passed an argument like *"Do NOT iterate into a polish loop. Just run the two gradle commands. Skip any `/simplify-code` review loop."* The invocation itself was technically compliant (Skill tool was used), but the argument instructed the child skill to abandon its own steps. The same effect as skipping, achieved through the argument channel.

## Root Cause

The first two issues trace back to the same system prompt instruction:

> "Do not invoke a skill that is already running"

Claude over-generalizes this to mean "don't invoke a skill that was previously used in this conversation." The presence of prior skill output in context acts as a false signal that the skill is "already running."

Additionally, Claude sometimes substitutes by executing steps from memory rather than invoking the Skill tool — recalling what a skill did last time instead of loading it fresh. This is problematic because skills may have been updated, and a fresh invocation ensures the current version is used.

The third issue has a different root cause: budget-driven rationalization. The agent wants to save time or tokens, knows the "never skip" rule forbids skipping the invocation, and looks for a compliant-seeming workaround. Passing "skip the loop" as an argument feels like a loophole — the Skill tool is still called — but the effect is identical to a direct skip.

## Analysis

The system prompt's guard rail has a narrow intended meaning: don't call a skill *in the same turn* where its `<command-name>` tag already appeared (i.e., the CLI already injected it). But without clarification, Claude interprets it broadly as "once invoked, never again."

This breaks:
- **Pipelines**: `/finalize` invoking `/review-code`, `/simplify-code`, etc.
- **Parallel sub-reviews**: `/review-code` launching five type-specific review agents
- **Loops**: `/polish-code` re-invoking itself until stable
- **Routing**: `/self-improve` routing through `/create-skill`
- **Any second run**: Running the same top-level skill twice in one session

## Solution

Rules in CLAUDE.md address these failure modes:

1. **Always use the Skill tool to invoke skills** — never substitute by executing steps from memory, even if the skill was loaded earlier in this conversation, including skills invoked by other skills or by themselves.
2. **"Already running" is scoped narrowly** — it only means don't call a skill in the same turn where its `<command-name>` tag already appeared.
3. **Never skip — directly or via arguments** — skipping covers any path that prevents a step from running, whether by not invoking the skill or by passing arguments that instruct it to shortcut its own steps. An argument is legitimate only when it matches the child skill's documented interface.

The first rule addresses the general case: every skill invocation must go through the Skill tool, no shortcuts. The second rule clarifies the only exception where skipping is correct. The third rule closes the arg-bypass loophole.
