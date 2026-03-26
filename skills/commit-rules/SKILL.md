---
name: commit-rules
description: "Shared commit message rules and technical constraints: imperative mood, concise single-line messages matching existing style, no heredoc syntax, never bypass commit signing. Referenced by /stage-commit and /commit-staged. Use when the user asks about \"commit message format\", \"commit conventions\", \"how to write commit messages\", or \"commit style\"."
---

# Commit Rules

## Commit Message Rules

- Match the style from `git log -n 10 --oneline`
- Concise and descriptive
- Imperative mood, present tense
- No commit description—summarize everything in the message

## Technical Constraints

- Use `git commit -m "message"` directly—do not use heredoc syntax (sandbox blocks temp file creation)
- Never bypass commit signing (`--no-gpg-sign`, `-c commit.gpgsign=false`). If signing fails, use `AskUserQuestion` to let the user resolve it—they may need to approve a key prompt.
