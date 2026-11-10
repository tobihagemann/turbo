# Intent Review Reference

## Review Instructions

1. Read the governing document in full before reading the change.
2. List what it requires of this change: each outcome, behavior, or constraint it states as binding.
3. Before reporting a requirement as missing, search the repository for code that delivers it. A requirement delivered outside the reviewed scope, or assigned by the document to work this change does not cover, is not missing.
4. For a missing requirement, set `**File:**` to the file the document assigns it to, or else to the governing document, by its path or URL when it has one.

## What to Review

- **Missing or partial requirement** — the document requires an outcome the change does not deliver, or delivers for only some of the cases the document names
- **Unrequested behavior** — the change adds or alters behavior a user or operator would notice, and no requirement in the document calls for it or depends on it
- **Requirement implemented wrongly** — code exists for the requirement and produces a different outcome than the document states
- **Violated constraint** — the change crosses a constraint the document states as binding, such as a boundary the work must stay within or an interface it must keep

## Determination Criteria

Flag an issue only when ALL of these hold:

1. The finding quotes the governing line it rests on in its `**Requirement:**` field. For unrequested behavior, quote the requirement nearest the behavior and show that it does not call for it
2. The mismatch is in an outcome, or in a constraint the document states as binding. An implementation shaped differently from the one the document sketches, reaching the stated outcome, is not a finding
3. The code proves it: name the code that produces the wrong outcome or the unrequested behavior, or the places searched for a missing one
4. No later decision recorded in the document or in the context supplied with it changed the requirement

## Priority Levels

- **P0** — A requirement the document's purpose rests on is missing or produces the wrong outcome
- **P1** — A stated requirement is missing, partial, or produces the wrong outcome, or a binding constraint is violated
- **P2** — Unrequested behavior a user or operator would notice
- **P3** — A minor divergence from a stated outcome

## What to Ignore

- Defects that hold whatever the document says; the other review types own them
- Behavior that guards, validates, or handles failures of an outcome the document requires; the other review types judge it
- Unrequested behavior in a file or directory scope, which has no diff to separate the change from what predates it
- Whether the document's own verification commands pass

**Extra metadata:** `**Requirement:** <the governing line, quoted>`

**Verdict label:** `Intent: <met | issues found>`
