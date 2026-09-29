---
name: smoke-test
description: "Launch the app and hands-on verify that it works by interacting with it. Falls back to an existing integration test suite when there is no interactive surface in scope. Use when the user asks to \"smoke test\", \"test it manually\", \"verify it works\", \"try it out\", \"run a smoke test\", \"check it in the browser\", or \"does it actually work\". Not a unit test runner."
---

# Smoke Test

Launch the app and hands-on verify that it works by interacting with it. Every smoke test is a concrete interaction with the running app: navigating a screen, clicking a control, filling a form, running a CLI command, and observing the result.

## Step 1: Determine Scope

Resolve scope using the first match:

1. **User-specified** — the user says what to test. Use that.
2. **PR** — a PR URL or number is provided. Fetch the PR details (title, description, changed files, comments) and read the changed code.
3. **Conversation context** — prior conversation contains recent work (a feature, fix, or refactor). Extract what changed, where it lives, and expected behavior.
4. **App-level discovery** — fresh context with no prior work. Examine the project (entry points, routes, commands, README) to identify the app's core user-facing flows. Design tests that verify the app launches and its primary functionality works end-to-end.

## Step 2: Determine Testing Approach

Always check for project-specific testing skills or MCP tools first. Use the fallbacks below when nothing project-specific is available:

- **Web app** → `/agent-browser` skill if available, otherwise `claude-in-chrome` MCP
- **UI/native app** → `computer-use` MCP
- **CLI tool** → direct terminal execution
- **Library with no entry point** → report that smoke testing is not applicable and stop, unless the scope changes a check's configuration; then use direct terminal execution

## Step 3: Run `/test-run-rules` Skill

Run the `/test-run-rules` skill to load the rules for launching and driving the app.

## Step 4: Plan Smoke Tests

Before drafting tests, check whether there is something to exercise:

- **The scope changes a check's configuration** (linter, formatter, type checker, or CI gate rules) — for that part of the scope, the check itself is the surface; plan tests against it and run them via the CLI Path in Step 5. Export the tree carrying the change to a scratch directory outside the checkout, add input there that each changed rule should flag or accept, and run the check on it. Pair each case with the same input under the configuration at the ref the resolved scope is measured against as its control, so a verdict the old configuration also produces is not credited to the change. Reach the check's installed toolchain and plugins from the scratch directory without installing into or modifying the checkout; when the check cannot run there, report the case unverified. When the change adds or narrows a suppression and the check reports unused suppressions, add a case with the suppressed cause removed and confirm the check reports the stale suppression.
- **No user-visible change in the resolved scope** — look for an existing integration test target that covers the change and is not part of the default test suite (so it hasn't already run in this session). If one exists, run it via the Integration Test Path in Step 5. If nothing exists, report that there is no interactive surface to verify and no separate integration suite to fall back on, then stop.
- **Required infrastructure cannot be stood up in this session** (backend service, auth provider, external dependency) — look for a stub under the test run rules before reporting blocked. When a stub works, record its response shapes and state transitions in the Setup contract's **Mock boundaries** item, along with the re-install condition for a call-site stub, and the PID and port of any stub process in **Owned cleanup**, then carry on with the plan. When the rules leave the scenario blocked, report blocked, naming what is missing and what was tried, then stop.
- **A test needs privileged state or a second participant** (an entitlement or plan tier, an elevated role, seed data, a second concurrent client or session) — provision it under the test run rules. Keep the test in the plan once provisioning succeeds, and record the granted state in the Setup contract's **Test identity** item and every session, role, and record this run creates in **Owned cleanup**. Drop the test to unverified only after an attempt failed.

Otherwise, design targeted smoke tests. Each test should:

1. Exercise a specific flow from the determined scope
2. Verify the happy path works end-to-end
3. Check one obvious edge case if applicable

Confirm any control, command, or other affordance a test names exists in the code before writing the test: search for the API that would implement it rather than inferring it from what the feature does. Where it cannot be confirmed, write the test against the outcome to verify and leave the affordance to be found during execution.

Confirm as well that the surface accepts a test's action in the state the test sets up. When the code refuses or swallows that action there, drive a state or entry point where the action goes through, or make the refusal itself the observation. When a scenario claims an affordance is available in a state, drive each such affordance in that state to its first observable effect and make that effect the pass condition; a refusal or swallowed action there fails the scenario. For an affordance whose effect is not cleanly undoable, stop at its confirmation step and cancel it. When the affordance has no confirmation step, act on a record this run created, record it in **Owned cleanup**, and carry any write to a shared external system through the test run rules' write sequence; plan the scenario as unverified when no such record can be created.

Output the plan as text:

```
Smoke Test Plan:
1. [Interaction with the running app] — what the interaction verifies
2. [Interaction with the running app] — what the interaction verifies
3. [Interaction with the running app] — what the interaction verifies

Approach: [agent-browser / claude-in-chrome / computer-use / terminal]
Dev server command: [command]
```

When another agent will execute this plan, append a **Setup contract** capturing what the executor needs and cannot safely rediscover:

- **Start environment** — commands and variables to bring up each service in isolation
- **Test identity** — the account or credentials the run authenticates as
- **Seed/reset** — operations that establish or restore baseline data, plus the enumeration, the pre-run manifest, and the revert procedure of every write the plan authorizes
- **Required state** — fixtures or preconditions each scenario depends on, including the validation constraints any payload the plan injects must satisfy to reach the code under test
- **Mock boundaries** — external services stubbed, with the response shapes and state transitions to return
- **Owned cleanup** — named sessions, ports, PIDs, and scratch resources this run creates and must release

Include an item when the executor would otherwise derive it from application source, or when it is state this run generated that the executor cannot rediscover safely; omit anything the running app makes self-evident. Require these details when the chosen testing approach prohibits reading application source as setup documentation.

Write each precondition as an observation the executor makes rather than a fact it can rely on, and say what to do when it does not hold: name the substitute setup, or direct the executor to report the precondition as wrong rather than the scenario as failed.

**When the scope's happy path writes to a shared external system and those writes are not cleanly undoable**, scope the plan to a path that provably cannot write: choose fixture data with nothing to act on, as the test run rules direct. State that scoping choice in the plan so the executor does not widen it back. When the writing path must run, work through the test run rules' write sequence.

**When a scenario's pass condition is that nothing happens** — no write, no call, no state change — pair it with a control that differs only in the dimension under test and whose expected outcome is that the effect does occur. A lone negative scenario cannot distinguish the behavior under test from a harness that never reached it. Pair each guard separately.

When the scenario drives one of the inputs below, establish while writing the plan that it reaches the code under test. An input refused before it gets there produces the expected absence for the wrong reason, and the control does not distinguish that from the behavior under test:

- **Crafted payload** — establish that the payload satisfies every validation layer between the injection point and the code under test, and record those constraints in the Setup contract's **Required state** item: a payload rejected at a parse boundary is refused before the code under test. State which layers the trace cannot settle rather than presenting the path as clear, and plan the scenario as inconclusive when the payload's reachability stays unestablished.
- **Repeat invocation** — when the guard under test rejects a repeat invocation, establish that the affordance the scenario drives can be invoked a second time: a busy or pending state on that affordance refuses the repeat before the guard sees it. Name an entry point carrying no such state when the primary one has it, and plan the scenario as inconclusive when the repeat's reachability stays unestablished.

Run the control through a stub that intercepts the mechanism, introducing one when the negative scenario was scoped by fixture data alone, so observing the effect there establishes that the interception point is reached:

- **A call the code under test makes** — a call-site stub is the cheapest interception: keep it installed across both runs and vary only the dimension under test, so the control's call is observed at the stub instead of reaching the real dependency.
- **No stub can intercept the mechanism** — carry the control through the test run rules' write sequence, and record it in the plan as authorized scope rather than a widening.
- **Neither control can run** — plan the negative scenario as inconclusive and say so.

## Step 5: Execute

If a project-specific testing skill or MCP tool was identified in Step 2, use that. The paths below are fallbacks.

### Web App Path

Start or reuse a dev server under the test run rules. If `/agent-browser` is available, run the `/agent-browser` skill. Otherwise, use `claude-in-chrome` MCP to interact with the app.

Core verification loop per test:

1. Navigate to the relevant page/route
2. Snapshot and verify expected UI elements exist
3. Interact (fill forms, click buttons, navigate)
4. Re-snapshot and verify the expected outcome
5. Record pass/fail

Close the browser session and stop the dev server when done.

### UI/Native App Path

Launch the app. Use `computer-use` MCP to interact with the UI.

Core verification loop per test:

1. Capture the UI state
2. Interact with the relevant controls
3. Re-capture and verify the expected outcome
4. Record pass/fail

### CLI Path

Run commands directly.

Core verification loop per test:

1. Run the command with expected inputs
2. Check stdout/stderr for expected output
3. Verify side effects (files created, data changed)
4. Record pass/fail

### Integration Test Path

Fallback when Step 4 routed here because nothing was interactive. Run multiple integration targets sequentially when they reset or mutate a shared test database, even when the checks are otherwise independent. Use the Monitor tool to tail output for long-running suites so failures surface as they happen.

Core verification loop per run:

1. Run the command
2. Capture the command's own exit code and its full summary output, never output filtered for selected summary lines
3. Record pass/fail per named test when the output exposes them, otherwise overall. A nonzero exit fails the run even when every named test passed

Do not invent a target if none was found in Step 4 — that gate already stopped.

## Step 6: Report

Record a test the test run rules leave blocked as **UNVERIFIED** and one they leave inconclusive as **INCONCLUSIVE**.

Before reporting a planned test as unverified, retry its setup under the test run rules for unavailable infrastructure and for privileged state, unless Step 4 already tried them and they failed. When the setup succeeds, run the test and record its result. Report a test as unverified only after that attempt, naming what was tried and what blocked it. Treat an existing unit test over the same behavior as no substitute: it leaves the interactive path unexercised.

Report a negative test and its control together: the negative reads as passed only when its control produced the effect, and as inconclusive otherwise.

Present a summary:

```
Smoke Test Results:
- [PASS] Test 1: description — [substitution, when one was driven]
- [FAIL] Test 2: description — [what went wrong]
- [UNVERIFIED] Test 3: description — [what was tried, what blocked it]
- [INCONCLUSIVE] Test 4: description — [why the result cannot be read]

Overall: X/Y passed, Z unverified, W inconclusive
```

If any test failed, include the relevant snapshot, screenshot, or output showing the failure.

Then use the TaskList tool and proceed to any remaining task.

## Rules

- Keep tests focused on the determined scope.
- When the scope has an interactive surface, drive that surface directly — a CLI command, HTTP request, or UI interaction — rather than importing an internal function to print its result or re-running the unit test suite. The Integration Test Path is the only sanctioned non-interactive fallback.
- To diagnose failures, run the `/investigate` skill on the smoke test report.
