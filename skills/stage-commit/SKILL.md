---
name: stage-commit
description: This skill should be used when the user asks to "stage and commit", "commit these changes", "commit my changes", "make a commit", or wants to stage files and create a commit in one step.
---

# Stage and Commit Changes

Stage and commit changes with a message matching existing commit style.

## Commit Message Rules

- Match the style from `git log -n 10 --oneline`
- Concise and descriptive
- Imperative mood, present tense
- No commit description—summarize everything in the message

## Staging Rules

- Stage only the changes to commit
- Leave other unstaged changes alone

## Technical Note

- Use `git commit -m "message"` directly—do not use heredoc syntax (sandbox blocks temp file creation)
