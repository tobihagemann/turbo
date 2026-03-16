# Setup Guide

Walk the user through setting up Turbo step by step. Use `AskUserQuestion` to confirm each step before proceeding.

## Task Tracking

At the start, use `TaskCreate` to create a task for each step:

1. Install Turbo skills
2. Add `.turbo` to global gitignore
3. Allow all skills
4. Install prerequisites
5. Configure context tracking
6. Add pre-implementation prep
7. Disable auto-compact (optional)
8. Oracle setup
9. Quick onboarding

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

Copy each skill directory from the local repo to the global skills directory:

```bash
mkdir -p ~/.claude/skills
for skill in $(ls ~/.turbo/repo/skills/); do
  cp -r ~/.turbo/repo/skills/$skill ~/.claude/skills/$skill
done
```

Skip any skills in `excludeSkills`.

Many skills depend on each other, so installing only a subset will leave gaps in orchestrator workflows like `/finalize`.

Verify skills are available by trying a command like `/finalize`. It should be recognized (don't run it yet, just check it's there).

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

## Step 3: Allow All Skills

Orchestrator workflows like `/finalize` invoke many skills in sequence. Without allowlisting them, the user gets prompted for each one, breaking the flow.

Add all Turbo skills to the `permissions.allow` array in `~/.claude/settings.json`. Generate the entries from the local repo:

```bash
ls ~/.turbo/repo/skills/ | sed 's/.*/"Skill(&)"/'
```

Merge the output into the existing `permissions.allow` array.

## Step 4: Install Prerequisites

### GitHub CLI (Required)

Many skills use `gh` for PR operations, review comments, and repo queries.

```bash
brew install gh
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

The `/smoke-test` skill uses external skills for browser and UI automation. Install them via the skills CLI:

**agent-browser** (highly recommended) — browser automation for web app smoke testing:

```bash
npx skills add https://github.com/vercel-labs/agent-browser --skill agent-browser --agent claude-code -y -g
```

**peekaboo** (macOS only) — UI automation for native app smoke testing:

```bash
npx skills add https://github.com/openclaw/openclaw --skill peekaboo --agent claude-code -y -g
```

Both are optional. Without them, `/smoke-test` falls back to terminal-based verification.

Add `"Skill(agent-browser)"` and `"Skill(peekaboo)"` to the `permissions.allow` array in `~/.claude/settings.json` (same as Step 3) so `/smoke-test` can invoke them without prompting.

## Step 5: Configure Context Tracking

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

## Step 6: Add Pre-Implementation Prep

Add this to `~/.claude/CLAUDE.md` (create the file if it doesn't exist):

```markdown
# Pre-Implementation Prep

After plan approval (ExitPlanMode) and before making edits:
1. Run `/code-style` to load code style principles
2. Read all files referenced by the user in their request
3. Read all files mentioned in the plan
4. Read similar files in the project to mirror their style
```

This ensures code style is read and mirrored before making changes.

## Step 7: Disable Auto-Compact (Optional)

With the 1M context window, compaction is rarely needed. If you prefer to control compaction timing, disable auto-compact in Claude Code via `/config`.

## Step 8: Oracle Setup

The `/oracle` skill consults ChatGPT when completely stuck on a problem. If not set up, everything still works. `/investigate` offers oracle escalation via a prompt, and the user can simply decline.

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

Merge these values into the existing `~/.turbo/config.json`. See the [oracle skill](skills/oracle/SKILL.md) for details.

## Step 9: Quick Onboarding

Present the user with a summary of how to get started:

1. **The main workflow:** Enter plan mode, implement changes, then run `/finalize` to test, review, commit, and create a PR.
2. **All available skills:** See the [README](README.md#all-skills) for the full list with descriptions.
3. **The planning pipeline:** For larger projects, see [The Planning Pipeline](README.md#the-planning-pipeline-optional).
4. **Self-improvement:** Run `/self-improve` before context runs out to capture lessons for future sessions.
5. **Track improvements:** When noticing something out of scope, run `/note-improvement` so it doesn't get lost.
6. **Updating:** Run `/update-turbo` to update all skills from the local repo with conflict detection and changelog.
