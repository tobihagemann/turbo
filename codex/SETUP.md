# Codex Setup Guide

Walk the user through setting up the Codex edition of Turbo step by step. Ask before changing user-level configuration.

## Task Tracking

Track these setup phases with the Codex plan tool:

1. Install Turbo Codex skills
2. Add `.turbo` to global gitignore
3. Install prerequisites
4. Enable structured user input in Default mode
5. Raise concurrent subagent limit
6. Add AGENTS.md additions
7. Oracle setup
8. Quick onboarding

## Step 1: Install Turbo Codex Skills

### Clone the Repo

```bash
git clone https://github.com/tobihagemann/turbo.git ~/.turbo/repo
```

Clone the upstream URL: `$update-turbo` pulls from `origin`. Keep any fork or development checkout of Turbo outside `~/.turbo/repo`.

### Excluded Skills

Read `~/.turbo/config.json` and check for a `codex.excludeSkills` array. If it exists, those skills should be excluded from installation. Example config:

```json
{
  "codex": {
    "excludeSkills": ["oracle"]
  }
}
```

### Install Skills

Install Codex skills into `~/.agents/skills`, skipping any in `codex.excludeSkills`:

```bash
mkdir -p ~/.agents/skills
exclude=$(jq -r '.codex.excludeSkills // [] | .[]' ~/.turbo/config.json 2>/dev/null)
for skill in ~/.turbo/repo/codex/skills/*; do
  [ -d "$skill" ] || continue
  name=$(basename "$skill")
  echo "$exclude" | grep -qxF "$name" && continue
  cp -R "$skill" ~/.agents/skills/
done
```

Many skills depend on each other, so installing only a subset can leave gaps in pipelines like `$finalize`.

Verify installation by confirming the skill directories exist in `~/.agents/skills/`.

### Initialize Config

Create or update `~/.turbo/config.json`:

```bash
mkdir -p ~/.turbo
```

Set:

- `codex.excludeSkills` to any excluded Codex skill names
- `codex.lastUpdateHead` to the current HEAD: `git -C ~/.turbo/repo rev-parse HEAD`
- `codex.configVersion` to the highest version number in `~/.turbo/repo/codex/MIGRATION.md`

Preserve any existing config values (`oracle`, `claude` if the Claude edition is also installed).

Example shape:

```json
{
  "codex": {
    "excludeSkills": [],
    "lastUpdateHead": "<HEAD>",
    "configVersion": 2
  }
}
```

## Step 2: Add `.turbo` to Global Gitignore

Some skills store project-level files in a `.turbo/` directory (specs, plans, improvements). Add it to the user's global gitignore to keep project repos clean:

First, check if the user has `core.excludesfile` configured:

```bash
git config --global core.excludesfile
```

- If set, append `.turbo/` to that file if it is not already present.
- If not set, use Git's standard XDG path:

```bash
mkdir -p ~/.config/git
grep -qxF '.turbo/' ~/.config/git/ignore 2>/dev/null || echo '.turbo/' >> ~/.config/git/ignore
```

Do not set `core.excludesfile` — the XDG path works automatically without it.

## Step 3: Install Prerequisites

### GitHub CLI (Required)

Many skills use `gh` for PR and issue operations, review comments, and repo queries.

Install it from [cli.github.com](https://cli.github.com/), then authenticate:

```bash
gh auth login
```

Verify: `gh auth status` should show the user is logged in.

### Claude Code CLI (Required for `$finalize`)

The `$peer-review` skill (used during `$finalize`) delegates to Claude for AI code review.

```bash
npm install -g @anthropic-ai/claude-code
```

Authenticate Claude Code per its instructions, then verify: `claude --help` should show usage info. `$peer-review` calls Claude in non-interactive print mode through `$claude-print`.

Smoke-test print mode in the current project: `claude -p "hello" < /dev/null` should return a response. If it fails because permissions are required, help the user configure Claude Code for read-only review in this trusted workspace. Do not enable broad write or bypass permissions for peer review — Claude only needs to read the repository and inspect diffs unless a specialized consultation explicitly asks for more.

## Step 4: Enable Structured User Input in Default Mode

Codex's `request_user_input` tool — used by Turbo skills for structured choice gates — is only available in Plan mode by default. Default ("code") mode requires opting into the `default_mode_request_user_input` feature flag.

Without it, Turbo skills that ask a structured question in Default mode either error with `request_user_input is unavailable in Default mode` or silently fall back to free-form chat, losing the option-list UI.

Ask the user whether to enable it. If yes, add `default_mode_request_user_input = true` under `[features]` in `~/.codex/config.toml` (create the section if it doesn't exist; preserve existing keys).

The flag is experimental upstream and off by default. Revisit this step if Codex stabilizes, renames, or default-enables it.

## Step 5: Raise Concurrent Subagent Limit

Codex caps concurrent subagents at `agents.max_threads`, which defaults to 6. Several Turbo skills fan out into more parallel agents than that, and Codex errors with `AgentLimitReached` when the cap is hit — slow and noisy under the default.

Ask the user whether to raise it. If yes, add the following under `[agents]` in `~/.codex/config.toml` (create the section if it doesn't exist; preserve existing keys):

```toml
[agents]
max_threads = 16
```

The Codex hard ceiling is 64. Per OpenAI ([issue #11965](https://github.com/openai/codex/issues/11965)), values significantly above 6 may occasionally trigger 429 rate-limit errors from the API. 16 is a comfortable headroom for Turbo's largest fan-outs; users who hit 429s can dial it down (e.g., to 12 or 10).

This setting cannot be combined with `[features.multi_agent_v2]` — Codex rejects the config at startup if both are present.

## Step 6: Add AGENTS.md Additions

Read [`ADDITIONS.md`](ADDITIONS.md) from `~/.turbo/repo/codex/` and add the sections to the user's Codex instructions:

- **User-global setup:** append to `~/.codex/AGENTS.md` (create the file if missing). This is the global instruction file Codex loads regardless of project.
- **Project-local setup:** append to the repository's root `AGENTS.md`. Codex walks from the project root down to the current working directory and merges every `AGENTS.md` it finds along the way. This is a one-time install: `$update-turbo` syncs only the user-global copy, so you maintain project-local additions yourself.

Codex caps the combined instruction set at `project_doc_max_bytes` (32 KiB by default), so keep the additions focused. `AGENTS.override.md` at any level *replaces* the `AGENTS.md` at that level — do not introduce one as a workaround for merge friction.

Do not overwrite existing user instructions. Merge by section heading.

## Step 7: Oracle Setup

Ask the user whether they want to set up the oracle. Explain that `$consult-oracle` consults ChatGPT when completely stuck on a problem, but everything works without it. If the user declines, skip this step.

It requires:

- **Chrome** with an active ChatGPT session
- **Node.js 24+** (required by the oracle CLI)
- A `~/.turbo/config.json` file with `oracle` settings:

```json
{
  "oracle": {
    "chatgptUrl": "https://chatgpt.com/",
    "chromeProfile": "Default"
  }
}
```

Merge these values into the existing `~/.turbo/config.json`. The `oracle` object lives at the top level (shared across editions). See the [consult-oracle skill](skills/consult-oracle/SKILL.md) for details.

## Step 8: Quick Onboarding

Present the user with a summary of how to get started:

1. **The main workflow:** Run `$turboplan` to draft and refine a plan, implement changes, then run `$finalize` to test, review, commit, and create a PR. `$turboplan` can also chain into implementation automatically.
2. **All available skills:** See [`SKILL-INDEX.md`](SKILL-INDEX.md) for the full Codex skill list with descriptions; the [root README](../README.md#all-skills) has the same skills indexed for the Claude edition.
3. **The turboplan pipeline:** For larger projects, `$turboplan` routes to a spec + shell decomposition. See [The Turboplan Pipeline](../README.md#the-turboplan-pipeline).
4. **Peer review:** Codex uses Claude as the independent reviewer through `$peer-review`.
5. **Self-improvement:** Run `$self-improve` before context runs out to capture lessons for future sessions.
6. **Track improvements:** When noticing something out of scope, run `$note-improvement` so it doesn't get lost.
7. **Artifacts:** Plans, specs, shells, audit reports, and improvements live under `.turbo/`.
8. **Updating:** Run `$update-turbo` to update installed Codex skills from the local repo with conflict detection and changelog.
9. **Browser and UI testing:** For web app testing, enable the `browser-use@openai-bundled` plugin. For desktop UI testing, enable the `computer-use@openai-bundled` plugin. Both are bundled in Codex's `openai-bundled` marketplace. See [Browser and UI Testing](../README.md#browser-and-ui-testing) for details.
