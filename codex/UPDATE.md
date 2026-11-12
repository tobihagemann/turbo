# Migrate to the Turbo Plugin for Codex

Move a copy install, where setup and `$update-turbo` copied skills into `~/.agents/skills`, onto the Turbo plugin. Every step is safe to re-run. This guide writes to user-scope paths (`~/.agents/skills`, `~/.codex/`, `~/.turbo/`) on purpose, and Codex's sandbox protects the first two: run each command that writes under `~/.agents` or `~/.codex` with `sandbox_permissions="require_escalated"`, for the user to approve.

Before any step changes or removes a file or folder, copy it into one backup folder for this run, `~/.turbo/backup/<timestamp>/`, with `<timestamp>` taken once from `date +%Y%m%d-%H%M%S`. Inside it, mirror each item's path under the home folder: `~/.agents/skills/<name>` goes to `<backup>/.agents/skills/<name>`, `~/.turbo/repo` to `<backup>/.turbo/repo`. Back up only the file or folder a step names, never all of `~/.codex`, which holds the user's login and session data. State the backup path at the start and in the final report. Never delete what is not first in the backup.

Brace a shell variable that holds a rev in any `<rev>:<path>` argument as `${var}:<path>`: zsh reads a colon after a bare parameter name as a modifier and mangles or rejects the ref.

## Step 1: Check the Install

Read `~/.turbo/config.json`. When the file is missing or holds no `codex.lastUpdateHead`, report that no copy install is left to migrate and stop.

When the config also holds `claude.lastUpdateHead` or a top-level `lastUpdateHead`, and a symlink in `~/.claude/skills` resolves into `~/.agents/skills`, a Claude Code copy install still uses those folders. Tell the user to run `/update-turbo` in Claude Code first, which migrates that install, and stop.

Otherwise, confirm the clone tracks upstream:

```bash
git -C ~/.turbo/repo config --get remote.origin.url
```

Upstream is `https://github.com/tobihagemann/turbo` or `git@github.com:tobihagemann/turbo`, with or without a trailing `.git`. Any other URL means the clone points at a fork left over from an earlier setup. When it does, or when `~/.turbo/repo` is missing, use `request_user_input` to offer cloning upstream or stopping, and stop when the question cannot reach the user. To clone upstream, once the user has moved any local work they want to keep out of the old clone, move it into the backup and clone upstream in its place, then continue:

```bash
git clone https://github.com/tobihagemann/turbo.git ~/.turbo/repo
```

Then fetch:

```bash
git -C ~/.turbo/repo fetch origin
```

The baseline is the commit the copies were installed from. Take it from `codex.lastUpdateHead`. Confirm the clone holds it with `git -C ~/.turbo/repo cat-file -e "${base}^{commit}"`, branching on the exit code; when it does not, the baseline is unknown.

## Step 2: Install the Plugin

Ask the user to run these in a terminal outside this session, since Codex's sandbox protects `~/.codex`:

```bash
codex plugin marketplace add tobihagemann/turbo
codex plugin add turbo@turbo
```

Codex runs a plugin's hooks only once the user trusts them, so ask them as well to trust Turbo's `SessionStart` hook, which loads the Turbo rules into every session, when Codex asks at its next start (or under `/hooks`), and repeat that in the report. Use `request_user_input` to wait until they report the plugin installed, with stopping the migration as the other option, and stop when the question cannot reach the user: no copy has been touched yet.

## Step 3: Remove the Copied Skills

Export the upstream skill trees under a scratch directory outside the repo, creating each target folder first:

```bash
mkdir -p <tmp>/new <tmp>/old
git -C ~/.turbo/repo archive origin/main:codex/skills | tar -x -C <tmp>/new
git -C ~/.turbo/repo archive "${base}:codex/skills" | tar -x -C <tmp>/old
```

Each skill lands at `<tmp>/new/<name>` and `<tmp>/old/<name>`. Skip the second export when the baseline is unknown.

Every folder in `~/.agents/skills` whose name exists in either tree is a Turbo copy. A skill Turbo has since retired, such as `update-turbo`, exists only in the baseline tree and still counts. Leave alone a folder that a symlink in `~/.claude/skills` still resolves to (compare resolved absolute paths), since a Claude Code install uses it, and list it in the report: once Claude Code no longer links it, the user moves it out by hand. Classify each other copy against the tree versions with `git diff --no-index --quiet -- <tree version> <copy>`, exit 0 meaning identical. For a symlink, compare `<copy>/`: the trailing slash compares the target's contents. A difference limited to `.DS_Store` files or `__pycache__` folders counts as identical.

- **Unmodified** — identical to the skill in either tree. Move it to the backup.
- **Edited** — identical to neither. Write a one-line summary of what differs from the closest upstream version. Search the copy for references that stop working on the plugin: `~/.turbo/repo`; paths into another Turbo skill's folder under `~/.agents/skills/`; and the old name of a renamed skill, which becomes its new name. The renamed skills are `turboplan` → `plan`, `create-handoff` → `handoff`, `create-skill` → `write-skill`, `resolve-findings` → `implement-findings`, `understand-change` → `teach-change`, `contribute-turbo` → `contribute`, `create-pr` and `update-pr` → `pr`, `note-improvement` → `backlog`, `triage-improvements` → `triage-backlog`, `implement-improvements` → `implement-backlog`, `resolve-pr-comments` → `resolve-pr-feedback`, `recall-rationale` → `recall-session`.

When the baseline is unknown, a copy that matches neither tree may still be an untouched older version. Before classifying it Edited, compare it against every distinct version of that skill in the history of `origin/main` (`git -C ~/.turbo/repo log --format=%H origin/main -- codex/skills/<name>`), and count it Unmodified when one matches. Take the set of Turbo names from every skill folder that ever existed under `codex/skills/` on `origin/main`, so a retired skill such as `update-turbo` still counts.

When no copy comes out identical to anything, suspect the comparison paths before asking about any copy.

Ask about the edited copies with `request_user_input`, one question per copy and at most three questions per call. Each question names the copy, gives its summary, and lists every stale reference found with its replacement: the new skill name, or a rewrite by hand for the clone and the other skills' paths, since the plugin's install path changes with every update. For a copy of a renamed skill, name its new skill and say that keeping the copy no longer overrides it, since pipelines call the new name. Offer:

- **Keep as an override** — the copy keeps the skill's name and stops receiving Turbo's changes. A copy of a renamed skill keeps only its old name, which no pipeline calls. Rewrite nothing in it.
- **Move to the backup** — the plugin's version takes over.

Any answer other than **Move to the backup**, including a question that cannot reach the user, keeps the copy.

Whenever a symlinked copy moves to the backup, copy its resolved contents with `cp -RL <copy> <backup path>`, then remove only the link with `unlink <copy>`, leaving the target in place.

## Step 4: Remove Turbo's Rules from AGENTS.md

Skip this step when `~/.codex/AGENTS.md` does not exist.

Collect every version of the Turbo rules on `origin/main`: list the commits with `git -C ~/.turbo/repo log --format=%H origin/main -- codex/ADDITIONS.md`, and read each, skipping a commit where the file does not exist. Take the section names from every `##` heading in any version.

Back up `~/.codex/AGENTS.md`. A section runs from its heading to the next heading of the same or a higher level. For each section whose heading text matches one of those names, remove every non-blank line that matches a line from that section in any version. Compare lines after trimming surrounding whitespace, dropping a leading list marker (`-`, `*`, or `+`), and treating `*` and `_` emphasis markers as the same. Keep the remaining lines under their heading, and drop the heading when no non-blank line remains. Report the lines kept.

Setup could also merge these sections into a project's root `AGENTS.md`. Tell the user that such a copy needs the same cleanup by hand.

## Step 5: Retire the Clone

When the config holds neither `claude.lastUpdateHead` nor a top-level `lastUpdateHead`, nothing needs `~/.turbo/repo` any longer. Use `request_user_input` to offer moving it to the backup or keeping it, naming any copy kept in Step 3 that still references it, and keep it when the question cannot reach the user. When the config does hold one, keep the clone and say that the Claude Code copy install still uses it.

## Step 6: Clean Up the Turbo Config

Leave `~/.codex/config.toml` as it is: Turbo still relies on its settings.

Back up `~/.turbo/config.json`. Note the names in `codex.excludeSkills` for the report, since the plugin now provides those skills too. Delete `codex.excludeSkills` and `codex.configVersion`, then `codex.lastUpdateHead`. Keep every other key, `codex.sharedClaudeAutoMemory`, `oracle`, and the whole `claude` object included.

## Step 7: Report

Report the backup path, the copies moved, the copies kept as overrides with any stale references still in them, the folders left for Claude Code, the formerly excluded skills, the AGENTS.md lines kept, and the config keys changed. Tell the user to start a new Codex session, after which the plugin's skills and rules load. To update the plugin later, or to work on Turbo itself or a fork, point them at https://github.com/tobihagemann/turbo/blob/main/docs/customization.md.
