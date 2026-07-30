---
name: code-style
description: "Enforce existence, reuse, mirror, and symmetry principles to keep new code minimal and consistent with surrounding code. Use when writing new code in an existing codebase, adding new features, refactoring, or making any code changes."
---

# Code Style: Exist, Reuse, Mirror, Symmetry

When writing new code in an existing codebase, work through these in order. When two pull in different directions, the earlier one wins.

1. **Establish that the code needs to exist**: Drop work the request does not need — an abstraction with one implementation, a configuration point with one caller, a branch for a state the callers cannot reach, scaffolding for an anticipated requirement. Deleting or narrowing beats adding. Before removing code that already exists, trace its callers and confirm nothing depends on the behavior. Input validation at trust boundaries, error handling that prevents data loss, security controls, accessibility affordances, and anything explicitly requested outrank this rule.
2. **Reuse existing code**: Before writing a new helper, check if an existing method can be reused or generalized. If a new helper is needed, model it after its closest sibling.
3. **Reuse existing patterns**: Find the closest analogous feature and replicate its structure (method decomposition, control flow, annotations, guard clauses). When an existing pattern fits, use it rather than introducing a new one. When following it would force materially more code or indirection than a different approach, take the different approach and apply it across the whole change.
4. **Mirror the surrounding code exactly**: Match brace style, comment style, naming conventions, blank line spacing, code density, and level of detail by reading nearby code first.
5. **Maintain symmetry**: If adding `fooB()` parallel to `fooA()`, match naming, parameter order, and structure. Rename `fooA()` when the rename stays mechanical; when it would ripple across call sites, name `fooB()` to match `fooA()` as it stands.
6. **Logical ordering**: Place new methods, switch cases, and fields in the order that mirrors the existing grouping or business lifecycle, rather than appending at the end.
7. **Default to no comment**: Write code that self-explains through naming, extraction, and structure. When you reach for a comment, first try refactoring so it becomes unnecessary. Add one only for a load-bearing constraint the code cannot express (a hidden invariant, a workaround, a non-obvious performance characteristic). When in doubt, omit it.
