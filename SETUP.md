# Setup Guide

Walk the user through setting up Turbo step by step. Use `AskUserQuestion` to confirm each step before proceeding.

## Task Tracking

At the start, use `TaskCreate` to create a task for each step:

1. Install Turbo skills
2. Add `.turbo` to global gitignore
3. Install prerequisites
4. Configure context tracking
5. Add CLAUDE.md additions
6. Oracle setup
7. Quick onboarding

## Step 1: Install Turbo Skills

### Clone, Fork, or Source

Ask the user their relationship to Turbo:

1. **Consume only** (clone) — read-only, pull updates
2. **Contribute** (fork) — submit improvements back via PRs
3. **Maintain** (source) — push directly to the upstream repo

#### Clone

```bash
git clone https://github.com/tobihagemann/turbo.git ~/.turbo/repo
```

#### Fork

The user forks [tobihagemann/turbo](https://github.com/tobihagemann/turbo) on GitHub first, then:

```bash
git clone https://github.com/<user>/turbo.git ~/.turbo/repo
cd ~/.turbo/repo && git remote add upstream https://github.com/tobihagemann/turbo.git
```

#### Source

```bash
git clone https://github.com/tobihagemann/turbo.git ~/.turbo/repo
```

Same as clone, but the user has push access to origin.

### Excluded Skills

Read `~/.turbo/config.json` and check for an `excludeSkills` array. If it exists, those skills should be excluded from installation. Example config:

```json
{
  "excludeSkills": ["codex", "oracle"]
}
```

For clone mode, add `contribute-turbo` to `excludeSkills` since it requires a fork or source access.

### Copy Skills

Copy each skill directory from the local repo to the global skills directory, skipping any skills in `excludeSkills`:

```bash
mkdir -p ~/.claude/skills
for skill in $(ls ~/.turbo/repo/skills/); do
  cp -r ~/.turbo/repo/skills/$skill ~/.claude/skills/$skill
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
- `repoMode` to `"clone"`, `"fork"`, or `"source"` based on the user's choice
- `excludeSkills` to the exclusion list
- `lastUpdateHead` to the current HEAD: `git -C ~/.turbo/repo rev-parse HEAD`
- `configVersion` to the highest version number in `~/.turbo/repo/MIGRATION.md`

Preserve any existing config values (e.g., `oracle` settings).

## Step 2: Add `.turbo` to Global Gitignore

Some skills store project-level files in a `.turbo/` directory (specs, prompt plans, improvements). Add it to the user's global gitignore to keep project repos clean:

First, check if the user has `core.excludesfile` configured:

```bash
git config --global core.excludesfile
```

- If set, append `.turbo/` to that file.
- If not set, use Git's standard XDG path:

```bash
mkdir -p ~/.config/git
echo '.turbo/' >> ~/.config/git/ignore
```

Do not set `core.excludesfile` — the XDG path works automatically without it.

## Step 3: Install Prerequisites

### GitHub CLI (Required)

Many skills use `gh` for PR operations, review comments, and repo queries.

Install it from [cli.github.com](https://cli.github.com/), then authenticate:

```bash
gh auth login
```

Verify: `gh auth status` should show the user is logged in.

### Codex CLI (Required for `/finalize`)

The `/peer-review` skill (used during `/finalize` Phase 3) delegates to codex for AI code review.

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

## Step 4: Configure Context Tracking

Turbo workflows like `/finalize` consume significant context. Knowing how much context is left prevents unexpected compaction mid-workflow.

Add this to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "jq -r '\"\\(.context_window.remaining_percentage | floor)% context left\"'"
  }
}
```

The user should now see something like `92% context left` at the bottom of the Claude Code terminal.

> **Tip:** If there are already other settings in this file, merge the `statusLine` key into the existing JSON.

## Step 5: Add CLAUDE.md Additions

Read [`CLAUDE-ADDITIONS.md`](CLAUDE-ADDITIONS.md) from `~/.turbo/repo/` and add each `##` section to `~/.claude/CLAUDE.md` as a `#` section. Create the file if it doesn't exist.

These additions are kept in sync by `/update-turbo` for future updates.

## Step 6: Oracle Setup

Use `AskUserQuestion` to ask whether the user wants to set up oracle. Explain that `/consult-oracle` consults ChatGPT when completely stuck on a problem, but everything works without it. If the user declines, skip this step.

It requires:

- **Chrome** with an active ChatGPT session
- **Python 3** with the `cryptography` package (`pip3 install cryptography`)
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
2. **All available skills:** See the [README](README.md#all-skills) for the full list with descriptions.
3. **The turboplan pipeline:** For larger projects, `/turboplan` routes to a spec + prompt plan decomposition. See [The Turboplan Pipeline](README.md#the-turboplan-pipeline).
4. **Self-improvement:** Run `/self-improve` before context runs out to capture lessons for future sessions.
5. **Track improvements:** When noticing something out of scope, run `/note-improvement` so it doesn't get lost.
6. **Updating:** Run `/update-turbo` to update all skills from the local repo with conflict detection and changelog.
7. **Browser and UI testing:** For web app testing, enable the `claude-in-chrome` MCP via `/mcp` or start Claude Code with `--chrome`. For native app testing on macOS, enable the `computer-use` MCP via `/mcp`. Both are per-project settings. See [Browser and UI Testing](README.md#browser-and-ui-testing) for details.
