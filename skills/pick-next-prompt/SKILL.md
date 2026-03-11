---
name: pick-next-prompt
description: This skill should be used when the user asks to "pick next prompt", "next prompt", "continue prompt plan", "what's next", "next implementation step", "continue with the plan", or wants to pick the next prompt from .turbo/prompts.md and plan its implementation.
---

# Pick Next Prompt

Read the prompt plan at `.turbo/prompts.md`, pick the next prompt, and plan its implementation. This skill runs in plan mode — it produces an implementation plan for the selected prompt, ready for the user to approve and execute.

## Step 1: Read the Prompt Plan

Read `.turbo/prompts.md`. Parse all prompts extracting:
- Prompt number and title
- Status (`pending`, `in-progress`, `done`)
- Dependencies (`Depends on` field)
- The prompt text block

Also read `.turbo/spec.md` (or the spec path referenced in the prompt plan header) for full context.

## Step 2: Pick the Next Prompt

Find the first `pending` prompt whose dependencies are all `done`.

- **If found**: proceed to Step 4
- **If all prompts are `done`**: report completion to the user — the plan is finished
- **If remaining prompts are blocked**: report which prompts are blocked and by what

## Step 3: Adapt the Prompt

Re-read the spec and compare against the current project state. Run the `/plan-implementation` skill and apply its Adaptation section to adjust the prompt if implementation has diverged.

Update `.turbo/prompts.md` with adjustments to the selected prompt. For affected future prompts, update their Context and Depends-on fields if the adaptation changes what they can assume.

Mark the selected prompt `in-progress` in `.turbo/prompts.md`.

## Step 4: Discover Skills

Identify currently available skills from the skill list in the system prompt. Determine which skills are relevant for this prompt's work:

- Compare the prompt's work type against each skill's trigger description
- Skills may have been installed or removed since the plan was created

## Step 5: Plan the Implementation

This is the core of the skill. Using the selected prompt as the requirements, run the `/plan-implementation` skill and apply its "Planning Each Unit" section.

Additionally, the plan's final step must instruct: "Mark prompt N as `done` in `.turbo/prompts.md`."

The plan is the deliverable. After the user approves it, they clear context and execute in a clean session. The skills line ensures the implementation session loads the right context.

## Rules

- Never modify the spec file — only `.turbo/prompts.md` is writable (besides the plan file)
- If the prompt plan file does not exist, tell the user to run `/create-prompt-plan` first
- Keep adaptations minimal — adjust only what diverged, do not rewrite prompts unnecessarily
