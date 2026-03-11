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
7. Disable auto-compact
8. Oracle setup
9. Quick onboarding

## Step 1: Install Turbo Skills

Before installing, check for two things:

### Excluded Skills

Read `~/.turbo/config.json` and check for an `excludeSkills` array. If it exists, those skills should be excluded from installation. Example config:

```json
{
  "excludeSkills": ["codex", "oracle"]
}
```

### Conflict Detection

Check if the user has existing non-symlinked skills in `~/.claude/skills/` that share names with Turbo skills. The install command overwrites existing skills with the same name.

```bash
for skill in $(gh api repos/tobihagemann/turbo/contents/skills --jq '.[].name'); do
  target="$HOME/.claude/skills/$skill"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "WARNING: $target exists and is not a symlink (will be overwritten)"
  fi
done
```

If any warnings appear, use `AskUserQuestion` to alert the user. For each conflicting skill, offer three options:
1. **Overwrite** — proceed with installation
2. **Exclude** — add the skill to `excludeSkills` in `~/.turbo/config.json` and skip it

### Install

If there are excluded skills (from config or user choice), build a specific skill list and pass it to `--skill`:

```bash
npx skills add tobihagemann/turbo --skill 'skill1' --skill 'skill2' ... --agent claude-code -y -g
```

If no exclusions, install all:

```bash
npx skills add tobihagemann/turbo --skill '*' --agent claude-code -y -g
```

Many skills depend on each other, so installing only a subset will leave gaps in orchestrator workflows like `/finalize`.

Verify skills are available by trying a command like `/finalize`. It should be recognized (don't run it yet, just check it's there).

Update by re-running the same command to pick up new, changed, or removed skills.

## Step 2: Add `.turbo` to Global Gitignore

Some skills store project-level files in a `.turbo/` directory (specs, prompt plans, improvements). Add it to the user's global gitignore to keep project repos clean:

```bash
echo '.turbo/' >> ~/.gitignore
git config --global core.excludesfile ~/.gitignore
```

## Step 3: Allow All Skills

Orchestrator workflows like `/finalize` invoke many skills in sequence. Without allowlisting them, the user gets prompted for each one, breaking the flow.

Add all Turbo skills to the `permissions.allow` array in `~/.claude/settings.json`. Generate the entries from the Turbo repo:

```bash
gh api repos/tobihagemann/turbo/contents/skills --jq '.[].name' | sed 's/.*/"Skill(&)"/'
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

## Step 7: Disable Auto-Compact

Turbo's orchestrator workflows work best when compaction timing is controlled manually. Disable auto-compact in Claude Code via `/config`.

Then manage compaction manually:
1. Check the context percentage in the status line
2. If below 50%, run `/compact` before starting `/finalize`

## Step 8: Oracle Setup

The `/oracle` skill consults ChatGPT when completely stuck on a problem. If not set up, everything still works. `/investigate` offers oracle escalation via a prompt, and the user can simply decline.

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

## Step 9: Quick Onboarding

Present the user with a summary of how to get started:

1. **The main workflow:** Enter plan mode, implement changes, then run `/finalize` to test, review, commit, and create a PR.
2. **All available skills:** See the [README](README.md#all-skills) for the full list with descriptions.
3. **The planning pipeline:** For larger projects, see [The Planning Pipeline](README.md#the-planning-pipeline-optional).
4. **Self-improvement:** Run `/distill-session` before context runs out to capture lessons for future sessions.
5. **Track improvements:** When noticing something out of scope, run `/note-improvement` so it doesn't get lost.
6. **Updating:** Run `/update-turbo` to update all skills with conflict detection and exclusion support.
