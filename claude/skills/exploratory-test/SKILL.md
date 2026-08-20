---
name: exploratory-test
description: "Execute multi-level exploratory testing of the app covering basic functionality, complex operations, adversarial testing, and cross-cutting scenarios, plus usability observations through a UX lens reported separately from defects. Deeper than /smoke-test. Use when the user asks to \"exploratory test\", \"test thoroughly\", \"test all scenarios\", \"deep test\", \"test edge cases\", \"test everything\", \"break it\", \"find bugs by testing\", \"test usability\", or \"check the UX while testing\"."
---

# Exploratory Test

Execute multi-level exploratory testing that goes beyond smoke testing to actively find bugs through escalating test scenarios.

## Task Tracking

At the start, use `TaskCreate` to create a task for each step:

1. Load or create test plan
2. Determine testing approach
3. Run `/user-experience` skill (when user-facing)
4. Execute tests by level
5. Report

## Step 1: Load or Create Test Plan

Resolve the test plan using these rules in order:

1. **Explicit path** — If the user passed a file path, use it
2. **Explicit slug** — resolve to `.turbo/test-plans/<slug>.md`
3. **Anchoring artifact** — If the work under test is anchored to a plan, resolve to `.turbo/test-plans/<that-slug>.md` when that file exists
4. **Single file** — Glob `.turbo/test-plans/*.md`. If exactly one file exists, use it
5. **Most recent** — If multiple files exist, use the most recently modified
6. **Legacy fallback** — `.turbo/test-plan.md` if `.turbo/test-plans/` does not exist
7. **Nothing found** — run the `/create-test-plan` skill first, then use the plan it writes

If multiple test plans exist and the most-recent choice is non-obvious, use `AskUserQuestion` to let the user pick from the candidates.

Read the resolved test plan and state its path. If the user specifies a narrower scope, filter the plan to relevant scenarios rather than executing all of them.

## Step 2: Determine Testing Approach

Use the approach specified in the test plan. If the plan does not specify one, determine it using the same logic as `/create-test-plan` Step 2.

## Step 3: Run `/user-experience` Skill (When User-Facing)

If the app has a user-facing surface (UI, screens, commands, messages, or any behavior a user sees or does), run the `/user-experience` skill to load the UX lens before executing tests, so usability concerns surface while interacting with the app. When it is unclear whether the surface is user-facing, use `AskUserQuestion` to ask rather than skipping silently. Skip this step for test targets with no user-facing behavior (internal library or infrastructure).

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

1. **Level 1: Basic Functionality** — If any Level 1 test fails, report early and use `AskUserQuestion` to ask whether to continue. Basic failures may indicate the feature is too broken for deeper testing.
2. **Level 2: Complex Operations** — Execute all tests regardless of individual failures.
3. **Level 3: Adversarial Testing** — Execute all tests. Failures here are expected and valuable.
4. **Level 4: Cross-Cutting Scenarios** — Execute all tests.

If a project-specific testing skill or MCP tool was identified in Step 2, use that. The paths below are fallbacks.

### Web App Path

Reuse a running dev server only when this session started it. Otherwise start one on a port this run selected and wait for it to be ready. Confirm it bound to that port before sending it traffic — a failed bind leaves another agent's service answering. Move to another port when the port is taken; report the error and stop when the server itself failed to start. If `/agent-browser` is available, run the `/agent-browser` skill. Otherwise, use `claude-in-chrome` MCP to interact with the app.

### UI/Native App Path

Launch the app. Use `computer-use` MCP to interact with the UI.

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

Update the resolved test plan file by checking off completed tests and annotating results.

Then use the TaskList tool and proceed to any remaining task.

## Rules

- Always clean up: close only the browser sessions this run opened, by name, and stop the dev servers this skill started. Capture the PID of each dev server this run starts and stop it by that PID rather than by a name or command-line pattern, which also matches an identically named process a concurrent agent is running. Stop the process group rather than the captured PID alone — a server started behind a wrapper outlives its parent — and confirm the port released before reporting cleanup complete. Never close all browser sessions at once — concurrent agents may share the browser daemon, so a blanket close is cross-agent destruction.
- Isolate shared process state so concurrent or subagent runs don't collide: bind dev servers and services to unique ports, scope tmux sessions (`tmux -L <name>`), give each browser session a unique name so cleanup can target only its own, and write screenshots and other scratch state to absolute paths under a unique scratch directory outside the repository under test. A port picked as unique may already be held by a concurrent agent, so check it before binding and move to another when it is taken, leaving the incumbent running.
- Never modify application code. This skill is read-only verification. Report failures without attempting to fix them.
- If the dev server fails to start, report the error and stop.
- Use the Monitor tool to tail app logs for errors or warnings while running tests, so backend failures surface alongside test observations.
- To diagnose failures, run the `/investigate` skill on the test report.
