# Correctness Review Reference

## What to Review

Bugs, logic errors, and correctness problems: incorrect control flow, off-by-one errors, null/undefined access, type mismatches, broken error handling, race conditions, resource leaks, and state lifecycle bugs.

Also audit removed behavior: when the change deletes a line or block, identify the invariant, guard, validation, or cleanup it enforced and confirm the change re-establishes it elsewhere or proves it is no longer needed. When the change moves or extracts code to a new location, also identify what the code relied on at its original location, such as an enclosing check, lock, transaction, or ordering, and confirm the new location provides it. Audit a configuration default the change alters: name what the old value guaranteed and confirm that guarantee still holds for every consumer that relied on it.

Also trace call sites: for each function, method, or exported symbol the change modifies, search for its callers and check whether the change breaks any of them — a new precondition, a changed return shape or nullability, a newly thrown error, a different ordering or timing dependency. Check the other direction too: a parallel change elsewhere in the same changeset can make an existing call unsafe.

## Determination Criteria

Flag an issue only when ALL of these hold:

1. It meaningfully impacts the accuracy, performance, security, or maintainability of the code
2. The bug is discrete and actionable (not a general codebase issue or combination of multiple issues)
3. Fixing it does not demand rigor beyond what exists in the rest of the codebase
4. The author would likely fix the issue if aware of it
5. The bug does not rely on unstated assumptions about the codebase or author's intent
6. Speculation is insufficient — identify the parts of the code that are provably affected
7. The issue is clearly not an intentional change by the original author

## Priority Levels

- **P0** — Drop everything. Blocking release or operations. Only for universal issues that do not depend on assumptions about inputs
- **P1** — Urgent. Should be addressed in the next cycle
- **P2** — Normal. To be fixed eventually
- **P3** — Low. Nice to have

## What to Ignore

- Trivial style unless it obscures meaning or violates documented standards

**Verdict label:** `Correctness: <correct | incorrect>`
