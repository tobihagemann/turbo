---
name: run-checks
description: "Run the project's full verification gate: every check the project defines as a pass/fail condition, built from its CI config, check scripts, and configured tools, or from a formatter-linter-test baseline when it declares none. Use when the user asks to \"run checks\", \"run the verification gate\", \"run lint and tests\", \"run the test suite\", \"check that this passes\", \"does this pass CI\", or \"run the project's checks\"."
---

# Run Checks

Build the gate by combining every source below that the project declares (sources 1-3); run the baseline (source 4) only when the project declares none of them. Passing the gate must mean the project's own checks (and CI, where it exists) pass.

1. **CI config** — where present, it is the authoritative gate; run the checks it enforces.
2. **Check scripts** — package-manager scripts (`check`, `verify`, `lint`, `typecheck`), Makefile or Taskfile targets, or a combined format+lint script.
3. **Configured tools** — any tool with a config committed to the repo, such as a dead-code or unused-dependency gate. A committed config means the project treats the tool as a gate; run it even when no script or CI invokes it. Do not run such a tool when the project has not configured it; unconfigured runs are discovery, which belongs to `$find-dead-code`.
4. **Baseline** — when the project declares nothing more, run the formatter, then the linter, then the test suite.

Run the formatter first so later checks see formatted code, then the rest. Fix any failure the tools do not auto-resolve. For test failures, run the `$investigate` skill to diagnose the root cause, apply the suggested fix, and re-run; if investigation finds no root cause, stop and report with its findings.

State which sources the project declared and which checks ran, so a narrower-than-intended gate stays visible.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.
