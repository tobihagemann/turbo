---
name: write-tests
description: Write missing tests matching project conventions. Use when the user asks to "write tests", "add tests", "write missing tests", or "add test coverage".
---

# Write Tests

Write missing tests matching project conventions.

## Step 1: Determine What to Test

Identify the code that needs test coverage:

1. If the caller specifies files, a diff command, or a specific target, use that. Otherwise, determine from conversation context or the current git state.
2. Skip non-testable code (config, documentation, CI files, SKILL.md files, markdown)
3. Search for existing test files covering the target code — skip if adequate tests already exist

If nothing needs tests, report that and stop.

## Step 2: Write and Run Tests

1. Identify the project's test framework and conventions by reading existing test files
2. Write focused unit or integration tests for the target code
3. Run the test suite to confirm all tests pass
4. If tests fail, run the `/investigate` skill to diagnose the root cause, then apply the suggested fix and re-run tests. If investigation cannot identify a root cause after its full cycle, stop and report with investigation findings.
