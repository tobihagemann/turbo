# Prompt Examples

[← Back to Turbo](../README.md) · [Workflow guide](workflows.md) · [Requirements](requirements.md) · [Customization](customization.md)

These are prompts you can type directly into Claude Code or Codex (use `$skill-name` in Codex). Skill names work as natural words in your sentences.

```
# Planning a change (single entry — /turboplan routes based on complexity)
/turboplan add a caching layer to the image pipeline  ← plan mode → draft → refine → halt; run /implement-plan after
/turboplan build a notification system with backend, API, and UI  ← same route, larger plan
/survey-patterns  ← pattern-ground an approach without drafting a plan
/prototype  ← settle how a surface looks or an interaction feels before committing to it
/implement-plan  ← execute the latest plan in .turbo/plans/ in a fresh session

# Investigating bugs
tests are failing in the auth module, can you please /investigate?
/investigate the app crashes when i click "save" after editing a profile

# Reviewing code
/review-code
/review-pr for PR #42

# Auditing project health
/audit
read @.turbo/audit.md and /apply-findings  ← follow-up session

# Onboarding to a new project
/onboard
/map-codebase  ← architecture report only

# Resolving PR feedback
/resolve-pr-comments

# Updating dependencies
/update-dependencies

# Working through the improvements backlog
the error messages in this module are inconsistent, /note-improvement
/implement-improvements  ← dedicated session

# Testing manually
/smoke-test
/exploratory-test
/preview  ← stand up the app so you can try a UI change yourself

# Picking the next issue to work on
/pick-next-issue

# Filing an issue
/create-issue for the flaky upload test

# Extracting session learnings
/self-improve

# Saving session state before compacting
/create-handoff

# Creating a new skill
/create-skill for a skill that <description>
```
