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

1. **Explicit path** — If a file path was passed, use it
2. **Explicit slug** — resolve to `.turbo/test-plans/<slug>.md`
3. **Anchoring artifact** — If the work under test is anchored to a plan, resolve to `.turbo/test-plans/<that-slug>.md` when that file exists
4. **Single file** — Glob `.turbo/test-plans/*.md`. If exactly one file exists, use it
5. **Most recent** — If multiple files exist, use the most recently modified
6. **Legacy fallback** — `.turbo/test-plan.md` if `.turbo/test-plans/` does not exist
7. **Nothing found** — run the `/create-test-plan` skill first, then use the plan it writes

If multiple test plans exist and the most-recent choice is non-obvious, use `AskUserQuestion` to let the user pick from the candidates.

Read the resolved test plan and state its path.

Unless an explicit path or slug was passed, confirm the resolved plan still describes the work under test:

- **Unavailable branch state** — a scenario's steps require a branch that no longer resolves in the repository
- **Completed prior run** — every checkbox is already ticked and no recorded result is FAIL or PARTIAL
- **Superseded context** — the plan's Context section names work that changes merged since the plan was written have reversed or removed

When a signal fires, output the signal and the scenarios it affects as text. For a superseded Context, name the scenarios that exercise the reversed or removed work. Then use `AskUserQuestion` to offer:

- **Regenerate** — run the `/create-test-plan` skill with the resolved path, and use the plan it writes
- **Execute anyway** — the signal is a false positive
- **Pick another plan** — resolve to a different test plan file, then confirm that plan against these same signals

If the user specifies a narrower scope, filter the plan to relevant scenarios rather than executing all of them. Reserve filtering for that case: a superseded plan keeps scenarios that each look plausible alone, so trimming it preserves the wrong ones.

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
5. Record **PASS**, **FAIL**, or **PARTIAL** with details
6. When the UX lens is loaded, note any usability observation it surfaces, kept separate from the verdict

When a test's own command failed on a sandbox denial, re-run it via the Bash tool (`dangerouslyDisableSandbox: true`) before recording **FAIL** or **PARTIAL**.

When a scenario needs infrastructure that cannot be stood up in this session (backend service, auth provider, external dependency), first re-run each command that starts or reaches it and failed on a sandbox denial via the Bash tool (`dangerouslyDisableSandbox: true`). When the infrastructure stays unavailable, look for a stub before recording **PARTIAL**. When the dependency is reached through a client whose endpoint is runtime configuration, repoint that endpoint at a local stub; the same interception yields an artifact the system emits rather than provides (a token, a session identifier, a single-use link). Confine this to runtime configuration and leave the working tree unchanged. When the code under test makes the call itself, a **call-site stub** intercepts it without a second process: from the run, install a replacement into the running process that matches one destination and returns the response the scenario needs or delays the real one, gated on a flag the run can flip. Installing it from the run leaves the working tree unchanged as well. It lasts only as long as the process, so re-install it after anything that restarts or reloads it. Record **PARTIAL** when no stub applies or the ones that do fail, naming what is missing and what was tried.

When a scenario writes to a shared external system and those writes are not cleanly undoable, run it against fixture data with nothing to act on whenever the scenario's expected outcome can still be observed that way, and name that fixture data in the result as a substitution. Treat writes as not cleanly undoable whenever restoring the records leaves downstream effects the writes triggered in place. When the writing path must run, work through it in order. Determine the full write set without executing it: use a dry-run mode when one exists, otherwise trace the code path and enumerate every record it writes, including those reached through triggers, cascades, and hooks. State what the enumeration cannot settle rather than presenting it as complete. Pick the target whose writes are incidental to what the scenario verifies, weighing each candidate's write set against the coverage it adds. Then request approval via `AskUserQuestion`, presenting the enumeration as what is being consented to, and request it again whenever the enumeration changes. Capture a pre-run manifest and write an ordered revert procedure. Record **PARTIAL** when approval is declined, naming the writes that were withheld.

When a scenario's preconditions need privileged state or a second participant (an entitlement or plan tier, an elevated role, seed data, a second concurrent client or session), provision it through a path the project already exposes for development and run the scenario. When the provisioning path writes to a shared external system, carry it through the write enumeration and approval sequence above. Record **PARTIAL** only after an attempt to provision failed, naming the precondition that could not be provisioned and what was tried.

When a scenario names a control, command, or other affordance the app does not have, establish what the scenario verifies before recording a verdict. When the named mechanism is itself what the scenario verifies, its absence is a **FAIL**. When the mechanism is incidental to the outcome the scenario verifies, drive the affordance that delivers that outcome, record the verdict against it, and name the substitution in the result. Record **PARTIAL** when which of the two it is cannot be established.

When the scenario's output is consumed by another system, withhold PASS until that system accepts it. Decoding a token, reading a response body, or confirming a row exists shows only that the artifact was produced. Stand up the consumer under the same isolation and cleanup rules as any other service this run starts, and exercise its own flow. When standing it up is not possible, record **PARTIAL** and name which half is unproven. PARTIAL counts as not passed everywhere a verdict is tallied or gated.

When a scenario depends on an input mode or device characteristic the browser emulates, confirm the page itself reports that capability before recording a verdict resting on it — a device preset may change only the viewport and the user agent. Record **PARTIAL**, naming the unproven half, when the capability cannot be established.

### Level Progression

1. **Level 1: Basic Functionality** — If any Level 1 test does not pass, report early and use `AskUserQuestion` to ask whether to continue. Basic failures may indicate the feature is too broken for deeper testing.
2. **Level 2: Complex Operations** — Execute all tests regardless of individual failures.
3. **Level 3: Adversarial Testing** — Execute all tests. Failures here are expected and valuable.
4. **Level 4: Cross-Cutting Scenarios** — Execute all tests.

If a project-specific testing skill or MCP tool was identified in Step 2, use that. The paths below are fallbacks.

### Web App Path

Reuse a running dev server only when this session started it. Otherwise start one on a port this run selected and wait for it to be ready. Confirm it bound to that port before sending it traffic — a failed bind leaves another agent's service answering. Move to another port when the port is taken; report the error and stop when the server itself failed to start. If `/agent-browser` is available, run the `/agent-browser` skill. Otherwise, use `claude-in-chrome` MCP to interact with the app.

### UI/Native App Path

Launch the app. Use `computer-use` MCP to interact with the UI.

### CLI Path

Run commands directly. Run each test runner this run starts in its own process group under a timeout enforced from outside the runner.

## Step 5: Report

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

Then use the TaskList tool and proceed to any remaining task.

## Rules

- Always clean up: close only the browser sessions this run opened, by name, stop the dev servers, services, stubs, and test runners this run started, restore any configuration it repointed or extended, release the sessions, roles, and records it created, and run the revert procedure of each approved write. Capture the PID of each dev server, service, stub, and test runner this run starts and stop it by that PID rather than by a name or command-line pattern, which also matches an identically named process a concurrent agent is running. Stop the process group rather than the captured PID alone — a server started behind a wrapper outlives its parent, and a runner's spawned helpers outlive the runner. Before reporting cleanup complete, confirm each server, service, and stub port released and no process from a stopped group still running, and report by PID any process that could not be stopped. When processes cannot be listed, report that check as unrun and name the groups. Never close all browser sessions at once — concurrent agents may share the browser daemon, so a blanket close is cross-agent destruction.
- Treat a permission or scope granted mid-run to unblock a scenario as something this run created: before reporting cleanup complete, verify the production code never needs it, then ask for it to be revoked in the report. Name the call sites checked there too.
- Isolate shared process state so concurrent or subagent runs don't collide: bind dev servers and services to unique ports, scope tmux sessions (`tmux -L <name>`), give each browser session a unique name so cleanup can target only its own, and write screenshots and other scratch state to absolute paths under a unique scratch directory outside the repository under test. Derive each such identifier once and reuse that exact value in every later command, writing it as a literal or reading it back from a note under the run's scratch directory. A value recomputed per shell, such as `$$`, differs between the command that creates a resource and the command that releases it, so cleanup releases something it never created and reports success while the real resource leaks. A port picked as unique may already be held by a concurrent agent, so check it before binding and move to another when it is taken, leaving the incumbent running. When a unique port moves a service off its default address, find the settings elsewhere in the stack that name that default, such as allowed origins and sign-in callback URLs, and bring each in line through runtime overrides, leaving the working tree unchanged: add the new address beside the default in a list, and replace the default only where no process outside this run reads the setting.
- Never modify application code. This skill is read-only verification, with one exception: a stub reached through runtime configuration, restored on cleanup. Report failures without attempting to fix them.
- If the dev server fails to start, report the error and stop.
- Verify an observation before reporting it as pre-existing rather than introduced by the change, and state that verification. Read the file at the ref the change under test is measured against with `git show <ref>:<path>`: `HEAD` for uncommitted or staged work, the commit the work began from when it is already committed locally, or `origin/<base-branch>` for a PR, fetched first. Reporting an introduced defect as pre-existing drops it from scope silently, while the opposite error only adds noise.
- Use the Monitor tool to tail app logs for errors or warnings while running tests, so backend failures surface alongside test observations.
- After the last test interaction, perform one additional log read or status check before reporting. Pending `Monitor` events that arrive after the agent emits final text are dropped, so the extra action gives them time to land. Matters most when this skill runs inside a subagent. When this check targets a server or log process you did not start, report it as outstanding for the process owner rather than running it yourself; inability to read such a process is outstanding, not a test failure.
- To diagnose failures, run the `/investigate` skill on the test report.
