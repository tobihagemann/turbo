---
name: pick-next-prompt
description: "Pick the next ready shell from a prompt plan in .turbo/prompt-plans/ and hand it to /turboplan for fill-in. Use when the user asks to \"pick next prompt\", \"next prompt\", \"continue prompt plan\", \"what's next\", \"next implementation step\", or \"continue with the plan\"."
---

# Pick Next Prompt

Pick the next ready shell from a prompt plan index and hand it to `/turboplan` in shell mode for fill-in, refinement, and implementation.

The prompt plan index is a thin manifest at `.turbo/prompt-plans/<slug>.md` that lists shells by number, status (pending/in-progress/done), shell file path, and dependencies. The shell content lives in separate files at `.turbo/plans/<spec-slug>-NN-<title>.md`. This skill handles the index side: resolving, picking, and marking in-progress. `/turboplan` (in shell mode) handles the shell side: fill-in, refine, implement, finalize.

## Step 1: Resolve the Prompt Plan Index

Determine which prompt plan index to read using these rules in order:

1. **Explicit path** — If the user passed a file path, use it
2. **Explicit slug** — If a slug was passed, resolve to `.turbo/prompt-plans/<slug>.md`
3. **In-progress wins** — Glob `.turbo/prompt-plans/*.md`. If exactly one index has any prompt with `Status: in-progress`, use it. This is the prompt plan currently being worked on.
4. **Single file** — If exactly one index file exists, use it
5. **Most recent** — If no index has an in-progress prompt and rule 3 did not resolve, use the most recently modified file
6. **Legacy fallback** — If `.turbo/prompt-plans/` does not exist but `.turbo/prompts.md` exists, the user is on the legacy free-text format. Tell them to re-run `/create-prompt-plan` to upgrade to shells, and halt without further processing.
7. **Nothing found** — If no prompt plan exists, tell the user to run `/turboplan` for a complex task (which will route to `/create-spec` + `/create-prompt-plan`) and stop

If multiple files have in-progress prompts (concurrent work in different feature branches), use `AskUserQuestion` to let the user pick.

State the resolved index path before continuing.

Read the index file. Each prompt entry uses bold-prefixed inline markers under a `## Prompt N:` heading. Parse:

- Prompt number and title (from the `## Prompt N: <title>` heading)
- Status (`**Status:** pending` / `in-progress` / `done`)
- Shell file path (`**Shell:** <path>`)
- Dependencies (`**Depends on:** none` or `Prompt N`)

## Step 2: Pick the Next Ready Shell

Find the first `pending` prompt whose dependencies are all `done`.

- **If found** — proceed to Step 3
- **If all prompts are `done`** — report completion to the user — the plan is finished
- **If remaining prompts are blocked** — report which prompts are blocked and by what

## Step 3: Mark In-Progress and Read the Shell

Update the index file to mark the selected prompt `in-progress`.

Read the shell file at the path from the prompt's `Shell:` field. Verify the file exists and contains the expected shell structure (Context, Produces, Consumes, Covers Spec Requirements, Implementation Steps, Open Questions). If the shell file is missing, stop and report — the index and shell files are out of sync.

## Step 4: Run `/turboplan` Skill

Run the `/turboplan` skill, passing the shell file path as input. `/turboplan` detects shell mode, skips complexity analysis, and runs `/draft-plan` in fill-in mode (which verifies Consumes, refreshes the pattern survey, escalates the shell's Open Questions, and writes a full plan back to the shell path). Then `/turboplan` continues through `/refine-plan`, the confirmation gate, and `/implement-plan`.

Tell `/turboplan` (via its task description) that the plan's final implementation step must include: "Mark prompt N as `done` in the prompt plan index at `<index path>`."

## Rules

- Never modify the spec file — only the prompt plan index is writable by this skill (shell files are writable by `/draft-plan` in fill-in mode, not by this skill directly)
- If no prompt plan index is found, tell the user to run `/turboplan` for a complex task — the routing inside `/turboplan` handles the spec + prompt plan creation
- Do not pre-verify Consumes or refresh surveys here — that's `/draft-plan`'s fill-in mode job
- Do not re-draft or re-analyze the shell — `/turboplan` in shell mode handles the full expansion
- If the index references a shell file that does not exist, halt — do not silently recover by regenerating the shell
