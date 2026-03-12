---
name: update-turbo
description: Update installed Turbo skills with a dynamic changelog, conflict resolution for customized skills, and guided user experience. Use when the user asks to "update turbo", "update turbo skills", "reinstall turbo", or "upgrade turbo".
---

# Update Turbo

Update installed Turbo skills with a dynamic changelog and interactive conflict resolution.

## Step 1: Gather State

Read two data sources:

1. **Config** — `~/.turbo/config.json` for `excludeSkills` (default: `[]`) and `lastCommit` (the commit hash from the last update)
2. **Lock file** — `~/.agents/.skill-lock.json` for installed Turbo skills (entries with `"source": "tobihagemann/turbo"`). Extract skill names.

Fetch upstream state:

```bash
# Latest commit on main
gh api repos/tobihagemann/turbo/commits/main --jq '.sha'

# Current skill list
gh api repos/tobihagemann/turbo/contents/skills --jq '.[].name'
```

If the latest commit matches `lastCommit`, report that Turbo is already up to date and stop.

## Step 2: Build Changelog

Compare the installed skill list (from lock file) against the upstream skill list to detect added and removed skills.

If `lastCommit` exists, fetch the diff to detect renames and modifications:

```bash
gh api "repos/tobihagemann/turbo/compare/<lastCommit>...<latest>"
```

From the response, filter `files` to entries where `filename` starts with `skills/`. Each file has `filename`, `status` (`added`, `removed`, `modified`, `renamed`), and `previous_filename` (for renames). Group by skill name.

For each modified or renamed skill, fetch both versions of the SKILL.md and diff the actual content:

```bash
# Old version (at baseline commit)
gh api "repos/tobihagemann/turbo/contents/skills/<name>/SKILL.md?ref=<lastCommit>" --jq '.content' | base64 -d

# New version (at latest commit)
gh api "repos/tobihagemann/turbo/contents/skills/<name>/SKILL.md?ref=<latest>" --jq '.content' | base64 -d
```

Read both versions and write a concise, plain-language summary of what changed. Focus on what the change means for the user: new capabilities, changed behavior, renamed commands, removed features. Flag anything that could be a breaking change (renamed skills that other skills reference, removed steps, changed interfaces).

For added skills, fetch their SKILL.md and summarize what they do.

## Step 3: Present Changelog

Use `AskUserQuestion` to present a formatted changelog. Example format:

```
Turbo Update Available

Added:
- /new-skill — Brief description of what it does

Removed:
- /old-skill

Renamed:
- /old-name → /new-name

Modified:
- /skill-a — Now launches 4 review agents instead of 3, adds clarity review
- /skill-b — Delegates to /review-code instead of running review inline

⚠ Breaking: /old-name renamed to /new-name — update any custom workflows

Proceed with update?
```

If the user declines, stop.

## Step 4: Resolve Conflicts

For each **modified** or **renamed** skill, check for local customizations by comparing the installed SKILL.md content against the upstream version at `lastCommit`. Fetch the old upstream version:

```bash
gh api "repos/tobihagemann/turbo/contents/skills/<name>/SKILL.md?ref=<lastCommit>" --jq '.content' | base64 -d
```

Read the installed file at `~/.claude/skills/<name>/SKILL.md` and compare. If they differ, the user has customized this skill.

For each customized skill with upstream changes, use `AskUserQuestion`:

```
/skill-name has upstream changes, but you've customized your local copy.

What changed upstream:
- Now uses /review-code instead of running peer review inline
- Added a new "Simplify review fixes" sub-step

Options:
1. Merge — apply upstream changes while preserving your customizations
2. Overwrite — replace with upstream version (customizations will be lost)
3. Skip — keep your version unchanged
4. Exclude — skip and exclude from future updates
```

Before proceeding to the next step, save the content of any customized skill where the user chose "Merge" (read the file now, before install overwrites it).

## Step 5: Execute Update

### Handle removals and renames

For each removed or renamed-away skill:

```bash
npx skills remove <name> -g -y
```

### Install

Build the exclusion list from `excludeSkills` config + skills the user chose to skip or exclude.

If exclusions exist, install specific skills:

```bash
npx skills add tobihagemann/turbo --skill '<name1>' --skill '<name2>' ... --agent claude-code -y -g
```

If no exclusions, install all:

```bash
npx skills add tobihagemann/turbo --skill '*' --agent claude-code -y -g
```

### Merge customized skills

For each skill where the user chose "Merge":

1. The install step overwrote the file. Read the new upstream version (now installed at `~/.claude/skills/<name>/SKILL.md`).
2. Launch an agent with the user's saved customized version and the new upstream version. Instruct it to preserve the user's customizations while incorporating the upstream changes. The agent writes the merged result to `~/.claude/skills/<name>/SKILL.md`.

### Update permissions

If skills were added or renamed, use `AskUserQuestion` to offer updating `permissions.allow` in `~/.claude/settings.json`. Show the entries to add or remove. If the user confirms, read the settings file, update the array, and write it back.

## Step 6: Save State

Read `~/.turbo/config.json` (or start with `{}`), set `lastCommit` to the latest commit hash, merge any new exclusions into `excludeSkills`, and write it back. Create `~/.turbo/` if needed.

Report a summary of what was updated.
