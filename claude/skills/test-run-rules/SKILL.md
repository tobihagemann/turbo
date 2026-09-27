---
name: test-run-rules
description: "Shared rules for test runs that drive the running app or run a test target: isolation from concurrent runs, stubs for infrastructure that cannot be stood up, provisioning privileged state, approval before writes to shared external systems, and cleanup of only what the run created. Not typically invoked directly."
---

# Test Run Rules

Apply these rules for the rest of the test run, whether it drives the running app or runs a test target. A scenario they leave **blocked** could not be set up or run; one they leave **inconclusive** ran, but its result cannot be read.

## Sandbox Denials

When a command failed on a sandbox denial, whether it starts or reaches infrastructure or is a scenario's own command, re-run it via the Bash tool (`dangerouslyDisableSandbox: true`) before treating the infrastructure as unavailable or recording the scenario as failed, blocked, or inconclusive.

## Isolation

- Isolate shared process state so concurrent or subagent runs don't collide: bind dev servers and services to unique ports, scope tmux sessions (`tmux -L <name>`), give each browser session a unique name so cleanup can target only its own, and write screenshots and other scratch state to absolute paths under a uniquely named subdirectory of the session scratchpad directory. Derive each such identifier once and reuse that exact value in every later command, writing it as a literal or reading it back from a note in that subdirectory. A value recomputed per shell, such as `$$`, differs between the command that creates a resource and the command that releases it, so cleanup releases something it never created and reports success while the real resource leaks. A port picked as unique may already be held by a concurrent agent, so check it before binding and move to another when it is taken, leaving the incumbent running. When a unique port moves a service off its default address, find the settings elsewhere in the stack that name that default, such as allowed origins and sign-in callback URLs, and bring each in line through runtime overrides, leaving the working tree unchanged: add the new address beside the default in a list, and replace the default only where no process outside this run reads the setting.
- Reuse a running dev server only when this session started it. Otherwise start one on a port this run selected and wait for it to be ready. Confirm it bound to that port before sending it traffic — a failed bind leaves another agent's service answering. Move to another port when the port is taken; report the error and stop when the server itself failed to start.
- Run each test runner this run starts in its own process group under a timeout enforced from outside the runner.

## Unavailable Infrastructure

When a scenario needs infrastructure that cannot be stood up in this session (backend service, auth provider, external dependency), look for a stub before treating the scenario as blocked. When the dependency is reached through a client whose endpoint is runtime configuration, repoint that endpoint at a local stub; the same interception yields an artifact the system emits rather than provides (a token, a session identifier, a single-use link). Confine this to runtime configuration and leave the working tree unchanged. When the code under test makes the call itself, a **call-site stub** intercepts it without a second process: from the run, install a replacement into the running process that matches one destination and returns the response the scenario needs or delays the real one, gated on a flag the run can flip. Installing it from the run leaves the working tree unchanged as well. It lasts only as long as the process, so re-install it after anything that restarts or reloads it. When no stub applies or the ones that do fail, the scenario is blocked: name what is missing and what was tried.

## Privileged State and Second Participants

When a scenario needs privileged state or a second participant (an entitlement or plan tier, an elevated role, seed data, a second concurrent client or session), provision it through a path the project already exposes for development, such as its own development-only endpoint, an administrative command, or a second client this run starts. When the provisioning path writes to a shared external system, carry it through the write sequence under Writes to Shared External Systems. Treat the scenario as blocked only after an attempt to provision failed, naming the precondition and what was tried.

Treat a permission or scope granted mid-run to unblock a scenario as something this run created: before reporting cleanup complete, verify the production code never needs it, then ask for it to be revoked in the report. Name the call sites checked there too.

## Writes to Shared External Systems

When a scenario writes to a shared external system and those writes are not cleanly undoable, run it against fixture data with nothing to act on whenever its expected outcome can still be observed that way, so the run still exercises wiring, auth, queries, guards, and failure isolation while writing nothing, and name that fixture data in the result as a substitution. Treat writes as not cleanly undoable whenever restoring the records leaves downstream effects the writes triggered in place.

When the writing path must run, work through it in order. Determine the full write set without executing it: use a dry-run mode when one exists, otherwise trace the code path and enumerate every record it writes, including those reached through triggers, cascades, and hooks. State what the enumeration cannot settle rather than presenting it as complete. Pick the target whose writes are incidental to what the scenario verifies, weighing each candidate's write set against the coverage it adds. Then request approval via `AskUserQuestion`, presenting the enumeration as what is being consented to, and request it again whenever the enumeration changes. Capture a pre-run manifest and write an ordered revert procedure. When approval is declined, the scenario is blocked: name the writes that were withheld.

## Reading Results

- When a scenario names a control, command, or other affordance the app does not have, establish what the scenario verifies before recording a verdict. When the named mechanism is itself what the scenario verifies, its absence is a failure. When the mechanism is incidental to the outcome the scenario verifies, drive the affordance that delivers that outcome, record the verdict against it, and name the substitution in the result. When which of the two it is cannot be established, the scenario is inconclusive.
- When a scenario depends on an input mode or device characteristic the browser emulates, confirm the page itself reports that capability before recording a verdict resting on it — a device preset may change only the viewport and the user agent. When the capability cannot be established, the scenario is inconclusive: name the capability.
- Verify an observation before reporting it as pre-existing rather than introduced by the change, and state that verification. Read the file at the ref the change under test is measured against with `git show <ref>:<path>`: `HEAD` for uncommitted or staged work, the commit the work began from when it is already committed locally, or `origin/<base-branch>` for a PR, fetched first. Reporting an introduced defect as pre-existing drops it from scope silently, while the opposite error only adds noise.

## Logs

- Use the Monitor tool to tail app logs for errors or warnings while testing, so backend failures surface alongside the checks.
- After the last interaction with the app, perform one additional log read or status check before reporting. Pending `Monitor` events that arrive after the agent emits final text are dropped, so the extra action gives them time to land. Matters most when the run happens inside a subagent. When this check targets a server or log process this run did not start, report it as outstanding for the process owner rather than running it yourself; inability to read such a process is outstanding, not a test failure.

## Code and Cleanup

- Leave application code unchanged: every stub above lives in runtime configuration or the running process and is removed on cleanup. Report failures without attempting to fix them.
- Always clean up: close only the browser sessions this run opened, by name, kill the tmux server of each `tmux -L` name it scoped, stop the dev servers, services, stubs, and test runners this run started, restore any configuration it repointed or extended, release the sessions, roles, and records it created, and run the revert procedure of each approved write. Capture the PID of each dev server, service, stub, and test runner this run starts and stop it by that PID rather than by a name or command-line pattern, which also matches an identically named process a concurrent agent is running. Stop the process group rather than the captured PID alone — a server started behind a wrapper outlives its parent, and a runner's spawned helpers outlive the runner. Before reporting cleanup complete, confirm each server, service, and stub port released and no process from a stopped group still running, and report by PID any process that could not be stopped. When processes cannot be listed, report that check as unrun and name the groups. Never close all browser sessions at once — concurrent agents may share the browser daemon, so a blanket close is cross-agent destruction.
