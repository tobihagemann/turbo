# Codex Migrations

Versioned breaking change migrations for the Codex edition of Turbo.

Migrations run in ascending order during the Codex `$update-turbo` flow. After all applicable migrations complete, `codex.configVersion` in `~/.turbo/config.json` is set to the highest migration version.

## Version 1: Initial Codex Edition

**Condition:** `~/.turbo/config.json` has no `codex` object, or has a `codex` object missing `configVersion`.

**Skip if:** `codex.configVersion` already exists.

### Steps

1. Initialize the `codex` object in `~/.turbo/config.json` if it does not exist.
2. Set `codex.configVersion` to `1`.
3. Set `codex.lastUpdateHead` to `git -C ~/.turbo/repo rev-parse HEAD` if it does not already exist.
4. Set `codex.excludeSkills` to `[]` if it does not already exist.
5. Preserve all top-level keys (`repoMode`, `oracle`) and any `claude` object untouched.

## Version 2: Remove `repoMode`

**Condition:** `~/.turbo/config.json` has a top-level `repoMode` key.

**Skip if:** The key does not exist.

### Steps

Turbo no longer distinguishes clone, fork, and source installs. `~/.turbo/repo` tracks upstream through `origin` (Phase 1 Step 1 of UPDATE.md repoints a clone that still points at a fork), and skill improvements are proposed upstream as issues instead of pushed or PR'd from this clone.

1. Read `~/.turbo/config.json`.
2. Delete the top-level `repoMode` key, preserve every other key, and write the file back.

## Version 3: Add Shared Claude Auto-Memory Preference

**Condition:** `codex.sharedClaudeAutoMemory` is missing or is not a boolean.

**Skip if:** `codex.sharedClaudeAutoMemory` is already `true` or `false`.

### Steps

1. Read `~/.turbo/config.json`.
2. Set `codex.sharedClaudeAutoMemory` to `false`, preserving every other key, and write the file back.

This preference is opt-in. Setup changes it to `true` only after the user chooses Shared Claude Code Auto Memory and the integration passes setup validation; `$self-improve` then trusts the saved value at runtime.
