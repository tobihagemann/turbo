---
name: update-pr
description: "Update an existing GitHub pull request's title and description to reflect the current state of the branch. Use when the user asks to \"update the PR\", \"update PR description\", \"update PR title\", \"refresh PR description\", or \"sync PR with changes\"."
---

# Update PR Title and Description

Read the current PR title and body, analyze what changed in the session, and draft an updated title and description that preserves the original writing style.

## Step 1: Fetch Current PR

Fetch the current PR details:

```bash
gh pr view [PR_NUMBER] --json number,title,body,baseRefName,commits
```

Omit PR_NUMBER to auto-detect from current branch.

## Step 2: Analyze the Existing Style

Before drafting, study the current title and body to identify:

- **Title format** — length, prefix conventions (e.g., `feat:`, `fix:`), capitalization
- **Body structure** — headings, bullet points, sections, line length
- **Tone** — formal vs. casual, terse vs. detailed
- **Content patterns** — does it explain the "why", list changes, include test plans?
- **Diagrams** — does the body contain Mermaid code blocks (sequence, state, or other)?
- **Screenshots** — does the body embed uploaded images?

## Step 3: Evaluate Whether an Update Is Needed

Run `git fetch origin <base>` so the remote ref is current before any diff below. A local branch of the same name can sit behind the remote, which puts the merge base before an already-merged pull request and pulls merged work into the description.

Read the fetched body against the current diff and list what the body leaves undescribed:

```bash
git diff origin/<base>...HEAD
```

Check every Mermaid diagram in the body the same way, node by node and transition by transition. A diagram that omits a state still renders, so only the code reveals its staleness.

If the body and its diagrams already describe the diff, and the session holds no capture of a changed user-facing surface that the body lacks or shows in an older state, the description is up to date. Say so, then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

If what the body leaves undescribed is only trivial (formatting, typos, config-only) and the session holds no such capture, say so, then call `update_plan` to mark this step completed and continue with the next step of the active workflow. Proceed when the body omits, misstates, or still describes behavior the diff no longer contains.

## Step 4: Analyze the Full Diff

Derive the PR description from the full diff, not from individual commits. The description should reflect the net change — what the code looks like now vs. the base — not the development journey. Intermediate bug fixes, reverted approaches, and implementation pivots that happened during development are not relevant to the reader.

1. Work from the full diff Step 3 read (`git diff origin/<base>...HEAD`) — this is the primary source of truth
2. Use what Step 3 found undescribed to understand what's new, but frame everything in the context of the whole PR
3. Check if the changes introduce runtime flows or state transitions that warrant diagrams (see Diagrams section below)

## Step 5: Run `$github-voice` Skill

Run the `$github-voice` skill to load writing style rules.

## Step 6: Draft Updated Title and Description

Write an updated title and body that:

- **Matches the original style** — same structure, tone, formatting, and level of detail
- **Reflects the net change** — describe what the full diff shows, not the development history
- **Preserves what still applies** — keep existing text that remains accurate
- **Adds what's new** — integrate new changes naturally into the existing structure
- **Removes what's stale** — drop descriptions of work that was reverted or replaced
- **Scopes to the target repository** — write for someone who knows only the repository the PR targets; when the change is paired with work in another repository, name the interface the code calls and leave that repository's internal names, data shapes, and mechanisms out of the body; describe the change on its own terms, without reference to how a different repository or product does it
- **Updates diagrams** — if existing Mermaid diagrams are present, update them to reflect the current state; if they describe reverted code, remove them; if new changes warrant diagrams, add them
- **Updates screenshots** — leave the URL of each embedded image unaltered, removing an image only when the surface it shows is no longer part of the PR; add session captures as the Screenshots section directs, replacing an embedded screenshot only with a newer capture of the same surface

## Step 7: Confirm with User

Output the drafted title and description as text, alongside the original for comparison, followed by the path of each capture that will upload, if any. Then use `request_user_input` for confirmation.

## Step 8: Apply the Update

After confirmation, write the drafted title to `.turbo/pr/<PR_NUMBER>-title.txt` and the drafted body to `.turbo/pr/<PR_NUMBER>-body.md` with `apply_patch`, then update the PR. The title goes through a file because it carries text fetched from the PR, where backticks and `$` would run inside a quoted argument.

When the body references no capture by local path, update both in one command:

```bash
gh api --method PATCH "/repos/<owner>/<repo>/pulls/<PR_NUMBER>" \
  -F title=@.turbo/pr/<PR_NUMBER>-title.txt \
  -F body=@.turbo/pr/<PR_NUMBER>-body.md
```

When it references captures by local path, send the title alone, then apply the body with one `--attach <path>` per capture, using the absolute path the body references:

```bash
gh api --method PATCH "/repos/<owner>/<repo>/pulls/<PR_NUMBER>" \
  -F title=@.turbo/pr/<PR_NUMBER>-title.txt
gh pr edit <PR_NUMBER> --body-file .turbo/pr/<PR_NUMBER>-body.md --attach <path>
```

When `gh pr edit` reports a failed upload, act on what it printed, then report which captures the PR went without:

- **No PR URL** — nothing uploaded and the body was not applied. Remove each capture the body file references by local path, taking its table column with it and the table and its heading when no column remains. Then run `gh pr edit <PR_NUMBER> --body-file .turbo/pr/<PR_NUMBER>-body.md` without `--attach`.
- **A PR URL** — the body was applied, referencing the captures that did not upload by local path. Fetch the posted body with `gh pr view <PR_NUMBER> --json body --jq .body`, remove each table column whose image is still a local path, write the result to the body file, and apply it with the same command.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

## Diagrams

GitHub renders Mermaid natively in PR descriptions via ` ```mermaid ` code blocks. Include diagrams only when they add clarity a text description can't.

### Sequence Diagram

Include when the changes introduce or modify a clear runtime flow: API endpoints, event handlers, pipelines, multi-service interactions, webhook flows.

````markdown
```mermaid
sequenceDiagram
  Client->>API: POST /payments
  API->>PaymentService: processPayment()
  PaymentService->>StripeClient: charge()
  StripeClient-->>PaymentService: confirmation
  PaymentService->>DB: save()
```
````

### State Diagram

Include when the changes add or modify entity states, status enums, workflow transitions, or lifecycle hooks.

````markdown
```mermaid
stateDiagram-v2
  [*] --> Draft
  Draft --> Pending: submit()
  Pending --> Approved: approve()
  Pending --> Rejected: reject()
  Approved --> [*]
```
````

### Rules

- Keep diagrams focused — max ~10 nodes/transitions
- Use descriptive labels on arrows (method names, HTTP verbs)
- Place diagrams after the summary paragraph under a `## Flow` or `## State Machine` heading
- One diagram per type max — don't include both unless the PR truly has both patterns

## Screenshots

Include screenshots when the PR changes a user-facing surface and this session already holds captures of that surface in its final state. Reuse those captures after viewing each one, keeping the fewest that show the change. Take no new captures: with none on hand, leave the body's screenshots as they are.

Reference every kept capture in one row of a markdown table, with its caption in the header cell above it:

```markdown
| <caption> | <caption> |
| --- | --- |
| ![<caption>](<absolute path>) | ![<caption>](<absolute path>) |
```

When the body already embeds screenshots, keep their layout: a replacement capture takes the old image's place, and an added capture goes beside the existing ones.

### Rules

- Use markdown image syntax with the capture's absolute path. `gh` points only markdown references at the uploaded asset, so a raw `<img>` tag keeps its local path.
- Reference every attached capture in the body. `gh` appends an attached file the body never references as its own paragraph.
- Place a new table after the summary paragraph under a `## Screenshots` heading, ahead of any diagram.

## Rules

- If the existing body is empty or minimal, infer a style from the title and commit messages
- Keep titles under 72 characters
- Preserve any existing sections the user clearly cares about (test plans, checklists, links)
- Don't reference `.turbo/` content (filenames, acceptance criteria, step numbers, headings) in the title or body. `.turbo/` is gitignored, so these references would be opaque to anyone reading without local copies.
