---
name: peer-review
description: This skill should be used when the user asks to "review my code", "peer review", "review changes", "review the diff", "review uncommitted changes", "review against main", or wants AI-powered code review of their changes.
---

# Peer Review

AI-powered code review of changes. Delegates to `/codex` in review mode by default.

## Usage

Determine what to review based on context:

- **Uncommitted changes**: run `/codex` with `--uncommitted`
- **Against a base branch**: run `/codex` with `--base <branch>`
- **Specific commit**: run `/codex` with `--commit <sha>`

Pass `--title` when reviewing a feature branch or PR to give the reviewer context.

Capture and return the full review output.
