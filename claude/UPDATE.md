# Migrate to the Turbo Plugin

Move a copy install, where setup and `/update-turbo` copied skills into `~/.claude/skills`, onto the Turbo plugin. Every step is safe to re-run.

Before any step changes or removes a file or folder, copy it into one backup folder for this run, `~/.turbo/backup/<timestamp>/`, with `<timestamp>` taken once from `date +%Y%m%d-%H%M%S`. Inside it, mirror each item's path under the home folder: `~/.claude/skills/<name>` goes to `<backup>/.claude/skills/<name>`, `~/.turbo/repo` to `<backup>/.turbo/repo`. Back up only the file or folder a step names, never all of `~/.claude`, which holds the user's login and session data. State the backup path at the start and in the final report. Never delete what is not first in the backup.

Brace a shell variable that holds a rev in any `<rev>:<path>` argument as `${var}:<path>`: zsh reads a colon after a bare parameter name as a modifier and mangles or rejects the ref.

## Step 1: Check the Install

Read `~/.turbo/config.json`. When the file is missing, or holds neither `claude.lastUpdateHead` nor a top-level `lastUpdateHead`, report that no copy install is left to migrate and stop.

Otherwise, confirm the clone tracks upstream:

```bash
git -C ~/.turbo/repo config --get remote.origin.url
```

Upstream is `https://github.com/tobihagemann/turbo` or `git@github.com:tobihagemann/turbo`, with or without a trailing `.git`. Any other URL means the clone points at a fork left over from an earlier setup. When it does, or when `~/.turbo/repo` is missing, use `AskUserQuestion` to offer:

- **Clone upstream** — once the user has moved any local work they want to keep out of the old clone, move it into the backup and clone upstream in its place, then continue:

  ```bash
  git clone https://github.com/tobihagemann/turbo.git ~/.turbo/repo
  ```

- **Stop** — leave everything as it is.

Then fetch:

```bash
git -C ~/.turbo/repo fetch origin
```

The baseline is the commit the copies were installed from. Take it from `claude.lastUpdateHead`, falling back to the top-level `lastUpdateHead`. Confirm the clone holds it with `git -C ~/.turbo/repo cat-file -e "${base}^{commit}"`, branching on the exit code; when it does not, the baseline is unknown. A baseline from before the edition split keeps its skills under `skills/` rather than `claude/skills/`: check with `git -C ~/.turbo/repo cat-file -e "${base}:claude/skills"`, branching on the exit code.

## Step 2: Install the Plugin

Ask the user to run these in Claude Code, since writes under `~/.claude/plugins` are theirs to make:

```text
/plugin marketplace add tobihagemann/turbo
/plugin install turbo@turbo
```

Then have them switch on auto-update for the `turbo` marketplace under `/plugin` → Marketplaces; third-party marketplaces do not update on their own. Use `AskUserQuestion` to wait until they report the plugin installed, with stopping the migration as the other option.

## Step 3: Remove the Copied Skills

Export the upstream skill trees under your scratchpad directory, creating each target folder first:

```bash
mkdir -p <tmp>/new <tmp>/old
git -C ~/.turbo/repo archive origin/main:claude/skills | tar -x -C <tmp>/new
git -C ~/.turbo/repo archive "${base}:<baseline skills folder>" | tar -x -C <tmp>/old
```

Each skill lands at `<tmp>/new/<name>` and `<tmp>/old/<name>`. Skip the second export when the baseline is unknown.

Every folder in `~/.claude/skills` whose name exists in either tree is a Turbo copy. A skill Turbo has since retired, such as `update-turbo`, exists only in the baseline tree and still counts. Classify each copy against the tree versions with `git diff --no-index --quiet -- <tree version> <copy>`, exit 0 meaning identical. For a symlink, as an install through `npx skills` left one, compare `<copy>/`: the trailing slash compares the target's contents. A difference limited to `.DS_Store` files or `__pycache__` folders counts as identical.

- **Unmodified** — identical to the skill in either tree. Move it to the backup.
- **Edited** — identical to neither. Write a one-line summary of what differs from the closest upstream version. Search the copy for references that stop working on the plugin: `mcp__context-level__read`, which becomes `mcp__turbo__context-level`; `~/.turbo/repo`; and paths into another Turbo skill's folder under `~/.claude/skills/`.

When the baseline is unknown, a copy that matches neither tree may still be an untouched older version. Before classifying it Edited, compare it against every distinct version of that skill in the history of `origin/main` (`git -C ~/.turbo/repo log --format=%H origin/main -- claude/skills/<name> skills/<name>`), and count it Unmodified when one matches. Take the set of Turbo names from every skill folder that ever existed under `claude/skills/` or `skills/` on `origin/main`, so a retired skill such as `update-turbo` still counts.

When no copy comes out identical to anything, suspect the comparison paths before asking about any copy.

Ask about the edited copies with `AskUserQuestion`, one question per copy and at most four questions per call. Each question names the copy, gives its summary, and lists every stale reference found with its replacement: the new tool name, or a rewrite by hand for the clone and the other skills' paths, since the plugin's install path changes with every update. For the `context-level` copy, add that moving it also removes the separate mod it carried, which the plugin replaces. Offer:

- **Keep as an override** — the copy keeps the skill's name, in pipelines too, and stops receiving Turbo's changes. Rewrite nothing in it.
- **Move to the backup** — the plugin's version takes over.

Any answer other than **Move to the backup** keeps the copy.

Whenever a symlinked copy moves to the backup, copy its resolved contents with `cp -RL <copy> <backup path>`, then remove only the link with `unlink <copy>`, leaving the target in place: a Codex install may own it.

## Step 4: Remove Turbo's Rules from CLAUDE.md

Skip this step when `~/.claude/CLAUDE.md` does not exist.

Collect every version of the Turbo rules on `origin/main`: list the commits with `git -C ~/.turbo/repo log --format=%H origin/main -- claude/ADDITIONS.md CLAUDE-ADDITIONS.md`, and read each at whichever of the two paths exists there, skipping a commit where neither does. Take the section names from every `##` heading in any version.

Back up `~/.claude/CLAUDE.md`. A section runs from its `#` heading to the next `#` heading. For each section whose heading matches one of those names, remove every non-blank line that matches a line from that section in any version. Compare lines after trimming surrounding whitespace, dropping a leading list marker (`-`, `*`, or `+`), and treating `*` and `_` emphasis markers as the same. Keep the remaining lines under their heading, and drop the heading when no non-blank line remains. Report the lines kept.

## Step 5: Clean Up Settings

Back up `~/.claude/settings.json` when it exists, then:

1. Remove `statusLine` only when its command is one Turbo installed: `jq -r '.context_window.remaining_percentage | if . == null then empty else "\(floor)% context left" end'`, the earlier `jq -r '"\(.context_window.remaining_percentage | floor)% context left"'`, or one running `context-statusline.sh`.
2. Remove every `hooks.PostToolUse` hook whose command runs `context-warn.sh`, then drop a matcher group left without hooks, a `PostToolUse` array left empty, and a `hooks` object left empty.
3. Set `env.CLAUDE_CODE_ENABLE_TODO_TOOLS` to the string `"1"` when it is not already. Create the file with just that key when it does not exist.

Preserve every other key. Move `~/.claude/hooks/turbo/` to the backup when it exists.

## Step 6: Retire the Clone

When the config holds no `codex.lastUpdateHead`, nothing needs `~/.turbo/repo` any longer. Use `AskUserQuestion` to offer moving it to the backup or keeping it, naming any copy kept in Step 3 that still references it. When the config does hold one, keep the clone and say that the Codex copy install still uses it.

## Step 7: Clean Up the Turbo Config

Back up `~/.turbo/config.json`. Note the names in `claude.excludeSkills`, or in a top-level `excludeSkills` on an install from before the edition split, for the report, since the plugin now provides those skills too. Delete `claude.excludeSkills`, `claude.lastUpdateHead`, and `claude.configVersion`, then the `claude` object when it is left empty, then the top-level `lastUpdateHead`. Keep every other key: `oracle`, the whole `codex` object, and keys an older install left at the top level (`excludeSkills`, `configVersion`, `repoMode`).

## Step 8: Report

Report the backup path, the copies moved, the copies kept as overrides with any stale references still in them, the formerly excluded skills, the CLAUDE.md lines kept, and the settings and config keys changed. Tell the user to restart Claude Code, after which the plugin's skills, rules, and context reading load. To work on Turbo itself or a fork, point them at https://github.com/tobihagemann/turbo/blob/main/docs/customization.md.
