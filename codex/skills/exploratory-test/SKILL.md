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
4. Execute tests by level
5. Report

## Step 1: Load or Create Test Plan

Check if `.turbo/test-plan.md` exists.

- **If it exists** — read the test plan and continue to Step 2. If the user specifies a narrower scope, filter the plan to relevant scenarios rather than executing all of them.
- **If it does not exist** — run the `$create-test-plan` skill first, then continue.

## Step 2: Determine Testing Approach

Use the approach specified in the test plan. If the plan does not specify one, determine it using the same logic as `$create-test-plan` Step 3.

## Step 3: Run `$user-experience` Skill (When User-Facing)

If the app has a user-facing surface (UI, screens, commands, messages, or any behavior a user sees or does), run the `$user-experience` skill to load the UX lens before executing tests, so usability concerns surface while interacting with the app. When it is unclear whether the surface is user-facing, use `request_user_input` to ask rather than skipping silently. Skip this step for test targets with no user-facing behavior (internal library or infrastructure).

## Step 4: Execute Tests by Level

Work through each level sequentially. Complete all tests in a level before moving to the next.

### Execution Loop (Per Test)

1. Set up the preconditions described in the test scenario
2. Perform the exact steps
3. Capture the result (screenshot, output, or state observation)
4. Compare against the expected outcome
5. Record **PASS** or **FAIL** with details
6. When the UX lens is loaded, note any usability observation it surfaces, kept separate from the PASS/FAIL verdict

### Level Progression

1. **Level 1: Basic Functionality** — If any Level 1 test fails, report early and use `request_user_input` to ask whether to continue. Basic failures may indicate the feature is too broken for deeper testing.
2. **Level 2: Complex Operations** — Execute all tests regardless of individual failures.
3. **Level 3: Adversarial Testing** — Execute all tests. Failures here are expected and valuable.
4. **Level 4: Cross-Cutting Scenarios** — Execute all tests.

If a project-specific testing skill or MCP tool was identified in Step 2, use that. The paths below are fallbacks.

### Web App Path

Start the dev server if not already running. Wait for it to be ready. Use the `browser-use@openai-bundled` plugin to interact with the app.

### UI/Native App Path

Launch the app. Use the `computer-use@openai-bundled` plugin to interact with the UI.

### CLI Path

Run commands directly.

## Step 5: Report

Present results organized by level:

```
Exploratory Test Results:

## Level 1: Basic Functionality (X/Y passed)
- [PASS] Test name: description
- [FAIL] Test name: description — [what went wrong]

## Level 2: Complex Operations (X/Y passed)
- [PASS] Test name: description
- [FAIL] Test name: description — [what went wrong]

## Level 3: Adversarial Testing (X/Y passed)
- [PASS] Test name: description
- [FAIL] Test name: description — [what went wrong]

## Level 4: Cross-Cutting Scenarios (X/Y passed)
- [PASS] Test name: description
- [FAIL] Test name: description — [what went wrong]

Overall: X/Y passed across all levels
```

Report usability observations from the UX lens below the level results, separately from the PASS/FAIL defects. A scenario can pass every functional check and still surface a usability concern.

```
## Usability Observations
- [UX] <observation> — names the UX context it touches (Understanding, Bridging, or Flowing) and the goal mismatch or friction it creates
```

For each failure, include the relevant screenshot, output, or state observation.

Update `.turbo/test-plan.md` by checking off completed tests and annotating results.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

## Rules

- Always clean up: close browser sessions, stop dev servers started by this skill.
- Isolate shared process state so concurrent or sub-agent runs don't collide: bind dev servers and services to unique ports, scope tmux sessions (`tmux -L <name>`), and use temporary directories for scratch state.
- Never modify application code. This skill is read-only verification. Report failures without attempting to fix them.
- If the dev server fails to start, report the error and stop.
- Tail app logs in a background shell for errors or warnings while running tests, so backend failures surface alongside test observations.
- To diagnose failures, run the `$investigate` skill on the test report.
