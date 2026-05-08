# Update Turbo (Edition Migration)

The Turbo repo has been split into per-edition trees. Skills now live under `claude/skills/` and `codex/skills/`. The legacy root `skills/` directory has been removed.

If you reached this file via an installed Claude Code `update-turbo` skill that points at `~/.turbo/repo/UPDATE.md`, your installed skill is the legacy pre-split version. Migrate it before resuming the normal update flow. (The Codex edition was added after the split, so Codex installs go straight to [`codex/UPDATE.md`](codex/UPDATE.md) and never reach this file.)

## Migration Steps (Claude Code Only)

1. Reinstall the path-aware skills from the canonical Claude edition tree:

   ```bash
   for skill in update-turbo contribute-turbo self-improve; do
     rm -rf ~/.claude/skills/$skill
     cp -R ~/.turbo/repo/claude/skills/$skill ~/.claude/skills/$skill
   done
   ```

2. Tell the user the migration is complete and they should re-run `/update-turbo` to perform the regular update. The newly-installed skill will read [`claude/UPDATE.md`](claude/UPDATE.md) instead of this file.
