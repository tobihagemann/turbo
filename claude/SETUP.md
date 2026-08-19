# Setup Guide

Walk the user through setting up Turbo step by step. Use `AskUserQuestion` to confirm each step before proceeding.

## Step 1: Install Turbo Skills

### Clone the Repo

```bash
git clone https://github.com/tobihagemann/turbo.git ~/.turbo/repo
```

Clone the upstream URL: `/update-turbo` pulls from `origin`. Keep any fork or development checkout of Turbo outside `~/.turbo/repo`.

### Excluded Skills

Read `~/.turbo/config.json` and check for a `claude.excludeSkills` array. If it exists, those skills should be excluded from installation. Example config:

```json
{
  "claude": {
    "excludeSkills": ["codex", "oracle"]
  }
}
```

### Copy Skills

Copy each skill directory from the local repo to the global skills directory, skipping any skills in `claude.excludeSkills`:

```bash
mkdir -p ~/.claude/skills
exclude=$(jq -r '.claude.excludeSkills // [] | .[]' ~/.turbo/config.json 2>/dev/null)
for skill in ~/.turbo/repo/claude/skills/*; do
  [ -d "$skill" ] || continue
  name=$(basename "$skill")
  echo "$exclude" | grep -qxF "$name" && continue
  cp -R "$skill" ~/.claude/skills/
done
```

Many skills depend on each other, so installing only a subset will leave gaps in pipelines like `/finalize`.

Verify installation by confirming the skill directories exist in `~/.claude/skills/`.

### Initialize Config

Create or update `~/.turbo/config.json`:

```bash
mkdir -p ~/.turbo
```

Set:
- `claude.excludeSkills` to the exclusion list
- `claude.lastUpdateHead` to the current HEAD: `git -C ~/.turbo/repo rev-parse HEAD`
- `claude.configVersion` to the highest version number in `~/.turbo/repo/claude/MIGRATION.md`

Preserve any existing config values (`oracle`, `codex` if the Codex edition is also installed).

Example shape:

```json
{
  "claude": {
    "excludeSkills": [],
    "lastUpdateHead": "<HEAD>",
    "configVersion": 5
  }
}
```

## Step 2: Add `.turbo` to Global Gitignore

Some skills store project-level files in a `.turbo/` directory (plans, improvements, reports). Add it to the user's global gitignore to keep project repos clean:

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

### Codex CLI (Required for `/finalize`)

The `/peer-review` skill (used during `/finalize`) delegates to codex for AI code review.

```bash
npm install -g @openai/codex
```

Verify: `codex --help` should show usage info.

### Companion Skills (Recommended)

Use `AskUserQuestion` to ask whether the user wants to install agent-browser for browser automation. Explain that without it, testing skills fall back to the `claude-in-chrome` MCP, and without that, interactive testing is limited to CLI tools. If the user declines, skip the install.

**agent-browser** (highly recommended) — browser automation for web app smoke testing:

```bash
npx skills add https://github.com/vercel-labs/agent-browser --skill agent-browser --agent claude-code -y -g
```

## Step 4: Configure Claude Code Settings

Add both keys below to `~/.claude/settings.json`, merging each into the existing JSON when the file already has other settings.

### Context Tracking

Turbo workflows like `/finalize` consume significant context. Knowing how much context is left prevents unexpected compaction mid-workflow.

```json
{
  "statusLine": {
    "type": "command",
    "command": "jq -r '\"\\(.context_window.remaining_percentage | floor)% context left\"'"
  }
}
```

The user should now see something like `92% context left` at the bottom of the Claude Code terminal.

### Task Tracking Tools

Turbo workflows track their phases with `TaskCreate`. Claude Code leaves the task tools out on newer models unless this environment variable is set, so tracking silently does nothing without it.

```json
{
  "env": {
    "CLAUDE_CODE_ENABLE_TODO_TOOLS": "1"
  }
}
```

The user needs to restart Claude Code before the tools appear.

## Step 5: Add CLAUDE.md Additions

Read [`ADDITIONS.md`](ADDITIONS.md) from `~/.turbo/repo/claude/` and add each `##` section to `~/.claude/CLAUDE.md` as a `#` section. Create the file if it doesn't exist.

These additions are kept in sync by `/update-turbo` for future updates.

## Step 6: Oracle Setup

Use `AskUserQuestion` to ask whether the user wants to set up oracle. Explain that `/consult-oracle` consults ChatGPT when completely stuck on a problem, but everything works without it. If the user declines, skip this step.

It requires:

- **Chrome** with an active ChatGPT session
- **Node.js 24+** (required by the oracle CLI)
- A `~/.turbo/config.json` file with oracle settings:

```json
{
  "oracle": {
    "chatgptUrl": "https://chatgpt.com/",
    "chromeProfile": "Default"
  }
}
```

Merge these values into the existing `~/.turbo/config.json`. See the [consult-oracle skill](skills/consult-oracle/SKILL.md) for details.

## Step 7: Quick Onboarding

Present the user with a summary of how to get started:

1. **The main workflow:** Run `/turboplan` to draft and refine a plan, implement changes, then run `/finalize` to test, review, commit, and create a PR. `/turboplan` can also chain into implementation automatically.
2. **All available skills:** See [`SKILL-INDEX.md`](SKILL-INDEX.md) for the full Claude skill list with descriptions (same content as the [root README](../README.md#all-skills)).
3. **The turboplan pipeline:** For anything beyond a clear-scope change, `/turboplan` routes to plan mode and produces a plan file. See [The Turboplan Pipeline](../README.md#the-turboplan-pipeline).
4. **Peer review:** Claude uses Codex as the independent reviewer through `/peer-review`.
5. **Self-improvement:** Run `/self-improve` before context runs out to capture lessons for future sessions.
6. **Track improvements:** When noticing something out of scope, run `/note-improvement` so it doesn't get lost.
7. **Artifacts:** Plans, audit reports, and improvements live under `.turbo/`.
8. **Updating:** Run `/update-turbo` to update all skills from the local repo with conflict detection and changelog.
9. **Browser and UI testing:** For web app testing, enable the `claude-in-chrome` MCP via `/mcp` or start Claude Code with `--chrome`. For native app testing on macOS, enable the `computer-use` MCP via `/mcp`. Both are per-project settings. See [Browser and UI Testing](../README.md#browser-and-ui-testing) for details.
