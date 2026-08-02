---
name: update-turbo
description: "Update installed Turbo Codex skills from the local repo with a dynamic changelog, conflict resolution for customized skills, and guided user experience. Use when the user asks to \"update turbo\", \"update turbo skills\", \"reinstall turbo\", \"upgrade turbo\", or \"update turbo for codex\"."
---

# Update Turbo

Read the latest update instructions from the local repo and follow them.

## Step 1: Read Instructions

Fetch `origin`, then read the latest Codex UPDATE.md:

```bash
git -C ~/.turbo/repo fetch origin
git -C ~/.turbo/repo show origin/main:codex/UPDATE.md
```

## Step 2: Follow Instructions

Follow the fetched UPDATE.md instructions from start to finish.
