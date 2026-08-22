---
name: simplify-docs
description: "Run a multi-agent review of code comments and markdown documentation for unnecessary content, then fix the issues. Covers comments that misdescribe the code, what-restating comments, name-mirroring doc comments, status-update prose, and other documentation noise. Use when the user asks to \"simplify docs\", \"simplify documentation\", \"clean up comments\", \"clean up docs\", \"review documentation\", \"strip unnecessary comments\", \"fix stale comments\", \"reduce doc noise\", or \"run simplify-docs\"."
---

# Simplify Docs

Review code comments and markdown documentation for unnecessary content, then fix the issues.

## Step 1: Determine the Scope

Determine what to review:

- If a specific **diff command** was provided (e.g., `git diff --cached`), use that.
- If a **file list or directory** was provided, review those files directly (read the full files, not a diff).
- If **neither** was provided, determine the appropriate diff command (e.g., `git diff`, `git diff --cached`, `git diff HEAD`) based on the current git state. When the branch is an open pull request, resolve its base with `gh pr view --json baseRefName --jq '.baseRefName'`, run `git fetch origin <base-branch>`, and diff against `origin/<base-branch>...HEAD`: a local branch of the same name can sit behind the remote, which puts the merge base before an already-merged pull request and pulls merged work into the scope. If there are no git changes, default to a full-tree sweep of source files plus top-level markdown.

State the resolved file list before launching the agents: add `--name-only` to a diff command, or list the files for a file or directory scope.

## Step 2: Launch Two Review Agents in Parallel

Emit both Agent tool calls below in one assistant message. Each Agent call uses `model: "opus"` and no `name`. Wait for every agent to report before continuing. Do not begin the next step on a partial set, and do not relaunch an agent that has not yet reported. Pass the scope from Step 1 to each agent. Every agent's prompt must direct it to treat the shared working tree and its git index as read-only and to reach its findings by reading and reasoning; fixes happen in Step 3. HEAD stays where it is: read other refs with `git show <ref>:<path>` rather than `git checkout` or `git switch`.

Confine the agent's prompt to what to review, plus the conventions and factual properties that bear on it. Pass a property of the existing prose as a fact the agent weighs, such as "the file documents non-obvious third-party behavior". Leave out any statement that tells the agent what verdict to reach about that property, such as "the file is deliberately comment-dense, judge against that established bar", because it binds the agent to accept the very property the review exists to assess.

Both agent prompts must also carry the readability criteria below and the constraint that follows them, applied to the prose that survives that agent's own list:

1. **Clause stacking** — a sentence carrying more than one idea. Split it when the clauses make independently useful points. Count ideas rather than propositions.
2. **Punctuation chains** — a second em dash, colon, or semicolon continuing the thought. Split the sentence. A `- **Term** — description` label separator is not a chain.
3. **Dense paragraphs** — facts running together past the point a reader can hold them apart. Break into shorter sentences, keeping the passage as prose rather than converting it to a bullet list.

Every split above keeps its connectives. Leave clauses joined when their relationship is the point (cause and effect, condition and consequence, contrast, qualification, scope) and separating them would make the reader rebuild the connection.

### Agent 1: Code Comments Review

Review code files in scope. Beyond the auto-loaded instruction files, walk each directory that is an ancestor of a reviewed file, from the project root down, and read its `CLAUDE.md` and any file those instructions import — a directory's file governs only the files at or below it. Flag a comment when it misdescribes the code, or when it adds no information beyond what the code already says:

1. **Asserts a contract the code does not enforce** — states what is handled, excluded, guaranteed, or left untouched, where the code beneath it does something else. Verify each such claim against the code rather than reading it as intent. Propose correcting the comment, or flag the missing enforcement when the stated contract is the desired one. Check this before the redundancy criteria below.
2. **Restates code, signature, or name** — paraphrases the immediately-following statement, a multi-statement block, a declaration's name, or the parameter/return shape. Includes doc blocks above a declaration whose prose elaborates the name and signature without adding rationale, and Parameters/Returns/Throws enumerations that only echo names and types. Flag only the redundant entries; non-obvious constraints (size, units, ranges, preconditions) stay. Drop the wrapping enumeration when no entries survive trimming. Where an instruction file or the documentation tooling's configuration requires that declaration to carry documentation, keep what the requirement covers and flag only entries that describe the code wrongly.
3. **Narrates history or change** — references PRs, tickets, prior behavior, recent changes, "fixed by"/"previously did X"/"no longer Y" framing, or session-narrative voice ("turns out", "discovered", "we found that"). State the current invariant; past behavior belongs in git history, and session-derived lessons about tooling belong in auto memory or project instructions. Change narration also appears in invariant form: a sentence that reads as a rule but only carries meaning as a contrast with the code's prior behavior, and that you would not write if the code had been greenfield from day one.
4. **Cross-references that decay** — names the caller ("used by X", "called from Y"), or task/flow/feature-flag context the code was added for ("added for the Y flow", "for the rollout"). Delete: caller relationships belong in the call graph, feature context in the PR description.
5. **Explains language or framework constructs** — describes what a stdlib feature, language keyword, or well-known framework call does. Assume a competent reader.
6. **Low-value section banners** — banners that don't section anything, or that restate what an access modifier or naming convention already conveys. Idiomatic structural markers around a real section stay.
7. **Overgrown rationale** — a comment that captures real WHY but in more lines or concerns than the rationale requires. Tighten to one sentence per concern, split bundled concerns to their decision points, or lift shared rationale to a design doc or commit message.
8. **Compensates for unclear code** — a comment that exists because the code is hard to read. Flag the underlying code as a refactor opportunity (rename, extract, restructure) rather than tightening the comment.

**Keep these:** comments that capture a load-bearing constraint the code itself cannot express — a hidden constraint or invariant, a workaround for a specific bug (ideally with a reference), a non-obvious performance characteristic, a pointer to a spec or RFC section, or behavior that would surprise a future reader and lead them to "fix" working code. Greenfield test: would you write this comment if the code had been greenfield from day one? Keeping a comment and finding it accurate are separate judgments: a comment that captures a real constraint still gets corrected when it describes that constraint wrongly.

For each finding, propose: delete it, tighten to the load-bearing WHY, restructure it for readability, or flag a refactor that would make the comment unnecessary.

### Agent 2: Markdown Documentation Review

Review markdown files in scope (READMEs, AGENTS.md, CLAUDE.md, docs/, contributor guides). Flag passages that add no information beyond what the reader can derive from current state:

1. **Status-update voice** — prose framed as recent updates or transitions. It also appears in invariant form: a sentence that reads as a rule but only carries meaning as a contrast with the design it replaced, and that you would not write if the project had always worked this way. Rewrite as timeless current-state prose.
2. **Restates what the codebase already shows** — passages that duplicate the repo layout or re-summarize what the code makes obvious.
3. **WHAT without WHY** — explanations of what a feature does that the feature's own name and signature already convey. Keep the parts that explain motivation, constraints, or tradeoffs.
4. **Scaffolding leak** — auto-generated headings, boilerplate sections, or prescriptive bullets that read like spec output rather than reader-facing prose.
5. **Explanation rot** — passages that describe an old design or contradict the current code. Delete or update to match reality.
6. **Multi-paragraph essays where one line would do** — long-form passages that restate the same point multiple ways. Keep one tight version.

**Keep these:** passages that explain motivation, capture constraints or tradeoffs the code can't express, document interfaces meant for outside readers, or record decisions whose rationale would otherwise be lost.

For each flagged passage, propose: delete it, tighten it, restructure it for readability, or rewrite it as timeless current-state prose.

## Step 3: Fix Issues

Aggregate the agents' findings, then apply each fix directly, skipping false positives. When uncertain whether a comment captures a non-obvious WHY, keep it.

When the scope is a diff, confine fixes to prose the changeset authored or falsified. Prose the change left both untouched and accurate stays as it is, however badly it reads.

Report the outcome as a table, one row per finding, keeping every cell to a single line:

| File | Finding | Outcome |
|------|---------|---------|

Where Outcome is one of:

- **Deleted**, **Tightened**, **Restructured**, or **Rewritten** — the fix that was applied
- **Flagged** — the fix belongs in the code: a refactor that would make the comment unnecessary, or a missing enforcement of a stated contract
- **Skipped** — name the reason

Keep the report to the table. When the table would be empty, report one line stating the docs were already clean instead.

Then use the TaskList tool and proceed to any remaining task.
