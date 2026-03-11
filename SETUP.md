# Setup Guide

This guide walks you through setting up Turbo step by step. If you're using Claude Code, Claude can guide you through this interactively using `AskUserQuestion` prompts.

## Step 1: Install Turbo Skills

```bash
npx skills add tobihagemann/turbo --skill '*' --agent claude-code
```

Install all skills — many depend on each other, so installing only a subset will leave gaps in orchestrator workflows like `/finalize`.

Verify skills are available by starting Claude Code and trying a command like `/finalize` — it should be recognized (don't run it yet, just check it's there).

Update regularly to stay compatible with the latest Claude Code version:

```bash
npx skills update
```

## Step 2: Add `.turbo` to Global Gitignore

Some skills store project-level files in a `.turbo/` directory (specs, prompt plans, improvements). Add it to your global gitignore to keep project repos clean:

```bash
echo '.turbo/' >> ~/.gitignore
git config --global core.excludesfile ~/.gitignore
```

## Step 3: Allow All Skills

Orchestrator workflows like `/finalize` invoke many skills in sequence. Without allowlisting them, you'll get prompted for each one, breaking the flow.

Add all Turbo skills to the `permissions.allow` array in `~/.claude/settings.json`. Generate the entries from the Turbo repo:

```bash
gh api repos/tobihagemann/turbo/contents/skills --jq '.[].name' | sed 's/.*/"Skill(&)"/'
```

Merge the output into your existing `permissions.allow` array.

## Step 4: Install Prerequisites

### GitHub CLI (required)

Many skills use `gh` for PR operations, review comments, and repo queries.

```bash
brew install gh
gh auth login
```

Verify: `gh auth status` should show you're logged in.

### Codex CLI (required for `/finalize`)

The `/peer-review` skill (used during `/finalize` Phase 3) delegates to codex for AI code review.

```bash
npm install -g @openai/codex
```

Verify: `codex --help` should show usage info.

## Step 5: Configure Context Tracking

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

You should now see something like `92% context left` at the bottom of your Claude Code terminal.

> **Tip:** If you already have other settings in this file, merge the `statusLine` key into the existing JSON — don't replace the whole file.

## Step 6: Add Pre-Implementation Prep

Add this to your `~/.claude/CLAUDE.md` (create the file if it doesn't exist):

```markdown
# Pre-Implementation Prep

After plan approval (ExitPlanMode) and before making edits:
1. Run `/code-style` to load code style principles
2. Read all files referenced by the user in their request
3. Read all files mentioned in the plan
4. Read similar files in the project to mirror their style
```

This ensures Claude reads and mirrors existing code style before making changes — a key quality principle that Turbo's `/code-style` skill enforces.

## Step 7: Disable Auto-Compact

Turbo's orchestrator workflows work best when you control compaction timing. Disable auto-compact in Claude Code via `/config`.

Then manage compaction manually:
1. Check your context percentage in the status line
2. If below 50%, run `/compact` before starting `/finalize`

## Step 8: Oracle Setup

The `/oracle` skill lets you consult ChatGPT when you're completely stuck on a problem. If not set up, everything still works — `/investigate` offers oracle escalation via a prompt, and you can simply decline.

It requires:

- **Chrome** with an active ChatGPT session
- **Python 3** with the `cryptography` package (`pip3 install cryptography`)
- A `~/.turbo/config.json` file:

```bash
mkdir -p ~/.turbo
cat > ~/.turbo/config.json << 'EOF'
{
  "oracle": {
    "chatgptUrl": "https://chatgpt.com/",
    "chromeProfile": "Default"
  }
}
EOF
# Edit ~/.turbo/config.json with your ChatGPT URL and Chrome profile name
```

See the [oracle skill](skills/oracle/SKILL.md) for details.
