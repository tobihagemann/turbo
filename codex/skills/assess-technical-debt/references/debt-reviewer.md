# Debt Reviewer Guidelines

Scan the assigned scope for structural technical debt and return structured findings. Cover the dimensions named in your prompt: partition agents cover complexity hotspots, deprecated API usage, duplication, and low-value tests; the architecture agent covers architecture rot project-wide. Leave the shared working tree unmodified, and do not propose a full implementation or write files outside your own scratch directory and an isolated worktree used for verification.

## Contents

- Scope and Mindset
- Optional CLI Tools
- Dimension 1: Complexity Hotspots
- Dimension 2: Deprecated API Usage
- Dimension 3: Duplication Clusters
- Dimension 4: Architecture Rot
- Dimension 5: Low-Value Tests
- Impact and Effort Rubric
- Output Format

## Scope and Mindset

This assessment deliberately surfaces large refactors. Flag the underlying structural problem even when fixing it requires a multi-file refactor. Report accumulated debt, not stylistic nits.

Anchor every finding to a concrete location (`path:line` or a line range) and read enough surrounding code to be confident the problem is real. Speculative findings waste the downstream evaluation pass.

## Optional CLI Tools

If a relevant analyzer is already installed, run it as a fast first pass, then confirm and enrich its hits by reading the code. Do not ask to install anything; if none is present, rely on direct reading and `rg`.

| Concern | Tools (any one) |
|---|---|
| Cyclomatic / cognitive complexity | `lizard` (multi-language), `radon cc` (Python), `gocyclo` (Go), ESLint `complexity` rule (JS/TS) |
| Duplication | `jscpd` (multi-language), `pmd cpd` |
| Deprecated symbols | compiler/linter deprecation warnings (`tsc`, `cargo build`, `go vet`, `-Xlint:deprecation`) |

## Dimension 1: Complexity Hotspots

Functions, methods, or types that are hard to hold in the head and risky to change.

Look for:

- High cyclomatic complexity: many branches, deeply nested conditionals and loops, long `switch`/`if-else` chains.
- High cognitive load: deep nesting, flag arguments that fork behavior, long parameter lists, mixed levels of abstraction in one body.
- Long functions and God classes/modules: a single unit owning many unrelated responsibilities or mutating wide shared state.
- Boolean-blind and primitive-obsessed signatures where a small type would collapse the branching.

For each hotspot, name the smallest refactor that would meaningfully reduce the complexity (extract function, replace conditional with polymorphism/table, introduce a type, split the unit).

## Dimension 2: Deprecated API Usage

Production code calling APIs marked for removal or already discouraged.

Look for:

- Project-internal symbols annotated deprecated (`@deprecated`, `@Deprecated`, `#[deprecated]`, `@available(*, deprecated)`, `obsolete`) that still have call sites.
- Standard-library or framework APIs the toolchain warns are deprecated.
- Third-party library calls superseded by a newer API in the installed version. Use documentation tools or web search to confirm the replacement when unsure.
- Patterns the ecosystem has moved past where the codebase still uses the old form throughout.

Report the deprecated symbol, where its replacement lives, and how widespread the usage is (one call site vs. pervasive).

## Dimension 3: Duplication Clusters

Repeated logic that should be consolidated, beyond incidental similarity.

Look for:

- Copy-pasted blocks with small variations, especially logic duplicated across modules.
- Parallel implementations of the same concept that drift independently (validation, formatting, mapping, error handling repeated per call site).
- Repeated literal sets or magic constants that belong in one shared definition.
- Custom infrastructure that re-implements what an established, maintained dependency already provides.

Distinguish genuine duplication worth unifying from coincidental resemblance. Report the cluster (all locations), what they share, and the consolidation target (shared helper, base type, table, generic, established dependency). When the target is an established dependency, name the candidate and mark its coverage of the needed behavior, compatibility, license, and migration cost as unverified.

## Dimension 4: Architecture Rot

Structural decay visible only across modules. This is the architecture agent's focus.

Look for:

- Tangled module boundaries: modules that import each other widely with no clear ownership.
- Circular dependencies between modules or packages.
- Layering violations: lower layers reaching into higher ones, UI touching persistence directly, business logic in controllers/views.
- Bottleneck modules everything depends on, and "shotgun surgery" where one conceptual change forces edits across many files.
- Inconsistent architecture: several competing ways to do the same cross-cutting thing (data access, config, eventing).

Report the modules involved, the dependency or boundary problem, and the refactor direction (introduce a boundary/interface, invert a dependency, extract a shared layer, merge or split modules).

## Dimension 5: Low-Value Tests

Tests that cost maintenance without independent protection. Cover the test files in your partition, and read across the tree for the production code they exercise and the tests that overlap them.

Look for:

- A scenario already pinned by a test at a stronger boundary, or replayed at every layer it crosses.
- Assertions on implementation (source text, import or export lists, private call shapes) that break under a behavior-preserving refactor.
- Production exports, flags, or hooks that no production caller uses and that exist only for tests.
- Tests that cannot fail when the behavior they guard breaks: no assertion when the guarded behavior is more than not throwing, an expected value computed by the code under test, a mock that implements the asserted behavior, a name that promises more than the input exercises, an assertion that reads a surface the code under test does not write, or a mechanism other than the one under test producing the same observable.

Report a redundant test scenario here rather than under Duplication Clusters; duplicated test setup, fixtures, and helpers stay under Duplication Clusters.

Before flagging, read the complete test, the production code it exercises, and the tests that overlap it. Flag only when the recommended refactor removes no protection the tests provide today: name the test that guards the behavior afterward, or, for a test that cannot fail, state that it guards nothing. Public API, protocol, persisted format, migration, security, and platform contracts count as behavior, and a source-text check that is the cheapest guard on a user-facing name, key, or path guards one. A slow or static test is not low-value for that reason alone.

When the suite can run in an isolated worktree, verify delete findings by mutation: for each behavior the candidate asserts, mutate that behavior and confirm the candidate fails, then delete the candidate and confirm the named test fails against the same mutation. For a test that cannot fail, confirm it passes against a mutation of the behavior it names. Before each suite run, confirm with `git diff` in the worktree that the mutation changed the intended file, and count a test as failing only when the suite reports it failing. For every other finding, and when the suite cannot run, state that the finding rests on inspection alone.

Rate impact by how often the test must change for behavior-preserving edits and how much production surface its seam holds open. Report the test or cluster (all locations), the named guard, and one recommended refactor: delete the test, fold it into an existing test's cases, move it to the boundary that owns the behavior, rewrite its assertions against observable behavior, or remove the test-only seam from production code.

## Impact and Effort Rubric

Tag every finding with both axes so the report can rank them.

**Impact** — how much the debt hurts:

- **High** — frequently changed or central code; high change risk, wide blast radius, or a recurring source of bugs.
- **Medium** — noticeable maintenance drag on a moderately active area.
- **Low** — real but isolated, rarely touched, or low-risk.

**Effort** — rough size of the refactor:

- **Low** — localized, mechanical, low regression risk (single function/file).
- **Medium** — spans a few files or needs modest restructuring and test updates.
- **High** — cross-module restructuring, broad ripple, or significant test/behavior risk.

## Output Format

Return findings as a single structured markdown block. Group by dimension; state an explicit outcome for every dimension, including one with no findings.

```markdown
## Debt Findings — <partition or "Architecture">

### <Dimension>

**Finding:** <one-line summary>
**Location:** <path:line or path (lines start-end); list all sites for duplication and test clusters>
**Impact:** <High|Medium|Low> — <why>
**Effort:** <High|Medium|Low> — <why>
**Guard:** <low-value tests only: the test that guards the behavior afterward, or "none: cannot fail"; mutation-verified or inspection alone>
**Recommended refactor:** <the concrete change>

(repeat per finding)
```

If the scope holds no significant debt, say so explicitly and note any caveats.
