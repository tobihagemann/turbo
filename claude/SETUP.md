# Setup Guide

Walk the user through setting up Turbo step by step. Use `AskUserQuestion` to confirm each step before proceeding.

## Step 1: Install the Turbo Plugin

When `~/.turbo/config.json` holds `claude.lastUpdateHead` or a top-level `lastUpdateHead`, Turbo is already installed as copied skills. Follow [`UPDATE.md`](UPDATE.md) instead of this step, then continue with Step 2.

Otherwise, ask the user to run these in Claude Code, since writes under `~/.claude/plugins` are theirs to make:

```text
/plugin marketplace add tobihagemann/turbo
/plugin install turbo@turbo
```

Then have them open `/plugin` → Marketplaces and switch on auto-update for the `turbo` marketplace. Third-party marketplaces do not update on their own, and Turbo ships its changes to `main`.

The plugin carries every skill and injects Turbo's rules into each session. Its mod also lists open items above the prompt, shows a status line under it, and compacts long workflows so they continue on their own; the [Claude Code mod guide](../docs/claude-code-mod.md) shows each. Skills are typed as `/turbo:<skill>`.

## Step 2: Add `.turbo` to Global Gitignore

Some skills store project-level files in a `.turbo/` directory (plans, backlog, reports). Add it to the user's global gitignore to keep project repos clean:

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

## Step 4: Enable Task Tracking Tools

Turbo workflows track their phases with `TaskCreate`. Claude Code leaves the task tools out on newer models unless this environment variable is set, so tracking silently does nothing without it.

Merge this into `~/.claude/settings.json`, keeping the file's other settings:

```json
{
  "env": {
    "CLAUDE_CODE_ENABLE_TODO_TOOLS": "1"
  }
}
```

The user needs to restart Claude Code before the tools appear.

## Step 5: Oracle Setup

Use `AskUserQuestion` to ask whether the user wants to set up oracle. Explain that `/consult-oracle` consults ChatGPT when completely stuck on a problem, but everything works without it. If the user declines, skip this step.

It requires:

- **Chrome** (the oracle drives its own profile, separate from the user's)
- **Node.js 24+** (required by the oracle CLI)
- A one-time ChatGPT sign-in to that profile
- A `~/.turbo/config.json` file with oracle settings:

```json
{
  "oracle": {
    "chatgptUrl": "https://chatgpt.com/"
  }
}
```

Merge these values into `~/.turbo/config.json`, creating it when it does not exist. Then run the one-time sign-in via the Bash tool (`timeout: 600000`); it blocks until sign-in completes:

```bash
npx -y @steipete/oracle@latest --engine browser --browser-manual-login --browser-keep-browser --model gpt-6-pro -p "HI"
```

Have the user sign into ChatGPT in the window that opens.

See the [consult-oracle skill](skills/consult-oracle/SKILL.md) for details.

## Step 6: Working on Turbo (Optional)

For someone who wants to change Turbo itself or run a fork, point them at [Customization](../docs/customization.md), which covers loading a clone as the plugin and sending lessons to it.

## Step 7: Quick Onboarding

Present the user with a summary of how to get started:

1. **The main workflow:** Run `/turbo:plan` to draft and refine a plan, implement changes, then run `/turbo:finalize` to test, review, commit, and create a PR. `/turbo:plan` can also chain into implementation automatically.
2. **All available skills:** See [`SKILL-INDEX.md`](SKILL-INDEX.md) for the full Claude skill list with descriptions.
3. **The plan pipeline:** For anything beyond a clear-scope change, `/turbo:plan` routes to plan mode and produces a plan file. See [The Plan Pipeline](../docs/workflows.md#the-plan-pipeline).
4. **Peer review:** Claude uses Codex as the independent reviewer through `/peer-review`.
5. **Self-improvement:** Run `/turbo:self-improve` before context runs out to capture lessons for future sessions.
6. **Track improvements:** When noticing something out of scope, run `/turbo:backlog` so it doesn't get lost.
7. **Artifacts:** Plans, reports, and the backlog live under `.turbo/`.
8. **Updating:** Updates arrive through the marketplace auto-update switched on in Step 1. Without it, run `/plugin marketplace update turbo` and restart Claude Code.
9. **Browser and UI testing:** For web app testing, enable the `claude-in-chrome` MCP via `/mcp` or start Claude Code with `--chrome`. For native app testing on macOS, enable the `computer-use` MCP via `/mcp`. Both are per-project settings. See [Browser and UI Testing Tools](../docs/requirements.md#browser-and-ui-testing-tools) for details.
