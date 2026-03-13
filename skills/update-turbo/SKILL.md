---
name: update-turbo
description: Update installed Turbo skills from the local repo with a dynamic changelog, conflict resolution for customized skills, and guided user experience. Use when the user asks to "update turbo", "update turbo skills", "reinstall turbo", or "upgrade turbo".
---

# Update Turbo

Update installed Turbo skills from the local repo at `~/.turbo/repo/` with a dynamic changelog and interactive conflict resolution.

## Step 1: Gather State

Read `~/.turbo/config.json` for:

- `repoMode` — `"clone"`, `"fork"`, or `"source"`
- `excludeSkills` (default: `[]`)
- `lastUpdateHead` — the commit hash from the last update

### Migration Check

If `~/.turbo/config.json` does not exist or has no `lastUpdateHead`, check whether the user has an old `npx skills` installation:

```bash
# Old system used symlinks into ~/.agents/skills/
ls -la ~/.claude/skills/finalize 2>/dev/null
```

If the symlink points into `~/.agents/skills/`, offer to migrate:

1. Ask the user: consume only (clone), contribute (fork), or maintain (source)?
2. Clone the repo to `~/.turbo/repo/` (see SETUP.md Step 1a for the exact commands per mode)
3. For each Turbo skill in `~/.agents/.skill-lock.json` (where `source` is `tobihagemann/turbo`):
   - Read the installed file at `~/.claude/skills/<name>/SKILL.md` (resolve symlink first)
   - Read the upstream version at `~/.turbo/repo/skills/<name>/SKILL.md`
   - Note whether the user has customized this skill (contents differ)
4. Remove old installations: `npx skills remove <name>` for each Turbo skill
5. Copy skills from the repo. For customized skills, copy the user's version instead
6. Initialize `~/.turbo/config.json` with `repoMode`, `excludeSkills: []`, and `lastUpdateHead` set to `git -C ~/.turbo/repo rev-parse HEAD`
7. Report migration complete and stop

### Fetch Updates

Determine the upstream remote based on `repoMode`:

- Clone or source: `origin`
- Fork: `upstream`

```bash
git -C ~/.turbo/repo fetch <remote>
```

Compare `lastUpdateHead` with the fetched main HEAD:

```bash
git -C ~/.turbo/repo rev-parse <remote>/main
```

If they match, report that Turbo is already up to date and stop.

## Step 2: Build Changelog

Use local git commands to detect changes since `lastUpdateHead`. Use the upstream remote determined in Step 1.

```bash
# Changed skill files
git -C ~/.turbo/repo diff --name-status <lastUpdateHead>..<remote>/main -- skills/

# Commit history for context
git -C ~/.turbo/repo log --oneline <lastUpdateHead>..<remote>/main -- skills/
```

From the `--name-status` output, each entry has a status (`A` added, `D` deleted, `M` modified, `R` renamed with old path). Group by skill name (extract from `skills/<name>/...`).

For each modified or renamed skill, read both versions of the SKILL.md:

```bash
# Old version
git -C ~/.turbo/repo show <lastUpdateHead>:skills/<name>/SKILL.md

# New version
git -C ~/.turbo/repo show <remote>/main:skills/<name>/SKILL.md
```

Read both versions and write a concise, plain-language summary of what changed. Focus on what the change means for the user: new capabilities, changed behavior, renamed commands, removed features. Flag anything that could be a breaking change (renamed skills that other skills reference, removed steps, changed interfaces).

For added skills, read their new SKILL.md and summarize what they do.

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

For each **modified** or **renamed** skill, check for local customizations using a three-way comparison:

1. Read the installed copy at `~/.claude/skills/<name>/SKILL.md`
2. Read the old upstream version: `git -C ~/.turbo/repo show <lastUpdateHead>:skills/<name>/SKILL.md`
3. If the installed copy matches the old upstream: no customization, auto-update in Step 5
4. If they differ: the user has customized this skill

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

Before proceeding to the next step, save the content of any customized skill where the user chose "Merge" (read the file now, before the copy step overwrites it).

## Step 5: Execute Update

### Pull

Pull the latest changes into the local repo:

- Clone or source: `git -C ~/.turbo/repo pull origin main`
- Fork: `git -C ~/.turbo/repo pull upstream main`, then `git -C ~/.turbo/repo push origin main` to sync the fork

### Copy skills

Build the exclusion list from `excludeSkills` config + skills the user chose to skip or exclude.

For each skill in `~/.turbo/repo/skills/` that is not excluded:

- **New skills**: `cp -r ~/.turbo/repo/skills/<name> ~/.claude/skills/<name>`
- **Removed skills**: `rm -rf ~/.claude/skills/<name>`, warn the user
- **Renamed skills**: Remove old directory, copy new
- **Modified (no customization)**: `cp -r ~/.turbo/repo/skills/<name> ~/.claude/skills/<name>` to overwrite

### Merge customized skills

For each skill where the user chose "Merge":

1. The copy step overwrote the file. Read the new upstream version (now installed at `~/.claude/skills/<name>/SKILL.md`).
2. Launch an agent with the user's saved customized version and the new upstream version. Instruct it to preserve the user's customizations while incorporating the upstream changes. The agent writes the merged result to `~/.claude/skills/<name>/SKILL.md`.

### Update permissions

If skills were added or renamed, use `AskUserQuestion` to offer updating `permissions.allow` in `~/.claude/settings.json`. Generate the entries from the local repo:

```bash
ls ~/.turbo/repo/skills/ | sed 's/.*/"Skill(&)"/'
```

Show the entries to add or remove. If the user confirms, read the settings file, update the array, and write it back.

## Step 6: Save State

Read `~/.turbo/config.json`, set `lastUpdateHead` to the new HEAD (`git -C ~/.turbo/repo rev-parse HEAD`), merge any new exclusions into `excludeSkills`, and write it back.

Report a summary of what was updated.
