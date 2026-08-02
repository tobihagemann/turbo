---
name: contribute-turbo
description: "Propose a turbo skill improvement upstream by filing a GitHub issue against the turbo repo. Use when the user asks to \"contribute to turbo\", \"submit turbo changes\", \"contribute back\", \"suggest a turbo improvement\", or \"upstream my changes\"."
---

# Contribute Turbo

Propose an improvement to a turbo skill as an issue on `tobihagemann/turbo`.

## Step 1: Identify the Proposed Change

Confirm the local repo exists:

```bash
test -d ~/.turbo/repo
```

If it does not, tell the user to run the Turbo setup first and stop.

Detect skills whose installed copy has drifted from the repo baseline:

```bash
for skill in ~/.claude/skills/*/; do
  name=$(basename "$skill")
  repo_dir=~/.turbo/repo/claude/skills/"$name"
  [ -d "$repo_dir" ] || continue
  diff -rq "$skill" "$repo_dir" >/dev/null 2>&1 && continue
  echo "$name"
done
```

For each drifted skill, read both versions of every file that differs and the single version of every file present on one side only. Classify each hunk and each one-sided file:

- **Correction** — a session edit meant to improve the skill upstream. Include it in the proposal.
- **Customization** — a persistent local addition that belongs to this machine only (extra workflow steps, personal paths, machine-specific notes, internal references). Leave it out of the proposal.
- **Upstream-newer** — content the repo copy carries and the installed copy lacks, left behind by a Skip or Exclude during an earlier update. Leave it out of the proposal.
- **Ambiguous** — use `AskUserQuestion` to confirm classification.

When no corrections survive classification, take the proposed change from conversation context instead. When the conversation describes no change either, tell the user there is nothing to contribute and stop.

Present the corrections in a summary table:

```
| # | Skill | Change Summary |
|---|-------|----------------|
| 1 | /evaluate-findings | Added handling for security-default findings |
| 2 | /self-improve | Clarified routing for trusted reviewer feedback |
```

Use `AskUserQuestion` to confirm which corrections to propose.

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
