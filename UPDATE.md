# Update Turbo (Pre-Split Installs)

This file is reached by an installed `update-turbo` skill from before the repo split into `claude/` and `codex/` editions. It leads into the one-time migration to the Turbo plugin. Touch no skill folder here: the migration decides what happens to every copied skill, the installed `update-turbo` included.

## Step 1: Check the Clone

Confirm the clone tracks upstream:

```bash
git -C ~/.turbo/repo config --get remote.origin.url
```

Upstream is `https://github.com/tobihagemann/turbo` or `git@github.com:tobihagemann/turbo`, with or without a trailing `.git`. Any other URL means the clone points at a fork left over from an earlier setup. Use `AskUserQuestion` to offer:

- **Clone upstream** — once the user has moved any local work they want to keep out of the old clone, move it to `~/.turbo/backup/<timestamp>/.turbo/repo`, with `<timestamp>` from `date +%Y%m%d-%H%M%S`, and clone upstream in its place. Then continue with Step 2 in this same run.

  ```bash
  git clone https://github.com/tobihagemann/turbo.git ~/.turbo/repo
  ```

- **Stop** — leave everything as it is.

## Step 2: Follow the Migration Guide

Fetch `origin` and read the Claude Code migration guide:

```bash
git -C ~/.turbo/repo fetch origin
git -C ~/.turbo/repo show origin/main:claude/UPDATE.md
```

Follow it from the start.
