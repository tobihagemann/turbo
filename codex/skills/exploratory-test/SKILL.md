---
name: exploratory-test
description: "Execute multi-level exploratory testing of the app covering basic functionality, complex operations, adversarial testing, and cross-cutting scenarios, plus usability observations through a UX lens reported separately from defects. Deeper than $smoke-test. Use when the user asks to \"exploratory test\", \"test thoroughly\", \"test all scenarios\", \"deep test\", \"test edge cases\", \"test everything\", \"break it\", \"find bugs by testing\", \"test usability\", or \"check the UX while testing\"."
---

# Exploratory Test

Execute multi-level exploratory testing that goes beyond smoke testing to actively find bugs through escalating test scenarios.

## Task Tracking

At the start, use `update_plan` to track each step, restating any remaining steps of a parent workflow alongside them:

1. Load or create test plan
2. Determine testing approach
3. Run `$user-experience` skill (when user-facing)
4. Run `$test-run-rules` skill
5. Execute tests by level
6. Report

## Step 1: Load or Create Test Plan

Resolve the test plan using these rules in order:

1. **Explicit path** — If a file path was passed, use it
2. **Explicit slug** — resolve to `.turbo/test-plans/<slug>.md`
3. **Anchoring artifact** — If the work under test is anchored to a plan, resolve to `.turbo/test-plans/<that-slug>.md` when that file exists
4. **Single file** — Glob `.turbo/test-plans/*.md`. If exactly one file exists, use it
5. **Most recent** — If multiple files exist, use the most recently modified
6. **Legacy fallback** — `.turbo/test-plan.md` if `.turbo/test-plans/` does not exist
7. **Nothing found** — run the `$create-test-plan` skill first, then use the plan it writes

If multiple test plans exist and the most-recent choice is non-obvious, use `request_user_input` to let the user pick from the candidates.

Read the resolved test plan and state its path.

Unless an explicit path or slug was passed, confirm the resolved plan still describes the work under test:

- **Unavailable branch state** — a scenario's steps require a branch that no longer resolves in the repository
- **Completed prior run** — every checkbox is already ticked and no recorded result is FAIL or PARTIAL
- **Superseded context** — the plan's Context section names work that changes merged since the plan was written have reversed or removed

When a signal fires, output the signal and the scenarios it affects as text. For a superseded Context, name the scenarios that exercise the reversed or removed work. Then use `request_user_input` to offer:

- **Regenerate** — run the `$create-test-plan` skill with the resolved path, and use the plan it writes
- **Execute anyway** — the signal is a false positive
- **Pick another plan** — resolve to a different test plan file, then confirm that plan against these same signals

If the user specifies a narrower scope, filter the plan to relevant scenarios rather than executing all of them. Reserve filtering for that case: a superseded plan keeps scenarios that each look plausible alone, so trimming it preserves the wrong ones.

## Step 2: Determine Testing Approach

Use the approach specified in the test plan. If the plan does not specify one, determine it using the same logic as `$create-test-plan` Step 2.

## Step 3: Run `$user-experience` Skill (When User-Facing)

If the app has a user-facing surface (UI, screens, commands, messages, or any behavior a user sees or does), run the `$user-experience` skill to load the UX lens before executing tests, so usability concerns surface while interacting with the app. When it is unclear whether the surface is user-facing, use `request_user_input` to ask rather than skipping silently. Skip this step for test targets with no user-facing behavior (internal library or infrastructure).

## Step 4: Run `$test-run-rules` Skill

Run the `$test-run-rules` skill to load the rules for launching and driving the app.

## Step 5: Execute Tests by Level

Work through each level sequentially. Complete all tests in a level before moving to the next.

### Execution Loop (Per Test)

1. Set up the preconditions described in the test scenario
2. Perform the exact steps
3. Capture the result (screenshot, output, or state observation)
4. Compare against the expected outcome
5. Record **PASS**, **FAIL**, or **PARTIAL** with details
6. When the UX lens is loaded, note any usability observation it surfaces, kept separate from the verdict

Record a scenario the test run rules leave blocked or inconclusive as **PARTIAL**, naming what is unproven and why.

When the scenario's output is consumed by another system, withhold PASS until that system accepts it. Decoding a token, reading a response body, or confirming a row exists shows only that the artifact was produced. Stand up the consumer under the same isolation and cleanup rules as any other service this run starts, and exercise its own flow. When standing it up is not possible, record **PARTIAL** and name which half is unproven. PARTIAL counts as not passed everywhere a verdict is tallied or gated.

### Level Progression

1. **Level 1: Basic Functionality** — If any Level 1 test does not pass, report early and use `request_user_input` to ask whether to continue. Basic failures may indicate the feature is too broken for deeper testing.
2. **Level 2: Complex Operations** — Execute all tests regardless of individual failures.
3. **Level 3: Adversarial Testing** — Execute all tests. Failures here are expected and valuable.
4. **Level 4: Cross-Cutting Scenarios** — Execute all tests.

If a project-specific testing skill or MCP tool was identified in Step 2, use that. The paths below are fallbacks.

### Web App Path

Start or reuse a dev server under the test run rules. Use the `browser-use@openai-bundled` plugin to interact with the app.

### UI/Native App Path

Launch the app. Use the `computer-use@openai-bundled` plugin to interact with the UI.

### CLI Path

Run commands directly.

## Step 6: Report

Present results organized by level:

```
Exploratory Test Results:

## Level 1: Basic Functionality (X/Y passed)
- [PASS] Test name: description — [substitution, when one was driven]
- [FAIL] Test name: description — [what went wrong]
- [PARTIAL] Test name: description — [what is unproven, and why]

## Level 2: Complex Operations (X/Y passed)
- [PASS] Test name: description — [substitution, when one was driven]
- [FAIL] Test name: description — [what went wrong]
- [PARTIAL] Test name: description — [what is unproven, and why]

## Level 3: Adversarial Testing (X/Y passed)
- [PASS] Test name: description — [substitution, when one was driven]
- [FAIL] Test name: description — [what went wrong]
- [PARTIAL] Test name: description — [what is unproven, and why]

## Level 4: Cross-Cutting Scenarios (X/Y passed)
- [PASS] Test name: description — [substitution, when one was driven]
- [FAIL] Test name: description — [what went wrong]
- [PARTIAL] Test name: description — [what is unproven, and why]

Overall: X/Y passed across all levels
```

Report usability observations from the UX lens below the level results, separately from the defects. A scenario can pass every functional check and still surface a usability concern.

```
## Usability Observations
- [UX] <observation> — names the UX context it touches (Understanding, Bridging, or Flowing) and the goal mismatch or friction it creates
```

For each failure, include the relevant screenshot, output, or state observation.

When the change under test spans several repositories, add a per-repo view of the findings below the usability observations, naming a suggested fix site for each.

Update the resolved test plan file by checking off completed tests and annotating results.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

## Rules

- To diagnose failures, run the `$investigate` skill on the test report.
