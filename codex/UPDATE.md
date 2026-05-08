# Update Turbo for Codex

Update installed Turbo Codex skills from the local repo at `~/.turbo/repo/` with a changelog and conflict handling.

## Phase 1: Analysis

### Step 1: Fetch

Read `~/.turbo/config.json` for `repoMode` (top-level: `"clone"`, `"fork"`, or `"source"`).

Determine the upstream remote:

- Clone or source: `origin`
- Fork: `upstream`

```bash
git -C ~/.turbo/repo fetch <remote>
```

### Step 2: Run Migrations

**Current version: 1**

Read `codex.configVersion` from `~/.turbo/config.json` (default: `0` if missing). Migrations run before any head comparison so users on a current commit still pick up schema migrations.

If `codex.configVersion` equals the current version, skip to Step 3.

Otherwise, read `MIGRATION.md` from the fetched remote:

```bash
git -C ~/.turbo/repo show <remote>/main:codex/MIGRATION.md
```

For each migration where the version number is greater than `codex.configVersion`, in ascending order:

1. Check the migration's **Condition**. If the condition is not met and a **Skip if** clause applies, skip it.
2. Otherwise, follow the migration's **Steps**.
3. After completing (or skipping) the migration, continue to the next one.

After all migrations are processed, set `codex.configVersion` to the current version in `~/.turbo/config.json`.

If any migration initialized config and reported completion (e.g., a first-time migration that sets up the repo), stop here. The user can run `$update-turbo` again to continue with the normal update flow.

### Step 3: Compare State

Read from `~/.turbo/config.json`:

- `codex.excludeSkills` (default: `[]`)
- `codex.lastUpdateHead`

Compare `codex.lastUpdateHead` with the fetched main HEAD:

```bash
git -C ~/.turbo/repo rev-parse <remote>/main
```

If they match, report that Turbo for Codex is already up to date and stop.

### Step 4: Build Changelog

Use local git commands to detect changes since `codex.lastUpdateHead`. The angle-bracket `<lastUpdateHead>` in the snippets below is the shell placeholder for that value.

```bash
# Changed skill files
git -C ~/.turbo/repo diff --name-status <lastUpdateHead>..<remote>/main -- codex/skills/

# Commit history for context
git -C ~/.turbo/repo log --oneline <lastUpdateHead>..<remote>/main -- codex/skills/
```

From the `--name-status` output, each entry has a status (`A` added, `D` deleted, `M` modified, `R` renamed with old path). Group by skill name (extract from `codex/skills/<name>/...`).

For each modified or renamed skill, read both versions of the SKILL.md:

```bash
# Old version
git -C ~/.turbo/repo show <lastUpdateHead>:codex/skills/<name>/SKILL.md

# New version
git -C ~/.turbo/repo show <remote>/main:codex/skills/<name>/SKILL.md
```

Read both versions and write a concise, plain-language summary of what changed. Focus on what the change means for the user: new capabilities, changed behavior, renamed commands, removed features. Flag anything that could be a breaking change (renamed skills that other skills reference, removed steps, changed interfaces, peer-review behavior changes).

For added skills, read their new SKILL.md and summarize what they do.

Also check for changes to `codex/ADDITIONS.md`:

```bash
git -C ~/.turbo/repo diff --name-status <lastUpdateHead>..<remote>/main -- codex/ADDITIONS.md
```

If modified, read both versions and summarize what changed: new sections added, existing sections updated, or sections removed.

### Step 5: Present Changelog

Output the changelog as text. Example format:

```
Turbo Codex Update Available

Added:
- $new-skill — Brief description of what it does

Removed:
- $old-skill

Renamed:
- $old-name → $new-name

Modified:
- $skill-a — Now delegates to $review-code instead of running review inline
- $skill-b — Updated peer-review behavior to use the latest $claude-print contract

⚠ Breaking: $old-name renamed to $new-name — update any custom workflows

AGENTS.md Additions:
- Updated "Skill Loading" — added new rule about X
- New section "Section Name" — brief description
```

Then ask the user whether to proceed with the update. If the user declines, stop.

## Phase 2: Resolution

### Step 1: Detect Customizations

For each **modified** or **renamed** skill, check for local customizations using a three-way comparison:

1. Read the installed copy at `~/.agents/skills/<name>/SKILL.md` (for renamed skills, use the **old** name since that is what is currently installed).
2. Read the old upstream version: `git -C ~/.turbo/repo show <lastUpdateHead>:codex/skills/<name>/SKILL.md` (for renamed skills, use the **old** path).
3. If the installed copy matches the old upstream: no customization, auto-update in Phase 3.
4. If they differ: the user has customized this skill.

### Step 2: Resolve Conflicts

For each customized skill with upstream changes, use `request_user_input` to ask:

```
$<skill-name> has upstream changes, but you've customized your local copy.

What changed upstream:
- Now delegates to $review-code instead of running peer review inline
- Added a new "Simplify review fixes" sub-step

Options:
1. Merge — apply upstream changes while preserving your customizations
2. Overwrite — replace with upstream version (customizations will be lost)
3. Skip — keep your version unchanged
```

If the user picks **Skip**, follow up with a second `request_user_input` asking whether to also exclude the skill from future updates (Yes / No). This keeps each gate within the 3-option cap.

### Step 3: Save Customized Content

Before proceeding to Phase 3, save the content of any customized skill where the user chose "Merge" (read the file now, before the copy step overwrites it).

## Phase 3: Execution

### Step 1: Pull

Pull the latest changes into the local repo:

- Clone or source: `git -C ~/.turbo/repo pull origin main`
- Fork: `git -C ~/.turbo/repo pull upstream main`, then `git -C ~/.turbo/repo push origin main`

### Step 2: Copy Skills

Build the exclusion list from `codex.excludeSkills` plus skills the user chose to skip or exclude.

For each skill in `~/.turbo/repo/codex/skills/` that is not excluded:

- **New skills**: `cp -R ~/.turbo/repo/codex/skills/<name> ~/.agents/skills/<name>`
- **Removed skills**: `rm -rf ~/.agents/skills/<name>`, warn the user
- **Renamed skills**: Remove old directory, copy new. If the old name appears in `codex.excludeSkills`, replace it with the new name.
- **Modified (no customization)**: Remove old directory, then `cp -R ~/.turbo/repo/codex/skills/<name> ~/.agents/skills/<name>`

### Step 3: Merge Customized Skills

For each skill where the user chose **Merge**:

1. The copy step overwrote the file. Read the new upstream version (now installed at `~/.agents/skills/<name>/SKILL.md`).
2. Using the saved customized version and the new upstream version, preserve the user's customizations while incorporating the upstream changes. Write the merged result back to `~/.agents/skills/<name>/SKILL.md`.

### Step 4: Sync AGENTS Additions

If `codex/ADDITIONS.md` changed since `codex.lastUpdateHead` (detected in Phase 1 Step 4):

1. Read `codex/ADDITIONS.md` from `~/.turbo/repo/`.
2. Determine which targets to sync. Setup writes ADDITIONS to two locations and either may be present:
   - **User-global:** `~/.codex/AGENTS.md` (or the configured Codex global instruction file, if the user overrode the default).
   - **Project-local:** the repository root `AGENTS.md` of the project the user is working in.
   For each location that exists, treat it as a sync target. Skip locations that don't exist (the user opted out at setup).
3. For each target, for each `##` section in `codex/ADDITIONS.md`:
   - If no matching same-named section exists in the target → **new**
   - If a matching section exists but content differs → **changed**
   - If content matches → skip
4. If any target has new or changed sections, ask the user:

```
AGENTS additions updated:

New:
- "Section Name" — brief description

Changed:
- "Section Name" — what changed

Apply to <list of target files that need updating>?
```

5. If approved, update each target file:
   - Append new sections under their original heading.
   - Replace changed sections with the updated content.

Never overwrite unrelated user instructions.

### Step 5: Save State

Write the new HEAD to `codex.lastUpdateHead`:

```bash
head=$(git -C ~/.turbo/repo rev-parse HEAD)
tmp=$(mktemp)
jq --arg head "$head" '.codex.lastUpdateHead = $head' ~/.turbo/config.json > "$tmp" && mv "$tmp" ~/.turbo/config.json
```

If Phase 2 added new exclusions, merge them into `codex.excludeSkills` via `apply_patch`.

Report a summary of updated, skipped, removed, and merged skills.
