# Manual Setup

See [SETUP.md](../SETUP.md) for the interactive guided setup. The steps below are the manual equivalent.

## 1. Clone the Repo

Clone (or fork) the Turbo repo to `~/.turbo/repo/`:

```bash
git clone https://github.com/tobihagemann/turbo.git ~/.turbo/repo
```

To contribute improvements back, fork the repo on GitHub first, then clone your fork and add the upstream remote:

```bash
git clone https://github.com/<your-username>/turbo.git ~/.turbo/repo
cd ~/.turbo/repo && git remote add upstream https://github.com/tobihagemann/turbo.git
```

## 2. Copy Skills

Copy all skill directories to your global skills location:

```bash
for skill in $(ls ~/.turbo/repo/skills/); do
  cp -r ~/.turbo/repo/skills/$skill ~/.claude/skills/$skill
done
```

Many skills depend on each other (e.g., `/finalize` composes `/polish-code`, `/update-changelog`, `/self-improve`, and more), so installing only a subset will leave gaps in the workflows.

## 3. Initialize Config

Create `~/.turbo/config.json`:

```bash
mkdir -p ~/.turbo
cat > ~/.turbo/config.json << EOF
{
  "repoMode": "clone",
  "excludeSkills": [],
  "lastUpdateHead": "$(git -C ~/.turbo/repo rev-parse HEAD)",
  "configVersion": 2
}
EOF
```

Set `repoMode` to `"clone"` (consumer), `"fork"` (contributor), or `"source"` (maintainer).

## 4. Add `.turbo` to Global Gitignore

Some skills store project-level files in a `.turbo/` directory (specs, plans, improvements). Add it to your global gitignore to keep project repos clean:

```bash
mkdir -p ~/.config/git
echo '.turbo/' >> ~/.config/git/ignore
```

This uses Git's standard XDG path (`$XDG_CONFIG_HOME/git/ignore`), which Git reads automatically without needing `core.excludesfile`. If `core.excludesfile` is already set, add `.turbo/` to that file instead.

## 5. Install Prerequisites

[GitHub CLI](https://cli.github.com/) is used by many skills for PR operations, review comments, and repo queries:

Install it from [cli.github.com](https://cli.github.com/), then authenticate:

```bash
gh auth login
```

[Codex CLI](https://github.com/openai/codex) is used by `/peer-review` for AI-powered code review during `/finalize`. Requires ChatGPT Plus or higher:

```bash
npm install -g @openai/codex
```

## 6. Install Companion Skills (Recommended)

The `/smoke-test` skill uses external skills for browser automation:

| Skill | What it's for | Install |
|---|---|---|
| [agent-browser](https://github.com/vercel-labs/agent-browser) | Browser automation for web app smoke testing (highly recommended) | `npx skills add https://github.com/vercel-labs/agent-browser --skill agent-browser --agent claude-code -y -g` |

Without agent-browser, Turbo's testing skills fall back to [Claude in Chrome](https://code.claude.com/docs/en/chrome) for browser automation. Start Claude Code with `--chrome` or run `/chrome` to connect. If neither is available, interactive testing is limited to CLI tools.

For native app and UI testing on macOS, enable the built-in `computer-use` MCP server via `/mcp`. See the [computer use docs](https://code.claude.com/docs/en/computer-use) for details.

## 7. Configure Context Tracking

Turbo workflows like `/finalize` consume significant context. Knowing how much context you have left prevents unexpected compaction mid-workflow.

Add this to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "jq -r '\"\\(.context_window.remaining_percentage | floor)% context left\"'"
  }
}
```

## 8. Add CLAUDE.md Additions

Add the sections from [`CLAUDE-ADDITIONS.md`](../CLAUDE-ADDITIONS.md) to `~/.claude/CLAUDE.md` (create the file if it doesn't exist). Each `##` section in that file maps to a `#` section in your CLAUDE.md.

## 9. Oracle Setup (Optional)

The `/consult-oracle` skill requires additional setup (Chrome, Python, ChatGPT access). See the [consult-oracle skill](../skills/consult-oracle/SKILL.md) for configuration via `~/.turbo/config.json`. If not set up, everything still works.
