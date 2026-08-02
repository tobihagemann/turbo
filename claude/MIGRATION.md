# Migrations

Versioned breaking change migrations for the Claude Code edition of Turbo. Each migration runs once during `/update-turbo` when the user's `claude.configVersion` in `~/.turbo/config.json` is below the migration's version number.

Migrations are executed in ascending order. After all applicable migrations complete, `claude.configVersion` is set to the highest migration version.

## Version 1: Migrate from `npx skills`

**Condition:** `~/.claude/skills/finalize` is a symlink pointing into `~/.agents/skills/`.

**Skip if:** The condition is not met (user never used `npx skills`).

### Steps

1. Clone the repo to `~/.turbo/repo/` (see SETUP.md Step 1)
2. For each Turbo skill (where `~/.claude/skills/<name>` is a symlink into `~/.agents/skills/` and has a matching directory in `~/.turbo/repo/claude/skills/`):
   - Read the installed file at `~/.claude/skills/<name>/SKILL.md` (resolve symlink first)
   - Read the upstream version at `~/.turbo/repo/claude/skills/<name>/SKILL.md`
   - Note whether the user has customized this skill (contents differ)
3. Remove old installations: `npx skills remove -g -y <name>` for each Turbo skill
4. Copy skills from the repo. For customized skills, copy the user's version instead
5. Initialize `~/.turbo/config.json` with `excludeSkills: []` and `lastUpdateHead` set to `git -C ~/.turbo/repo rev-parse HEAD`
6. Report migration complete

## Version 2: Remove Skill Permissions

**Condition:** `~/.claude/settings.json` contains any `Skill(...)` entries in `permissions.allow`.

**Skip if:** No `Skill(...)` entries exist in `permissions.allow`.

### Steps

1. Read `~/.claude/settings.json`, remove all entries matching `Skill(...)` from the `permissions.allow` array, and write the file back.

Since Claude Code 2.1.19, skills without additional permissions or hooks are auto-allowed, making these entries unnecessary.

## Version 3: Nest Edition Config Keys

**Condition:** `~/.turbo/config.json` has any of `lastUpdateHead`, `excludeSkills`, or `configVersion` at the top level.

**Skip if:** None of those keys exist at the top level (already nested under `claude.*`, or the file does not yet exist).

### Steps

The Claude edition's config keys move from the top level into a `claude` object so the Codex edition can use a parallel `codex` object without colliding. `repoMode` and `oracle` stay at the top level (they are shared or skill-scoped).

1. Read `~/.turbo/config.json`.
2. Move the existing top-level `lastUpdateHead`, `excludeSkills`, and `configVersion` values into a `claude` object. Defaults if missing: `excludeSkills: []`, `configVersion: 0`. `lastUpdateHead` is required and must already be present for any user reaching this migration.
3. Remove the original top-level `lastUpdateHead`, `excludeSkills`, and `configVersion` keys.
4. Preserve `repoMode`, `oracle`, and any `codex` object untouched.
5. Write the file back.

Example: `jq '. + {claude: {lastUpdateHead, excludeSkills: (.excludeSkills // []), configVersion: (.configVersion // 0)}} | del(.lastUpdateHead, .excludeSkills, .configVersion)' ~/.turbo/config.json` (then move the result into place).

## Version 4: Remove `repoMode`

**Condition:** `~/.turbo/config.json` has a top-level `repoMode` key.

**Skip if:** The key does not exist.

### Steps

Turbo no longer distinguishes clone, fork, and source installs. `~/.turbo/repo` tracks upstream through `origin` (Phase 1 Step 1 of UPDATE.md repoints a clone that still points at a fork), and skill improvements are proposed upstream as issues instead of pushed or PR'd from this clone.

1. Read `~/.turbo/config.json`.
2. Delete the top-level `repoMode` key, preserve every other key, and write the file back.
