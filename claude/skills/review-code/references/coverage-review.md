# Coverage Review Reference

## Review Instructions

1. Skip non-testable code (config, documentation, CI files, SKILL.md files, markdown).
2. Search for existing test files covering the target code.
3. Identify the project's test framework and conventions by reading existing test files.

### Verifying Pin Claims

Before asserting that a behavior is unpinned, or that a new test pins one, verify it by mutation: in an isolated `git worktree` created under `$TMPDIR`, invert or remove the line at issue, run the suite, and check whether a test fails. Leave HEAD where it is: read other refs with `git show <ref>:<path>` rather than `git checkout` or `git switch`. A test that passes against a behavior-changing mutation does not pin the behavior. After discarding the worktree, verify that `git worktree list` no longer shows it, that `git status --short` is clean, that HEAD is still on the branch it started on, and that the shared tree's dependency directory still resolves (a destroyed install leaves `git status` clean, since it is gitignored). Report damage you cannot repair, with the exact repair command, in place of findings. Cite the mutation and its result as evidence in the finding's paragraph; the `**Failure scenario:**` line still reads trigger → consequence: the unguarded path and what shipping it lets through.

This covers any claim that a specific behavior is or is not guarded, including "tests exist but miss this path" — target the unguarded path. Settle "this module has no tests at all" by inspection.

A surviving mutation proves a gap only when the mutated code behaves differently from the original for some reachable input. Name that input in the finding. When none can be named, the finding is void.

A failing test proves the behavior is pinned only when the mutation landed in the branch under review. Name that branch and the original behavior the mutation reproduces before running it, then re-read the mutated lines: a mutation placed a statement away fails for a reason unrelated to the gap, and voiding the finding on that evidence hides it with nothing to show the check went wrong.

Skip the mutation when a fresh checkout cannot run the suite cheaply: it needs an install or build step, there is no runnable test command, or the suite depends on state outside the tree such as fixed ports, shared databases, caches, untracked local configuration, or external services. Needing an install is itself a skip trigger here, whether or not that install would succeed. Skip it as well when the line at issue bounds a loop, a retry, or a wait and the suite has no per-test timeout — the mutation hangs instead of failing. Run the suite only against dependencies inside the worktree. Reaching the shared tree's install by any route, whether a link, a copy, a mount, or an environment variable redirecting resolution, is not a substitute, since removing a worktree deletes through symlinks and a redirected suite writes into the shared install. When skipping, say in the finding's paragraph that the claim rests on inspection alone.

### Reviewing a Boundary Served by a Double

When a test double is the only executor of an external boundary, a green tier is evidence about the double and not about production. Enumerate in the finding what the double cannot prove: which behaviors of the real dependency it fails to reproduce, and which passing tests are vacuous as a result. A double more permissive, more informative, or more forgiving than the real dependency is itself the defect, so report it against the double. When the changed code is exercised only through the double, the finding concerns that code's coverage in diff mode, naming the double as the reason the coverage is illusory.

## What to Review

- **No test coverage** — functions or modules with no corresponding tests
- **Missing edge cases** — tests exist but miss critical paths (error handling, boundary conditions, empty inputs, concurrent access)
- **Test efficacy** — tests that cannot fail when the behavior they guard breaks (the assertion reads a surface the code under test does not write, or a mechanism other than the one under test produces the same observable)
- **Double fidelity** — a test double more permissive, more informative, or more forgiving than the dependency it stands in for, so tests passing against it say nothing about production
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
