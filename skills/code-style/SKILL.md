---
name: code-style
description: "Enforce mirror, reuse, and symmetry principles: match brace style, naming conventions, and spacing of surrounding code; reuse existing patterns and helpers instead of introducing new ones; maintain structural symmetry across parallel functions. Use when writing new code, adding features, refactoring, reviewing code style, or ensuring consistency with existing codebase patterns."
---

# Code Style: Mirror, Reuse, Symmetry

When writing new code in an existing codebase, follow these principles:

1. **Mirror the surrounding code exactly**: Match brace style, comment style, naming conventions, blank line spacing, code density, and level of detail by reading nearby code first.
2. **Reuse existing patterns**: Find the closest analogous feature and replicate its structure (method decomposition, control flow, annotations, guard clauses). Don't introduce new patterns when an existing one fits.
3. **Reuse existing code**: Before writing a new helper, check if an existing method can be reused or generalized. If a new helper is needed, model it after its closest sibling.
4. **Maintain symmetry**: If adding `fooB()` parallel to `fooA()`, ensure naming, parameter order, and structure are symmetric. Rename `fooA()` if needed.
5. **Logical ordering**: Place new methods, switch cases, and fields in the order that mirrors the existing grouping or business lifecycle, not just appended at the end.
