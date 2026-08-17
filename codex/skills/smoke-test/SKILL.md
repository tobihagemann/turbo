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

- **Web app** → `browser-use@openai-bundled` plugin
- **UI/native app** → `computer-use@openai-bundled` plugin
- **CLI tool** → direct terminal execution
- **Library with no entry point** → report that smoke testing is not applicable and stop

## Step 3: Plan Smoke Tests

Before drafting tests, check whether there is something to exercise:

- **No user-visible change in the resolved scope** — look for an existing integration test target that covers the change and is not part of the default test suite (so it hasn't already run in this session). If one exists, run it via the Integration Test Path in Step 4. If nothing exists, report that there is no interactive surface to verify and no separate integration suite to fall back on, then stop.
- **Required infrastructure cannot be stood up in this session** (backend service, auth provider, seed data, external dependency) — look for a stub before reporting blocked. When the dependency is reached through a client whose endpoint is runtime configuration, repoint that endpoint at a local stub; the same interception yields an artifact the system emits rather than provides (a token, a session identifier, a single-use link). Confine this to runtime configuration and leave the working tree unchanged. When a stub works, record it in the Setup contract's **Mock boundaries** item and carry on with the plan. Report blocked when no stub applies or the ones that do fail, naming what is missing and what was tried, then stop.

Otherwise, design targeted smoke tests. Each test should:

1. Exercise a specific flow from the determined scope
2. Verify the happy path works end-to-end
3. Check one obvious edge case if applicable

Output the plan as text:

```
Smoke Test Plan:
1. [Interaction with the running app] — what the interaction verifies
2. [Interaction with the running app] — what the interaction verifies
3. [Interaction with the running app] — what the interaction verifies

Approach: [browser-use@openai-bundled / computer-use@openai-bundled / terminal]
Dev server command: [command]
```

When another agent will execute this plan, append a **Setup contract** capturing what the executor needs and cannot safely rediscover:

- **Start environment** — commands and variables to bring up each service in isolation
- **Test identity** — the account or credentials the run authenticates as
- **Seed/reset** — operations that establish or restore baseline data, plus the enumerated write set when the plan authorizes writes
- **Required state** — fixtures or preconditions each scenario depends on
- **Mock boundaries** — external services stubbed, with the response shapes and state transitions to return
- **Owned cleanup** — named sessions, ports, and scratch resources this run creates and must release

Include an item only when the executor would otherwise derive it from application source; omit anything the running app makes self-evident. Require these details when the chosen testing approach prohibits reading application source as setup documentation.

Write each precondition as an observation the executor makes rather than a fact it can rely on, and say what to do when it does not hold: name the substitute setup, or direct the executor to report the precondition as wrong rather than the scenario as failed.

**When the scope's happy path writes to a shared external system and those writes are not cleanly undoable**, scope the plan to a path that provably cannot write: choose fixture data with nothing to act on, so the run still exercises wiring, auth, queries, guards, and failure isolation while writing nothing. Treat writes as not cleanly undoable whenever restoring the records leaves downstream effects the writes triggered in place. State that scoping choice in the plan so the executor does not widen it back. When the writing path must run, work through it in order. Determine the full write set without executing it: use a dry-run mode when one exists, otherwise trace the code path and enumerate every record it writes, including those reached through triggers, cascades, and hooks. State what the enumeration cannot settle rather than presenting it as complete. Pick the target whose writes are incidental to what the run verifies, weighing each candidate's write set against the coverage it adds. Then request approval via `request_user_input`, presenting the enumeration as what is being consented to, and request it again whenever the enumeration changes. When `request_user_input` does not reach the user, write nothing and report the approval as unresolved. Capture a pre-run manifest and write an ordered revert procedure; when another agent will execute the plan, carry the enumeration, the manifest, and the revert procedure in the Setup contract's **Seed/reset** item.

## Step 4: Execute

If a project-specific testing skill or MCP tool was identified in Step 2, use that. The paths below are fallbacks.

### Web App Path

Start the dev server if not already running. Wait for it to be ready. Use the `browser-use@openai-bundled` plugin to interact with the app.

Core verification loop per test:

1. Navigate to the relevant page/route
2. Snapshot and verify expected UI elements exist
3. Interact (fill forms, click buttons, navigate)
4. Re-snapshot and verify the expected outcome
5. Record pass/fail

Close the browser session and stop the dev server when done.

### UI/Native App Path

Launch the app. Use the `computer-use@openai-bundled` plugin to interact with the UI.

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

Fallback when Step 3 routed here because nothing was interactive. Run the discovered target. Run multiple integration targets sequentially when they reset or mutate a shared test database, even when the checks are otherwise independent. Tail output in a background shell for long-running suites so failures surface as they happen.

Core verification loop per run:

1. Run the command
2. Capture exit code and the relevant summary output
3. Record pass/fail per named test when the output exposes them, otherwise overall

Do not invent a target if none was found in Step 3 — that gate already stopped.

## Step 5: Report

Present a summary:

```
Smoke Test Results:
- [PASS] Test 1: description
- [FAIL] Test 2: description — [what went wrong]
- [PASS] Test 3: description

Overall: X/Y passed
```

If any test failed, include the relevant snapshot, screenshot, or output showing the failure.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

## Rules

- Always clean up: close only the browser sessions this run opened, by name, stop the dev servers and stubs this skill started, and restore any configuration it repointed. Never close all browser sessions at once — concurrent agents may share the browser daemon, so a blanket close is cross-agent destruction.
- Isolate shared process state so concurrent or sub-agent runs don't collide: bind dev servers and services to unique ports, scope tmux sessions (`tmux -L <name>`), give each browser session a unique name so cleanup can target only its own, and write screenshots and other scratch state to absolute paths under a unique scratch directory outside the repository under test.
- Never modify code. This skill is read-only verification, with one exception: a stub reached through runtime configuration, restored on cleanup. If a test fails, report the failure — do not attempt to fix it.
- If the dev server fails to start, report the error and stop.
- Keep tests focused on the determined scope.
- When the scope has an interactive surface, drive that surface directly — a CLI command, HTTP request, or UI interaction — rather than importing an internal function to print its result or re-running the unit test suite. The Integration Test Path is the only sanctioned non-interactive fallback.
- Tail app logs in a background shell for errors or warnings while verifying, so backend failures surface alongside UI checks.
- After the last UI interaction, perform one additional log read or status check before reporting. Background-shell output that lands after the agent emits final text is not surfaced, so the extra action gives it time to appear in a polled read. Matters most when this skill runs inside a sub-agent. When this check targets a server or log process you did not start, report it as outstanding for the process owner rather than running it yourself; inability to read such a process is outstanding, not a smoke failure.
- To diagnose failures, run the `$investigate` skill on the smoke test report.
