# Prompt Examples

[← Back to Turbo](../README.md) · [Workflow guide](workflows.md) · [Requirements](requirements.md) · [Claude Code mod](claude-code-mod.md) · [Customization](customization.md)

These are prompts you can type directly into Claude Code or Codex (`/turbo:skill-name` in Claude Code, `$turbo:skill-name` in Codex). Skill names work as natural words in your sentences. The first six groups follow a change through the factory's stages, and the rest cover work alongside it.

```
# Shape: planning a change (single entry — /turbo:plan routes based on complexity)
/turbo:plan add a caching layer to the image pipeline  ← plan mode → draft → refine → halt; run /turbo:implement-plan after
/turbo:plan build a notification system with backend, API, and UI  ← same route, larger plan
/turbo:survey-patterns  ← pattern-ground an approach without drafting a plan
/turbo:prototype  ← settle how a surface looks or an interaction feels before committing to it

# Build: implementing a plan
/turbo:implement-plan  ← execute the latest plan in .turbo/plans/ in a fresh session

# Try: testing manually
/turbo:preview  ← stand up the app so you can try a UI change yourself
/turbo:smoke-test
/turbo:exploratory-test

# Polish: reviewing and closing out
/turbo:review-code
/turbo:finalize
/turbo:quick-finalize  ← close out without the deep review loop

# Learn: capturing lessons and ideas
/turbo:self-improve
the error messages in this module are inconsistent, /turbo:backlog

# Ship: committing and opening the PR
/turbo:ship

# Investigating bugs
tests are failing in the auth module, can you please /turbo:investigate?
/turbo:investigate the app crashes when i click "save" after editing a profile

# Reviewing and resolving PR feedback
/turbo:review-pr for PR #42
/turbo:resolve-pr-comments

# Updating dependencies
/turbo:update-dependencies

# Working through the backlog
/turbo:triage-backlog  ← keep or drop each entry
/turbo:implement-backlog  ← dedicated session

# Picking the next issue to work on
/turbo:pick-next-issue

# Filing an issue
/turbo:create-issue for the flaky upload test

# Checking in on the session (Claude Code)
/turbo:resolve-open-items  ← walk the open items listed above the prompt
/turbo:context-level  ← how much of the context window is left

# Saving session state before compacting
/turbo:handoff

# Creating a new skill
/turbo:write-skill for a skill that <description>
```
