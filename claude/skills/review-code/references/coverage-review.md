# Coverage Review Reference

## Review Instructions

1. Skip non-testable code (config, documentation, CI files, SKILL.md files, markdown).
2. Search for existing test files covering the target code.
3. Identify the project's test framework and conventions by reading existing test files.

### Verifying Pin Claims

Before asserting that a behavior is unpinned, or that a new test pins one, verify it by mutation: in an isolated `git worktree` created under `$TMPDIR`, invert or remove the line at issue, run the suite, and check whether a test fails. A test that passes against the mutation does not pin the behavior. After discarding the worktree, verify that `git worktree list` no longer shows it, that `git status --short` is clean, and that the shared tree's dependency directory still resolves (a destroyed install leaves `git status` clean, since it is gitignored). Report damage you cannot repair, with the exact repair command, in place of findings. Cite the mutation and its result as evidence in the finding's paragraph; the `**Failure scenario:**` line still reads trigger → consequence: the unguarded path and what shipping it lets through.

This covers any claim that a specific behavior is or is not guarded, including "tests exist but miss this path" — target the unguarded path. Settle "this module has no tests at all" by inspection.

Skip the mutation when a fresh checkout cannot run the suite cheaply: it needs an install or build step, there is no runnable test command, or the suite depends on state outside the tree such as fixed ports, shared databases, caches, untracked local configuration, or external services. Needing an install is itself a skip trigger here, whether or not that install would succeed. Run the suite only against dependencies inside the worktree. Reaching the shared tree's install by any route, whether a link, a copy, a mount, or an environment variable redirecting resolution, is not a substitute, since removing a worktree deletes through symlinks and a redirected suite writes into the shared install. When skipping, say in the finding's paragraph that the claim rests on inspection alone.

## What to Review

- **No test coverage** — functions or modules with no corresponding tests
- **Missing edge cases** — tests exist but miss critical paths (error handling, boundary conditions, empty inputs, concurrent access)
- **Test efficacy** — tests that cannot fail when the behavior they guard breaks (the assertion reads a surface the code under test does not write, or a mechanism other than the one under test produces the same observable)
- **Risk-level mismatch** — high-risk code (auth, data handling, financial logic) with only basic happy-path tests
- **Convention gaps** — tests not following the project's established testing patterns

## Determination Criteria

Flag an issue only when ALL of these hold:

1. The code performs meaningful logic worth testing (not pure configuration, boilerplate, or generated code)
2. The gap is discrete and actionable (a specific function or module, not "needs more tests generally")
3. The missing coverage creates real risk proportional to the code's criticality

## Priority Levels

- **P0** — Critical code with no tests (auth, data mutation, payment processing)
- **P1** — Important code with no tests or high-risk code with only happy-path tests
- **P2** — Code with tests but missing significant edge cases
- **P3** — Minor coverage gaps or convention mismatches

## What to Ignore

- Non-testable code (config, documentation, CI files, SKILL.md files, markdown)
- Generated code or trivial getters/setters with no logic

**Verdict label:** `Test Coverage: <adequate | gaps found>`
