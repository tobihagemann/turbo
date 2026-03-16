# Migrations

Versioned breaking change migrations for Turbo. Each migration runs once during `/update-turbo` when the user's `configVersion` in `~/.turbo/config.json` is below the migration's version number.

Migrations are executed in ascending order. After all applicable migrations complete, `configVersion` is set to the highest migration version.

## Version 1: Migrate from `npx skills`

**Condition:** `~/.claude/skills/finalize` is a symlink pointing into `~/.agents/skills/`.

**Skip if:** The condition is not met (user never used `npx skills`).

### Steps

1. Ask the user: consume only (clone), contribute (fork), or maintain (source)?
2. Clone the repo to `~/.turbo/repo/` (see SETUP.md Step 1 for the exact commands per mode)
3. For each Turbo skill (where `~/.claude/skills/<name>` is a symlink into `~/.agents/skills/` and has a matching directory in `~/.turbo/repo/skills/`):
   - Read the installed file at `~/.claude/skills/<name>/SKILL.md` (resolve symlink first)
   - Read the upstream version at `~/.turbo/repo/skills/<name>/SKILL.md`
   - Note whether the user has customized this skill (contents differ)
4. Remove old installations: `npx skills remove -g -y <name>` for each Turbo skill
5. Copy skills from the repo. For customized skills, copy the user's version instead
6. Initialize `~/.turbo/config.json` with `repoMode`, `excludeSkills: []`, and `lastUpdateHead` set to `git -C ~/.turbo/repo rev-parse HEAD`
7. Report migration complete
