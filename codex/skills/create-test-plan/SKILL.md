---
name: create-test-plan
description: "Analyze what changed and generate a structured test plan at .turbo/test-plans/<slug>.md covering four escalating levels: basic functionality, complex operations, adversarial testing, and cross-cutting scenarios. Use when the user asks to \"create a test plan\", \"plan tests\", \"what should I test\", \"generate test scenarios\", \"test plan for this PR\", or \"what are the test cases\"."
---

# Create Test Plan

Analyze what changed and generate a comprehensive test plan covering four escalating levels of testing depth.

## Step 1: Determine Scope

Resolve scope using the first match:

1. **User-specified** — the user says what to test. Use that.
2. **PR** — a PR URL or number is provided. Fetch the PR details (title, description, changed files, comments) and read the changed code.
3. **Conversation context** — prior conversation contains recent work (a feature, fix, or refactor). Extract what changed, where it lives, and expected behavior.
4. **App-level discovery** — fresh context with no prior work. Examine the project (entry points, routes, commands, README) to identify the app's core user-facing flows.

If the resolved scope spans more than one git branch and the user named no single branch, cover each of them instead of only the branch currently checked out. Include scenarios that exercise them together where the branches can be combined in the working tree the plan's executor will have, and state the required branch state in each such scenario's steps.

## Step 2: Determine Testing Approach

Always check for project-specific testing skills or MCP tools first. Use the fallbacks below when nothing project-specific is available:

- **Web app** → `$agent-browser` skill if available, otherwise Codex browser automation
- **UI/native app** → `computer-use` MCP
- **CLI tool** → direct terminal execution
- **Library with no entry point** → report that interactive testing is not applicable and stop

## Step 3: Resolve the Output Path

Pick a slug for the test plan from the change under test:

- Lowercase
- Replace non-alphanumeric characters with hyphens
- Collapse consecutive hyphens
- Trim leading and trailing hyphens
- Truncate to 40 characters at a word boundary

If the work is anchored to an existing plan at `.turbo/plans/<slug>.md`, reuse that plan's slug verbatim.

The user may pass an explicit slug or path; honor it.

If `.turbo/test-plans/<slug>.md` already exists, use `request_user_input` to ask whether to overwrite, append a numeric suffix (`-2`, `-3`, ...), or pick a different slug. For a slug reused from an anchoring artifact, offer overwrite or a different slug only.

State the chosen slug and the resulting test plan path before continuing.

## Step 4: Analyze the Change

After identifying scope, read the actual code in depth to understand:

- What was added, modified, or removed
- Expected behavior (from PR descriptions, comments, commit messages, or specs)
- Assumptions the implementation makes
- Error paths and edge cases
- Other features or components that could be affected

## Step 5: Generate the Test Plan

For each level, generate specific, actionable test scenarios tailored to the actual change. Each scenario needs exact steps and an expected outcome.

### Level 1: Basic Functionality

Does the feature work at all? Verify the happy path and the most obvious behavior.

- Core feature works as described
- Expected output/UI matches the spec or PR description
- No regressions in directly related functionality

### Level 2: Complex Operations

Combine multiple actions in sequence. Verify state consistency across operations.

- Chain related operations (e.g., create, edit, rename, delete)
- Exercise different combinations of feature parameters
- Verify intermediate states are correct, not just the final result

### Level 3: Adversarial Testing

Actively try to break the feature. Explore boundary conditions and unexpected inputs.

- Invalid, empty, or extreme inputs
- Rapid repeated actions
- Interrupting operations midway (cancel, disconnect, close)
- Resource limits (very large files, deep structures, long names)
- Permission and access edge cases

### Level 4: Cross-Cutting Scenarios

Explore state interactions across system boundaries. These surface the hardest bugs.

- Concurrent modifications from different sources
- State transitions (online to offline to online, foreground to background)
- Interactions with other features that share state
- Race conditions between asynchronous operations

### When a Level Does Not Apply

If the change is small enough that a level has no meaningful scenarios (e.g., a typo fix has no cross-cutting scenarios), note "N/A for this change" with a brief explanation.

## Step 6: Present and Write

Output the plan as text. Then use `request_user_input` to ask for approval before writing.

Create `.turbo/test-plans/` if it does not exist. Write the plan to `.turbo/test-plans/<slug>.md` using this format:

```markdown
# Test Plan: <Feature/Change Name>

## Context

<Brief description of what changed and why>

## Approach

<Testing approach: agent-browser / Codex browser automation / computer-use / terminal>
<Dev server command if applicable>

## Level 1: Basic Functionality

- [ ] **<Test name>** — <Steps to perform> → Expected: <expected outcome>

## Level 2: Complex Operations

- [ ] **<Test name>** — <Steps to perform> → Expected: <expected outcome>

## Level 3: Adversarial Testing

- [ ] **<Test name>** — <Steps to perform> → Expected: <expected outcome>

## Level 4: Cross-Cutting Scenarios

- [ ] **<Test name>** — <Steps to perform> → Expected: <expected outcome>
```

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

## Rules

- Generate at least 2 scenarios per level, more for complex changes.
- Each scenario must have concrete steps and an expected outcome specific to the change.
- Tailor all scenarios to the actual change. Generic test advice is not useful.
