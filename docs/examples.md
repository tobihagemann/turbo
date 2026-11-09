# Prompt Examples

[← Back to Turbo](../README.md) · [Workflow guide](workflows.md) · [Requirements](requirements.md) · [Customization](customization.md)

These are prompts you can type directly into Claude Code or Codex (`/turbo:skill-name` in Claude Code, `$turbo:skill-name` in Codex). Skill names work as natural words in your sentences.

```
# Planning a change (single entry — /turbo:plan routes based on complexity)
/turbo:plan add a caching layer to the image pipeline  ← plan mode → draft → refine → halt; run /turbo:implement-plan after
/turbo:plan build a notification system with backend, API, and UI  ← same route, larger plan
/turbo:survey-patterns  ← pattern-ground an approach without drafting a plan
/turbo:prototype  ← settle how a surface looks or an interaction feels before committing to it
/turbo:implement-plan  ← execute the latest plan in .turbo/plans/ in a fresh session

# Investigating bugs
tests are failing in the auth module, can you please /turbo:investigate?
/turbo:investigate the app crashes when i click "save" after editing a profile

# Reviewing code
/turbo:review-code
/turbo:review-pr for PR #42

# Resolving PR feedback
/turbo:resolve-pr-comments

# Updating dependencies
/turbo:update-dependencies

# Working through the backlog
the error messages in this module are inconsistent, /turbo:backlog
/turbo:triage-backlog  ← keep or drop each entry
/turbo:implement-backlog  ← dedicated session

# Testing manually
/turbo:smoke-test
/turbo:exploratory-test
/turbo:preview  ← stand up the app so you can try a UI change yourself

# Picking the next issue to work on
/turbo:pick-next-issue

# Filing an issue
/turbo:create-issue for the flaky upload test

# Extracting session learnings
/turbo:self-improve

# Saving session state before compacting
/turbo:handoff

# Creating a new skill
/turbo:write-skill for a skill that <description>
```
