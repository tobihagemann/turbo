---
name: prototype
description: "Build a self-contained local prototype at .turbo/prototypes/<slug>.html, drive it, and hand it to the user to settle unknowns that prose cannot answer. Use when the user asks to \"prototype this\", \"build a prototype\", \"mock this up\", \"show me what it would look like\", \"let me try the interaction first\", or when a decision waits on seeing a surface or using it firsthand."
---

# Prototype

Build a throwaway prototype that answers named unknowns, operate it, and hand it to the user for judgment.

## Step 1: Name What the Prototype Must Settle

Take the open unknowns from what was passed in. When nothing was passed in, derive them from the current work: the questions whose answers in prose would still leave the user guessing, such as what a surface looks like or whether an interaction pattern makes sense in the hand.

State each unknown as a question the user answers by using the prototype rather than by reading a description. Output that list as text before building, and keep anything outside it out of the prototype.

## Step 2: Resolve the Prototype Path

Reuse the slug of the plan that governs the work when there is one. Honor an explicit slug or output path the user passed in. Otherwise generate a slug from the task title:

- Lowercase
- Replace non-alphanumeric characters with hyphens
- Collapse consecutive hyphens
- Trim leading and trailing hyphens
- Truncate to 40 characters at a word boundary

Write to `.turbo/prototypes/<slug>.html`, creating the directory when it does not exist. State the resolved path before writing. Later rounds of the same prototype rewrite that same file. When the path holds a prototype of a different subject, append `-2`, `-3`, and so on until the path is free.

## Step 3: Build It

Write one self-contained `.html` file at the resolved path, with markup, styles, script, and sample data inline. It runs from `file://` with no build step, no package install, and no dependency on the real application.

Build only what the Step 1 questions require. Hardcode the data behind them, stub anything that would cross a network boundary, and leave persistence out.

## Step 4: Operate It

Open the file and drive it yourself before handing it over, using the `browser-use@openai-bundled` plugin.

Exercise every control and flow that the Step 1 questions depend on, and confirm each one is reachable and responds. Fix whatever does not work and drive it again. A render or a screenshot leaves the controls untested, so it does not establish that the user can reach what they are being asked to judge.

## Step 5: Hand It Over

Give the user the file path, the Step 1 questions the prototype answers, and what to try for each. Then use `request_user_input` for their verdict:

- **Settled** — the prototype answered the questions.
- **Needs changes** — the user describes what to change. Return to Step 3 and continue from there, so every later round is driven in Step 4 before it reaches the user.

## Step 6: Record What It Settled

Delete from the prototype file every approach it disproved, so that nothing which failed survives in the file as apparent implementation. Keep what the settled answers rest on.

Then state each Step 1 question with the answer the prototype produced, and name separately anything it disproved. Carry these answers into the work that prompted the prototype. Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

## Rules

- The prototype file is the only output. Application code stays untouched.
