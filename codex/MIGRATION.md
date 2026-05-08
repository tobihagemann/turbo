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
