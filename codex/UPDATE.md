# Update Turbo for Codex

Update installed Turbo Codex skills from the local repo at `~/.turbo/repo/` with a changelog and conflict handling.

Every `<rev>:<path>` argument below is a hazard when a shell variable holds the rev: brace it as `${var}:<path>`. In zsh, a colon directly after a parameter name introduces a modifier, and every path in this document begins with `c`, which zsh consumes as the `:c` modifier. The ref silently loses that character and fails to resolve. Double quotes do not prevent this; the braces do.

## Phase 1: Analysis

### Step 1: Fetch

Confirm the clone tracks upstream:

```bash
git -C ~/.turbo/repo remote get-url origin
```

If it prints anything other than `https://github.com/tobihagemann/turbo.git`, the clone points at a fork left over from an earlier setup. Stop, and tell the user to move any local work into a checkout outside `~/.turbo/repo` and replace the clone before re-running:

```bash
git clone https://github.com/tobihagemann/turbo.git ~/.turbo/repo
```

Installed skills live outside this clone, so replacing it loses no customizations.

Then fetch:

```bash
git -C ~/.turbo/repo fetch origin
```

### Step 2: Run Migrations

**Current version: 2**

Read `codex.configVersion` from `~/.turbo/config.json` (default: `0` if missing). Migrations run before any head comparison so users on a current commit still pick up schema migrations.

If `codex.configVersion` equals the current version, skip to Step 3.

Otherwise, read `MIGRATION.md` from `origin`:

```bash
git -C ~/.turbo/repo show origin/main:codex/MIGRATION.md
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
git -C ~/.turbo/repo rev-parse origin/main
```

If they match, report that Turbo for Codex is already up to date and stop.

### Step 4: Build Changelog

The changelog is for user-facing display only. Destructive behavior in Phase 3 is driven by Phase 2's audit matrix, not by these categories.

Use local git commands to detect changes since `codex.lastUpdateHead`. The angle-bracket `<lastUpdateHead>` in the snippets below is the shell placeholder for that value.

```bash
# Changed skill files
git -C ~/.turbo/repo diff --name-status <lastUpdateHead>..origin/main -- codex/skills/

# Commit history for context
git -C ~/.turbo/repo log --oneline <lastUpdateHead>..origin/main -- codex/skills/
```

From the `--name-status` output, each entry has a status (`A` added, `D` deleted, `M` modified, `R` renamed with old path). Group by skill name (extract from `codex/skills/<name>/...`).

For each modified or renamed skill, read both versions of the SKILL.md:

```bash
# Old version
git -C ~/.turbo/repo show <lastUpdateHead>:codex/skills/<name>/SKILL.md

# New version
git -C ~/.turbo/repo show origin/main:codex/skills/<name>/SKILL.md
```

Read both versions and write a concise, plain-language summary of what changed. Focus on what the change means for the user: new capabilities, changed behavior, renamed commands, removed features. Flag anything that could be a breaking change (renamed skills that other skills reference, removed steps, changed interfaces, peer-review behavior changes).

For added skills, read their new SKILL.md and summarize what they do.

Also check for changes to `codex/ADDITIONS.md`:

```bash
git -C ~/.turbo/repo diff --name-status <lastUpdateHead>..origin/main -- codex/ADDITIONS.md
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

### Step 1: Build the Audit Matrix

Detection runs over **every** skill in the union of installed, old upstream, and new upstream — independent of the changelog. Phase 3's destructive operations gate strictly on the matrix, so any deviation between an installed skill and its old upstream baseline surfaces here, not in Phase 3.

Materialize the old upstream skill tree once:

```bash
tmp=$(mktemp -d)
git -C ~/.turbo/repo archive <lastUpdateHead> -- codex/skills/ 2>/dev/null | tar -x -C "$tmp"
mkdir -p "$tmp/codex/skills"
```

The trailing `mkdir -p` handles the case where `<lastUpdateHead>` predates the `codex/skills/` path: the archive emits no entries and the directory wouldn't otherwise exist, which would cause the diff step below to error on a missing path. With an empty old-upstream tree, every installed skill routes into the **Collision** category (old absent, new present, installed present) and the user is asked once per skill whether to overwrite with the fresh upstream.

Enumerate the union of skill names from three sources, deduplicated:

```bash
# Old upstream
git -C ~/.turbo/repo ls-tree -d --name-only <lastUpdateHead> -- codex/skills/ | xargs -n1 basename
# New upstream
git -C ~/.turbo/repo ls-tree -d --name-only origin/main -- codex/skills/ | xargs -n1 basename
# Installed
ls -1 ~/.agents/skills/ 2>/dev/null
```

**Detect skill renames** before flag computation. A skill rename is signaled when `git diff --name-status -M` reports an `R` status on a `SKILL.md` between two skill directories:

```bash
git -C ~/.turbo/repo diff --name-status -M <lastUpdateHead>..origin/main -- codex/skills/ |
  awk -F'\t' '/^R/ && $2 ~ "^codex/skills/[^/]+/SKILL\\.md$" && $3 ~ "^codex/skills/[^/]+/SKILL\\.md$" {
    old=$2; new=$3
    sub("codex/skills/", "", old); sub("/SKILL.md", "", old)
    sub("codex/skills/", "", new); sub("/SKILL.md", "", new)
    print old "\t" new
  }'
```

Build a map of `(old → new)` pairs. For names appearing as either side of a rename, categorize as **Renamed** and skip the standard 4-flag matrix below for both old and new names. A Renamed entry has two sub-cases:

| Sub-case | Detection | Default |
|---|---|---|
| **Renamed, clean** | `git diff --no-index --quiet -- "$tmp/codex/skills/<old-name>" ~/.agents/skills/<old-name>` exits 0 | Auto-migrate in Phase 3 |
| **Renamed, customized** | same diff exits 1 | Ask user (Migrate / Skip / Exclude) |

If git's rename detection threshold isn't met (e.g., the rename also rewrote `SKILL.md` substantially), the rename falls through to the standard matrix as Removed-upstream + New-upstream — data is still safe (Removed-upstream prompts on customized installs); the UX just doesn't recognize the rename.

For each remaining `<name>` (i.e., names not paired in the rename map), compute four flags. Brace any rev variable in the `cat-file` probes below: their errors are suppressed, so an unbraced rev makes `old_exists` come back false for every skill and routes each one into **Collision**.

| Flag | How |
|---|---|
| `old_exists` | `git -C ~/.turbo/repo cat-file -e <lastUpdateHead>:codex/skills/<name>/SKILL.md 2>/dev/null` (exit 0 means exists) |
| `new_exists` | `git -C ~/.turbo/repo cat-file -e origin/main:codex/skills/<name>/SKILL.md 2>/dev/null` (exit 0 means exists) |
| `installed_exists` | `test -d ~/.agents/skills/<name>` |
| `clean` | only when `old_exists` and `installed_exists` are both true: `git diff --no-index --quiet -- "$tmp/codex/skills/<name>" ~/.agents/skills/<name>` (exit 0 → clean, exit 1 → customized) |

Use `git diff --no-index` rather than POSIX `diff -rq`. Git diff understands file modes (regular vs executable), symlinks, and gitlinks; POSIX diff misses mode and symlink target changes.

Combine the flags into one of these categories:

| `old_exists` | `new_exists` | `installed_exists` | `clean` | Category |
|---|---|---|---|---|
| ✓ | ✓ | ✓ | ✓ | **Modified, clean** |
| ✓ | ✓ | ✓ | ✗ | **Modified, customized** |
| ✓ | ✗ | ✓ | ✓ | **Removed upstream, clean** |
| ✓ | ✗ | ✓ | ✗ | **Removed upstream, customized** |
| ✗ | ✓ | ✓ | — | **Collision** |
| ✗ | ✓ | ✗ | — | **New upstream** |
| ✗ | ✗ | ✓ | — | **User-local** |
| ✓ | ✓ | ✗ | — | **User-uninstalled** |
| ✓ | ✗ | ✗ | — | **Already gone** |

When `old_exists` and `new_exists` are both true and the upstream content is identical between `<lastUpdateHead>` and `origin/main` for that skill, mark the entry as **No-op** regardless of the `clean` flag — the skill didn't actually change upstream.

Before continuing, confirm the probes actually ran: every name from the old-upstream enumeration must have `old_exists` true, and every name from the new-upstream enumeration must have `new_exists` true. Only installed-only names may have both false. A violation means the flag computation is broken, not that the skills are missing. Stop here, report which of the two causes below applies, and leave `codex.lastUpdateHead` unchanged so a corrected run can retry.

First, a mangled `<rev>:<path>` ref, per the bracing note at the top. Second, a loop that never iterated: zsh does not word-split unquoted parameter expansions at all, so `for n in $NAMES` runs once with the entire list as a single value and every probe fails against that one bogus name. Iterate with `for n in ${(f)NAMES}` to split on newlines, or capture the enumeration to a file and read it with `while IFS= read -r n; do ... done < "$file"`.

### Step 2: Resolve

For each category that requires user input, use `request_user_input`. Auto-handled categories (no prompt): **Modified, clean**, **Removed upstream, clean**, **Renamed, clean**, **New upstream**, **User-local**, **User-uninstalled**, **Already gone**, **No-op**.

**Modified, customized**

```
$<skill-name> has upstream changes, but you've customized your local copy.

What changed upstream:
- [summary from changelog]

Options:
1. Merge — apply upstream changes while preserving your customizations
2. Overwrite — replace with upstream version (customizations will be lost)
3. Skip — keep your version unchanged
```

If the user picks **Skip**, follow up with a second `request_user_input` asking whether to also exclude the skill from future updates (Yes / No). This keeps each gate within the 3-option cap.

**Removed upstream, customized**

```
$<skill-name> was removed upstream, but you've customized your local copy.

Options:
1. Remove — delete the customized installed copy
2. Keep — leave it installed; will surface again on the next update
3. Exclude — leave it installed and exclude from future updates
```

**Collision** (a locally installed skill shares a name with a NEW upstream skill)

```
$<skill-name> is locally installed but is also a NEW upstream skill of the same name. They are different things at the same path.

Options:
1. Overwrite — replace your local version with the upstream skill
2. Keep — keep your local version, skip installing the upstream one
3. Exclude — keep your local and exclude this name from future updates
```

**Renamed, customized**

```
$<old-name> was renamed upstream to $<new-name>, but you've customized your local copy.

What changed in the upstream rename:
- [summary from changelog]

Options:
1. Migrate — rename your installed copy to $<new-name>, then merge your customizations into the new upstream version
2. Skip — leave $<old-name> installed at the old name, don't install $<new-name>
3. Exclude — same as Skip, plus exclude both names from future updates
```

### Step 3: Save Customized Content

Before proceeding to Phase 3, snapshot the entire installed directory of every skill where the user chose **Merge** (Modified-customized) or **Migrate** (Renamed-customized). The saved tree must include any customized files under `scripts/`, `references/`, `assets/`, or net-new paths the user added.

```bash
# For Modified-customized + Merge:
saved="$tmp/saved/<name>"
mkdir -p "$(dirname "$saved")"
cp -R ~/.agents/skills/<name>/ "$saved"

# For Renamed-customized + Migrate (key the snapshot under the NEW name so Phase 3 Step 3 finds it next to the fresh install):
saved="$tmp/saved/<new-name>"
mkdir -p "$(dirname "$saved")"
cp -R ~/.agents/skills/<old-name>/ "$saved"
```

## Phase 3: Execution

### Step 1: Pull

Pull the latest changes into the local repo:

```bash
git -C ~/.turbo/repo pull origin main
```

### Step 2: Apply Matrix Actions

Build the exclusion set from `codex.excludeSkills` plus any skill where the user chose Exclude in Phase 2.

For each skill in the audit matrix that is not excluded, execute the action determined by its category:

| Category | Action |
|---|---|
| Modified, clean | `rm -rf ~/.agents/skills/<name>` && `cp -R ~/.turbo/repo/codex/skills/<name> ~/.agents/skills/<name>` |
| Modified, customized + Merge | `rm -rf ~/.agents/skills/<name>` && `cp -R ~/.turbo/repo/codex/skills/<name> ~/.agents/skills/<name>` (Step 3 then re-applies the saved customizations) |
| Modified, customized + Overwrite | same as Modified, clean |
| Modified, customized + Skip | no action |
| Removed upstream, clean | `rm -rf ~/.agents/skills/<name>`, warn the user |
| Removed upstream, customized + Remove | `rm -rf ~/.agents/skills/<name>` |
| Removed upstream, customized + Keep | no action |
| Collision + Overwrite | `rm -rf ~/.agents/skills/<name>` && `cp -R ~/.turbo/repo/codex/skills/<name> ~/.agents/skills/<name>` |
| Collision + Keep | no action |
| Renamed, clean | `rm -rf ~/.agents/skills/<old-name>` && `cp -R ~/.turbo/repo/codex/skills/<new-name> ~/.agents/skills/<new-name>` |
| Renamed, customized + Migrate | `rm -rf ~/.agents/skills/<old-name>` && `cp -R ~/.turbo/repo/codex/skills/<new-name> ~/.agents/skills/<new-name>` (Step 3 then re-applies the saved customizations to the new path) |
| Renamed, customized + Skip | no action |
| New upstream | `cp -R ~/.turbo/repo/codex/skills/<name> ~/.agents/skills/<name>` |
| User-local, User-uninstalled, Already gone, No-op | no action |

A denied `rm -rf` exits non-zero and prints `Permission denied`, or `Operation not permitted` under a sandbox; `-f` suppresses only its nonexistent-path error. Chain each pair as `rm -rf <dest> && cp -R <src> <dest>` so a denied removal cannot be followed by a copy. An unchained `cp` after a failed removal copies into the surviving destination, leaving the old content at `<dest>` and the new content one level down at `<dest>/<name>`. Before retrying a failed apply, inspect the install for nested `<name>/<name>` directories and for skills whose content is still the old version.

### Step 3: Merge Customized Skills

For each skill where the user chose **Merge** (Modified-customized) or **Migrate** (Renamed-customized):

1. After Phase 3 Step 2's rm + cp, the install holds the fresh upstream version. Identify the three relevant trees per case:

   | User choice | Install path | Saved tree | Old upstream baseline |
   |---|---|---|---|
   | Merge (Modified) | `~/.agents/skills/<name>/` | `$tmp/saved/<name>/` | `$tmp/codex/skills/<name>/` |
   | Migrate (Renamed) | `~/.agents/skills/<new-name>/` | `$tmp/saved/<new-name>/` | `$tmp/codex/skills/<old-name>/` |

2. Walk the saved customized tree. For each file path relative to the skill root:
   - **Present in saved, absent in fresh upstream** — net-new user file. Copy back to the install verbatim.
   - **Present in saved, present in fresh upstream, byte-identical to old upstream baseline** — file is uncustomized at this path. Leave the fresh upstream version in place.
   - **Present in saved, present in fresh upstream, differs from old upstream baseline** — customized file. Use the saved customized version, old upstream baseline at that path, and fresh upstream version now installed to produce a merged result that preserves the user's customizations while incorporating upstream changes. Write the merged result back to the install path.
   - **Absent in saved, present in fresh upstream** — user deleted this file. Use `request_user_input` to decide: restore from upstream or honor the deletion.

### Step 4: Sync AGENTS Additions

If `codex/ADDITIONS.md` changed since `codex.lastUpdateHead` (detected in Phase 1 Step 4):

1. Read `codex/ADDITIONS.md` from `~/.turbo/repo/`.
2. Read `~/.codex/AGENTS.md`. This is the only sync target: `$update-turbo` maintains the user-global copy, never a project's root `AGENTS.md`. Project-local additions are a one-time setup choice the user maintains themselves.
3. For each `##` section in `codex/ADDITIONS.md`:
   - If no matching same-named section exists in the target → **new**
   - If a matching section exists but content differs → **changed**
   - If content matches → skip
4. If there are new or changed sections, ask the user:

```
AGENTS additions updated:

New:
- "Section Name" — brief description

Changed:
- "Section Name" — what changed

Apply to ~/.codex/AGENTS.md?
```

5. If approved, update `~/.codex/AGENTS.md`:
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
