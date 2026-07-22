---
name: create-issue
description: "Create a GitHub issue with a drafted title and body. Use when the user asks to \"create an issue\", \"file an issue\", \"open an issue\", \"submit an issue\", \"report a bug\", \"file a bug report\", \"file a feature request\", or \"file a design proposal\"."
---

# Create Issue

Draft a focused title and body for a GitHub issue, then file it. Bug reports state reproduction steps and observed versus expected behavior.

## Step 1: Gather Context

Determine what the issue is about from the conversation. When the subject is ambiguous, use `request_user_input` to settle it before drafting.

List the repo's issue templates, read its labels, and search for an existing issue covering the same thing:

```bash
ls .github/ISSUE_TEMPLATE/ 2>/dev/null
gh label list --limit 100
gh issue list --search "<keywords>" --state all
```

Treat an empty listing as normal. When templates exist, read the one matching the issue type, and read `.github/ISSUE_TEMPLATE/config.yml` when present. Follow the template's structure and required sections, and apply the labels and title prefix the template declares. For a YAML issue form, render each field's `attributes.label` as a `###` heading with the answer beneath, matching what the web form produces. When `config.yml` sets `blank_issues_enabled: false`, choose a template rather than filing a blank issue.

When the search surfaces a plausible duplicate, present it and use `request_user_input` to confirm whether to file anyway.

## Step 2: Run `$github-voice` Skill

Run the `$github-voice` skill to load writing style rules.

## Step 3: Draft Title and Body

Draft the title and body. Output them as chat text so the user can review before anything is filed.

## Step 4: Confirm and Create

Use `request_user_input` for confirmation only. Generate a random tag so the body file is unique across sessions:

```bash
head -c 4 /dev/urandom | xxd -p
```

Write the drafted body to `.turbo/issue/<tag>-body.md` (using the printed tag) with `apply_patch`, then create the issue with `gh issue create --body-file`:

```bash
gh issue create --title "<TITLE>" --body-file .turbo/issue/<tag>-body.md --label "<LABEL>,<LABEL>"
```

Repeat `--label` when the template sets several. Drop `--label` when no existing label fits. Do not set `--assignee` or `--milestone` unless the user explicitly asks.

## Rules

- Don't reference `.turbo/` content (filenames, requirement IDs, shell references, headings) in the title or body. `.turbo/` is gitignored, so these references would be opaque to anyone reading without local copies.
- Create labels only when the user asks.
