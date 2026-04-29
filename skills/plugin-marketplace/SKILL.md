| name | plugin-marketplace |
| description | Install, list, update, and uninstall Claude Code skill packs from GitHub repos. Use when the user says "plugin marketplace install", "install plugin", "install skill pack", "/plugin-marketplace install owner/repo", "uninstall plugin owner/repo", "list plugins", or "update plugin owner/repo". |

# Plugin Marketplace

Manage third-party Claude Code skill packs from GitHub. Packs are cloned to `~/.turbo/plugins/<owner>-<repo>/` and their skills are symlinked (or copied) into `~/.claude/skills/`.

Registry lives at `~/.turbo/plugins/registry.json`.

## Argument Parsing

Parse the user's message for a subcommand and optional `owner/repo` argument:

- `install <owner/repo>` — install a skill pack
- `uninstall <owner/repo>` — remove a skill pack
- `update [owner/repo]` — update one pack or all
- `list` — show installed packs

If no subcommand is recognizable, show usage and stop.

## Task Tracking

Create tasks for the chosen subcommand before acting:

- install: "Validate repo", "Clone pack", "Copy skills", "Register pack"
- uninstall: "Validate installed", "Remove skills", "Deregister pack"
- update: "Fetch remote", "Pull changes", "Sync skills"
- list: "Read registry"

---

## Subcommand: install

### Step 1 — Validate

Confirm `owner/repo` was provided. If not, ask the user for it and stop until answered.

Check the registry: if already installed, tell the user and stop.

### Step 2 — Clone

```shell
PACK_DIR=~/.turbo/plugins/<owner>-<repo>
git clone https://github.com/<owner>/<repo>.git "$PACK_DIR"
```

If clone fails, report the error and stop.

### Step 3 — Discover Skills

Check whether the repo has a `skills/` directory at its root:

```shell
ls "$PACK_DIR/skills/"
```

If no `skills/` directory exists, tell the user the repo does not follow the skill pack convention and stop. Do not install.

### Step 4 — Copy Skills

```shell
mkdir -p ~/.claude/skills
for skill in "$PACK_DIR"/skills/*/; do
  name=$(basename "$skill")
  dest=~/.claude/skills/"$name"
  if [ -d "$dest" ]; then
    echo "SKIP (already exists): $name"
  else
    cp -r "$skill" "$dest"
    echo "INSTALLED: $name"
  fi
done
```

Report every installed and skipped skill to the user.

### Step 5 — Register

Read `~/.turbo/plugins/registry.json` (create `{}` if missing). Add an entry:

```json
{
  "<owner>/<repo>": {
    "packDir": "~/.turbo/plugins/<owner>-<repo>",
    "installedAt": "<ISO timestamp>",
    "head": "<git HEAD SHA>",
    "skills": ["<list of installed skill names>"]
  }
}
```

Write the updated registry back.

Tell the user installation is complete and list installed skills.

---

## Subcommand: uninstall

### Step 1 — Validate

Confirm `owner/repo` was provided and exists in the registry. If not found, tell the user and stop.

### Step 2 — Remove Skills

Read the `skills` array from the registry entry. For each skill:

```shell
rm -rf ~/.claude/skills/<skill-name>
```

Ask the user to confirm before deleting if any skill name appears in more than one registered pack (conflict — removing it would break the other pack).

### Step 3 — Remove Pack Directory

```shell
rm -rf ~/.turbo/plugins/<owner>-<repo>
```

### Step 4 — Deregister

Remove the `<owner>/<repo>` key from `~/.turbo/plugins/registry.json` and write it back.

Tell the user uninstall is complete.

---

## Subcommand: update

### Step 1 — Determine Scope

If `owner/repo` was provided, update only that pack. Otherwise update all packs in the registry.

### Step 2 — Pull Changes

For each pack being updated:

```shell
git -C ~/.turbo/plugins/<owner>-<repo> pull --ff-only
```

If `--ff-only` fails (diverged), warn the user and skip that pack — do not force-merge.

Record the new HEAD SHA.

### Step 3 — Sync Skills

Re-run the copy step from `install` Step 4 for any skills in the updated pack. Overwrite existing installed skill directories.

Update the `head` and any `skills` changes in the registry entry.

Report which skills were updated.

---

## Subcommand: list

Read `~/.turbo/plugins/registry.json`. If empty or missing, tell the user no packs are installed.

Otherwise display a table:

```
Pack                    Skills  Head      Installed
tobihagemann/turbo      42      abc1234   2025-01-15
yourname/my-skills       3      def5678   2025-03-02
```

---

## Error Handling

- Missing `gh` or `git`: tell the user to install the missing tool and stop.
- Network failure on clone/pull: report the error verbatim, suggest checking the repo URL and network, stop.
- Registry parse error: warn the user the registry may be corrupted, show the raw content, stop before writing.
