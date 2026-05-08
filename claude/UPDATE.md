# Update Turbo

Update installed Turbo skills from the local repo at `~/.turbo/repo/` with a dynamic changelog and interactive conflict resolution.

## Phase 1: Analysis

### Step 1: Fetch

Read `~/.turbo/config.json` for `repoMode` (top-level: `"clone"`, `"fork"`, or `"source"`).

Determine the upstream remote based on `repoMode`:

- Clone or source: `origin`
- Fork: `upstream`

```bash
git -C ~/.turbo/repo fetch <remote>
```

### Step 2: Run Migrations

**Current version: 3**

Read `configVersion` from `~/.turbo/config.json`, looking at `claude.configVersion` first and falling back to top-level `configVersion` for legacy installs (default: `0` if missing). Migrations run before any head comparison so legacy users on a current commit still pick up schema migrations.

If `configVersion` equals the current version, skip to Step 3.

Otherwise, read `MIGRATION.md` from the fetched remote:

```bash
git -C ~/.turbo/repo show <remote>/main:claude/MIGRATION.md
```

For each migration where the version number is greater than `configVersion`, in ascending order:

1. Check the migration's **Condition**. If the condition is not met and a **Skip if** clause applies, skip it.
2. Otherwise, follow the migration's **Steps**.
3. After completing (or skipping) the migration, continue to the next one.

After all migrations are processed, set `claude.configVersion` to the current version in `~/.turbo/config.json`.

If any migration initialized config and reported completion (e.g., a first-time migration that sets up the repo), stop here. The user can run `/update-turbo` again to continue with the normal update flow.

### Step 3: Compare State

Read from `~/.turbo/config.json`:

- `claude.excludeSkills` (default: `[]`)
- `claude.lastUpdateHead` — the commit hash from the last update

Compare `claude.lastUpdateHead` with the fetched main HEAD:

```bash
git -C ~/.turbo/repo rev-parse <remote>/main
```

If they match, report that Turbo is already up to date and stop.

### Step 4: Build Changelog

Use local git commands to detect changes since `claude.lastUpdateHead`. Use the upstream remote determined in Step 1. The angle-bracket `<lastUpdateHead>` in the snippets below is the shell placeholder for that value.

```bash
# Changed skill files
git -C ~/.turbo/repo diff --name-status <lastUpdateHead>..<remote>/main -- claude/skills/

# Commit history for context
git -C ~/.turbo/repo log --oneline <lastUpdateHead>..<remote>/main -- claude/skills/
```

From the `--name-status` output, each entry has a status (`A` added, `D` deleted, `M` modified, `R` renamed with old path). Group by skill name (extract from `claude/skills/<name>/...`).

For each modified or renamed skill, read both versions of the SKILL.md:

```bash
# Old version
git -C ~/.turbo/repo show <lastUpdateHead>:claude/skills/<name>/SKILL.md

# New version
git -C ~/.turbo/repo show <remote>/main:claude/skills/<name>/SKILL.md
```

Read both versions and write a concise, plain-language summary of what changed. Focus on what the change means for the user: new capabilities, changed behavior, renamed commands, removed features. Flag anything that could be a breaking change (renamed skills that other skills reference, removed steps, changed interfaces).

For added skills, read their new SKILL.md and summarize what they do.

Also check for changes to `claude/ADDITIONS.md`:

```bash
git -C ~/.turbo/repo diff --name-status <lastUpdateHead>..<remote>/main -- claude/ADDITIONS.md
```

If modified, read both versions and summarize what changed: new sections added, existing sections updated, or sections removed.

### Step 5: Present Changelog

Output the changelog as text. Example format:

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

CLAUDE.md Additions:
- Updated "Skill Loading" — added new rule about X
- New section "Section Name" — brief description
```

Then use `AskUserQuestion` to ask whether to proceed with the update. If the user declines, stop.

## Phase 2: Resolution

### Step 1: Detect Customizations

For each **modified** or **renamed** skill, check for local customizations using a three-way comparison:

1. Read the installed copy at `~/.claude/skills/<name>/SKILL.md` (for renamed skills, use the **old** name since that is what is currently installed)
2. Read the old upstream version: `git -C ~/.turbo/repo show <lastUpdateHead>:claude/skills/<name>/SKILL.md` (for renamed skills, use the **old** path)
3. If the installed copy matches the old upstream: no customization, auto-update in Phase 3
4. If they differ: the user has customized this skill

### Step 2: Resolve Conflicts

For each customized skill with upstream changes, use `AskUserQuestion`:

```
/<skill-name> has upstream changes, but you've customized your local copy.

What changed upstream:
- Now uses /review-code instead of running peer review inline
- Added a new "Simplify review fixes" sub-step

Options:
1. Merge — apply upstream changes while preserving your customizations
2. Overwrite — replace with upstream version (customizations will be lost)
3. Skip — keep your version unchanged
4. Exclude — skip and exclude from future updates
```

### Step 3: Save Customized Content

Before proceeding to Phase 3, save the content of any customized skill where the user chose "Merge" (read the file now, before the copy step overwrites it).

## Phase 3: Execution

### Step 1: Pull

Pull the latest changes into the local repo:

- Clone or source: `git -C ~/.turbo/repo pull origin main`
- Fork: `git -C ~/.turbo/repo pull upstream main`, then `git -C ~/.turbo/repo push origin main` to sync the fork

### Step 2: Copy Skills

Build the exclusion list from `claude.excludeSkills` plus skills the user chose to skip or exclude.

For each skill in `~/.turbo/repo/claude/skills/` that is not excluded:

- **New skills**: `cp -r ~/.turbo/repo/claude/skills/<name> ~/.claude/skills/<name>`
- **Removed skills**: `rm -rf ~/.claude/skills/<name>`, warn the user
- **Renamed skills**: Remove old directory, copy new. If the old name appears in `claude.excludeSkills`, replace it with the new name.
- **Modified (no customization)**: Remove old directory, then `cp -r ~/.turbo/repo/claude/skills/<name> ~/.claude/skills/<name>`

### Step 3: Merge Customized Skills

For each skill where the user chose "Merge":

1. The copy step overwrote the file. Read the new upstream version (now installed at `~/.claude/skills/<name>/SKILL.md`).
2. Launch an agent with the user's saved customized version and the new upstream version. Instruct it to preserve the user's customizations while incorporating the upstream changes. The agent writes the merged result to `~/.claude/skills/<name>/SKILL.md`.

### Step 4: Sync CLAUDE.md Additions

If `claude/ADDITIONS.md` changed since `claude.lastUpdateHead` (detected in Phase 1 Step 4):

1. Read `claude/ADDITIONS.md` from `~/.turbo/repo/`
2. Read `~/.claude/CLAUDE.md`
3. For each `##` section in `claude/ADDITIONS.md`:
   - If no matching `#` section exists in the user's file → **new**
   - If a matching section exists but content differs → **changed**
   - If content matches → skip
4. If there are new or changed sections, use `AskUserQuestion`:

```
CLAUDE.md additions updated:

New:
- "Section Name" — brief description

Changed:
- "Section Name" — what changed

Apply to ~/.claude/CLAUDE.md?
```

5. If approved, update `~/.claude/CLAUDE.md`:
   - Append new sections as `#` headers
   - Replace changed sections with the updated content

Never overwrite unrelated user instructions.

### Step 5: Save State

Write the new HEAD to `claude.lastUpdateHead`:

```bash
head=$(git -C ~/.turbo/repo rev-parse HEAD)
tmp=$(mktemp)
jq --arg head "$head" '.claude.lastUpdateHead = $head' ~/.turbo/config.json > "$tmp" && mv "$tmp" ~/.turbo/config.json
```

If Phase 2 added new exclusions, merge them into `claude.excludeSkills` via Edit.

Report a summary of what was updated.
