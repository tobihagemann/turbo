---
name: run-checks
description: "Run the project's verification gate, built from its CI config, check scripts, and tools. Use when the user asks to \"run checks\", \"run lint and tests\", \"run the test suite\", or \"does this pass CI\"."
---

# Run Checks

Build the gate by combining every source below that the project declares (sources 1-3); run the baseline (source 4) only when the project declares none of them. Passing the gate must mean the project's own checks (and CI, where it exists) pass.

1. **CI config** — where present, it is the authoritative gate; run the checks it enforces.
2. **Check scripts** — package-manager scripts (`check`, `verify`, `lint`, `typecheck`, `build`), Makefile, Taskfile, or justfile targets, a combined format+lint script, or a check command the project's instruction files call for on this change.
3. **Configured tools** — any tool with a config committed to the repo, such as a dead-code or unused-dependency gate. A committed config means the project treats the tool as a gate; run it even when no script or CI invokes it. Do not run such a tool when the project has not configured it.
4. **Baseline** — when the project declares nothing more, run the formatter, then the linter, then the build where the project produces one, then the test suite.

Run the formatter first so later checks see formatted code, then the rest. When a check fails on a sandbox denial, re-run it via the Bash tool (`dangerouslyDisableSandbox: true`) before diagnosing it or reporting it as not run. A check passes only when its command exits 0. A check still running has no exit status: wait for every check to exit, one running in the background included, before reporting the gate or starting anything that follows it. Judge each run by its exit status and the runner's full summary, never by filtering the output for selected summary lines. Fix any failure the tools do not auto-resolve, then re-run each failed check and judge it by the re-run. When a fix, or a tool resolving its own failure, edits the code while the gate is running, re-run every check whose passing run started before that edit. When the same edit keeps recurring across re-runs, stop and report the checks that produce it. For test failures, run the `/investigate` skill to diagnose the root cause, apply the suggested fix, and re-run; if investigation finds no root cause, stop and report with its findings.

State which sources the project declared, which checks ran, and each check's final exit status, so a narrower-than-intended gate or a failing check stays visible.

Then use the TaskList tool and proceed to any remaining task.
