---
name: contribute
description: "Propose a turbo skill improvement as a GitHub issue on the turbo repo. Use when the user asks to \"contribute to turbo\", \"contribute back\", or \"upstream my changes\"."
---

# Contribute

Propose an improvement to a turbo skill as an issue on `tobihagemann/turbo`.

## Step 1: Identify the Proposed Change

Take the proposed changes from the lessons passed in: each names the turbo skill it targets, the change, and the session evidence behind it. Without them, take the proposed changes from conversation context. When neither describes a change to a turbo skill, tell the user there is nothing to contribute and stop.

Read each target skill's current text upstream, so each change is stated against the file as it stands on `main`:

```bash
gh api repos/tobihagemann/turbo/contents/claude/skills/<name>/SKILL.md -H 'Accept: application/vnd.github.raw'
```

Leave out a change whose target skill does not exist upstream, and tell the user.

Present the changes in a summary table:

```
| # | Skill | Change Summary |
|---|-------|----------------|
| 1 | /evaluate-findings | Added handling for security-default findings |
| 2 | /self-improve | Clarified routing for trusted reviewer feedback |
```

Use `AskUserQuestion` to confirm which changes to propose.

## Step 2: Craft Contribution Context

For each change, construct a "why" explanation. The goal: the turbo maintainer should understand what happened and why the existing instructions were insufficient, without learning anything about the contributor's project.

Use this template:

> During [general workflow description], the skill's instructions [what was missing or wrong]. This caused [what happened]. The change [what it does] so that [benefit].

**Example:**

> During a code review session, the evaluate-findings skill encountered a finding with `security-default` severity. The existing instructions only handled `critical`, `high`, `medium`, and `low` severities, causing the finding to be silently dropped. The change adds `security-default` to the severity handling table so these findings are properly triaged.

The maintainer implements the change, so state it concretely alongside the "why": the file path under `claude/skills/<name>/`, the step or section it belongs in, and the exact replacement text or a diff.

### Privacy Filter

Before finalizing, verify the whole proposal — the "why" explanation, the cited paths, and the proposed replacement text — contains none of the following:

- Project or repo names
- File paths from the user's project
- Company or product names
- API keys, URLs, or credentials
- Business logic or domain-specific terminology that identifies the project
- User names beyond the contributor's GitHub handle

Output the drafted proposal as text. Then use `AskUserQuestion` for approval. The user must approve the proposal before proceeding.

## Step 3: Run `/create-issue` Skill

Use `TaskCreate` to create a task for each approved concern. Process concerns in order, one concern per issue.

For each concern, run the `/create-issue` skill, filing against `tobihagemann/turbo` rather than the current project's repo. The approved text from Step 2 is the issue body; leave it as approved rather than re-deriving it from conversation context.

Report each issue URL.

Then use the TaskList tool and proceed to any remaining task.
