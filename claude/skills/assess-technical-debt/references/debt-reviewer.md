# Debt Reviewer Guidelines

Scan the assigned scope for structural technical debt and return structured findings. Cover the dimensions named in your prompt: partition agents cover complexity hotspots, deprecated API usage, and duplication; the architecture agent covers architecture rot project-wide. Do not modify code, propose a full implementation, or write files.

## Contents

- Scope and Mindset
- Optional CLI Tools
- Dimension 1: Complexity Hotspots
- Dimension 2: Deprecated API Usage
- Dimension 3: Duplication Clusters
- Dimension 4: Architecture Rot
- Impact and Effort Rubric
- Output Format

## Scope and Mindset

This assessment deliberately surfaces large refactors. Flag the underlying structural problem even when fixing it requires a multi-file refactor. Report accumulated debt, not stylistic nits.

Anchor every finding to a concrete location (`path:line` or a line range) and read enough surrounding code to be confident the problem is real. Speculative findings waste the downstream evaluation pass.

## Optional CLI Tools

If a relevant analyzer is already installed, run it as a fast first pass, then confirm and enrich its hits by reading the code. Do not ask to install anything; if none is present, rely on direct reading and grep.

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
- Third-party library calls superseded by a newer API in the installed version. Use documentation MCP tools or WebSearch to confirm the replacement when unsure.
- Patterns the ecosystem has moved past where the codebase still uses the old form throughout.

Report the deprecated symbol, where its replacement lives, and how widespread the usage is (one call site vs. pervasive).

## Dimension 3: Duplication Clusters

Repeated logic that should be consolidated, beyond incidental similarity.

Look for:

- Copy-pasted blocks with small variations, especially logic duplicated across modules.
- Parallel implementations of the same concept that drift independently (validation, formatting, mapping, error handling repeated per call site).
- Repeated literal sets or magic constants that belong in one shared definition.

Distinguish genuine duplication worth unifying from coincidental resemblance. Report the cluster (all locations), what they share, and the consolidation target (shared helper, base type, table, generic).

## Dimension 4: Architecture Rot

Structural decay visible only across modules. This is the architecture agent's focus.

Look for:

- Tangled module boundaries: modules that import each other widely with no clear ownership.
- Circular dependencies between modules or packages.
- Layering violations: lower layers reaching into higher ones, UI touching persistence directly, business logic in controllers/views.
- Bottleneck modules everything depends on, and "shotgun surgery" where one conceptual change forces edits across many files.
- Inconsistent architecture: several competing ways to do the same cross-cutting thing (data access, config, eventing).

Report the modules involved, the dependency or boundary problem, and the refactor direction (introduce a boundary/interface, invert a dependency, extract a shared layer, merge or split modules).

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
**Location:** <path:line or path (lines start-end); list all sites for duplication>
**Impact:** <High|Medium|Low> — <why>
**Effort:** <High|Medium|Low> — <why>
**Recommended refactor:** <the concrete change>

(repeat per finding)
```

If the scope holds no significant debt, say so explicitly and note any caveats.
