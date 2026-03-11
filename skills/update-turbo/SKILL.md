---
name: update-turbo
description: Update installed Turbo skills to the latest version with conflict detection and exclusion support. Use when the user asks to "update turbo", "update turbo skills", "reinstall turbo", or "upgrade turbo".
---

# Update Turbo

Update installed Turbo skills to the latest version, respecting excluded skills and detecting conflicts.

## Step 1: Read Config

Read `~/.turbo/config.json` if it exists. Check for an `excludeSkills` array:

```json
{
  "excludeSkills": ["codex", "oracle"]
}
```

## Step 2: Detect Conflicts

Fetch the list of Turbo skills and check for non-symlinked skills that would be overwritten. Skip skills already in `excludeSkills`:

```bash
for skill in $(gh api repos/tobihagemann/turbo/contents/skills --jq '.[].name'); do
  # skip if already excluded
  target="$HOME/.claude/skills/$skill"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "CONFLICT: $target exists and is not a symlink"
  fi
done
```

If conflicts are found, use `AskUserQuestion` to alert the user. For each conflicting skill, offer two options:
1. **Overwrite** — proceed with installation
2. **Exclude** — add the skill to `excludeSkills` in `~/.turbo/config.json` and skip it

Create `~/.turbo/config.json` if it doesn't exist. Merge the `excludeSkills` key into existing config.

## Step 3: Install

If there are excluded skills (from config or user choice), build a specific skill list:

```bash
npx skills add tobihagemann/turbo --skill 'skill1' --skill 'skill2' ... --agent claude-code -y -g
```

If no exclusions, install all:

```bash
npx skills add tobihagemann/turbo --skill '*' --agent claude-code -y -g
```

## Step 4: Clean Up Removed Skills

After installing, detect skills that were previously installed from Turbo but are no longer in the current release. Use two data sources to identify Turbo-owned skills:

1. **`skills-lock.json`** (primary) — check `~/.claude/skills/skills-lock.json` for entries with `"source": "tobihagemann/turbo"`. Extract the skill names.
2. **Symlink check** (fallback) — if no lock file, check `~/.claude/skills/*` for symlinks pointing to `../../.agents/skills/`. These are CLI-managed globals.

Compare against the just-installed skill list. The install output lists all skills it installed — use that list. Alternatively, fetch from the repo:

```bash
gh api repos/tobihagemann/turbo/contents/skills --jq '.[].name'
```

If `gh api` fails (TLS errors, rate limits), fall back to checking which symlinks in `~/.claude/skills/` are now broken:

```bash
for skill in ~/.claude/skills/*; do
  [ -L "$skill" ] || continue
  [ -e "$skill" ] && continue  # symlink target exists, skip
  echo "STALE: $(basename "$skill")"
done
```

For each stale skill found, inform the user via `AskUserQuestion` and remove:

```bash
npx skills remove <skill-name> -g -y
```

Also remove the stale entry from `~/.claude/skills/skills-lock.json` if present (delete the key from the `skills` object).
