---
name: commit-staged
description: This skill should be used when the user asks to "commit staged changes", "commit what's staged", "create a commit from staging", or wants to commit already-staged files without staging new ones.
---

# Commit Staged Changes

Commit already-staged changes with a message matching existing commit style.

## Commit Message Rules

- Match the style from `git log -n 10 --oneline`
- Concise and descriptive
- Imperative mood, present tense
- No commit description—summarize everything in the message

## Staging Rules

- Changes are already staged and ready to commit
- Do not stage any files

## Technical Note

- Use `git commit -m "message"` directly—do not use heredoc syntax (sandbox blocks temp file creation)
