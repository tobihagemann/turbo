---
name: self-improve
description: "Extract lessons from this session or past sessions and route them to instructions, memory, or skills. Use when the user asks to \"self-improve\", \"what did we learn\", or \"capture lessons\"."
---

# Self-Improve

Review the current conversation, or when asked the project's past sessions, to extract durable lessons, then route each one to the right knowledge layer.

## Step 1: Gather Session Evidence

Resolve the absolute path of this skill's directory, the directory of the `SKILL.md` loaded for this run, and use it as `<this skill's directory>` below.

### Recover Pre-Compaction Evidence

**Skip** when the conversation is visible in full from the user's own first message, or when the summary shows that the last work before the compaction was a finished `$self-improve` run.

Otherwise, when it starts from a summary of earlier work, recover the compacted turns from the on-disk rollout file. Spawn a single sub-agent (inherited model defaults). The sub-agent's prompt must include:

1. The absolute path of the project root
2. A distinctive phrase from the visible conversation, for confirming which rollout file belongs to this session
3. An instruction to read `<this skill's directory>/references/transcript-miner.md` for rollout file location, extraction, and output format

Treat the returned items as raw evidence for the scan below.

### Sweep Past Sessions

**Run** when asked to distill sessions beyond the current one: read [references/past-session-sweep.md](references/past-session-sweep.md) and follow it. **Skip** otherwise.

## Step 2: Scan for Lessons

Scan the full conversation with this priority:

1. **Corrections** — Where the user interrupted, said "no", "actually", "stop", "not like that", redirected, reverted a change, picked a variant other than the one Codex proposed, or manually fixed something Codex did wrong, including a value the user changed in a file Codex wrote. After a run of nudges toward one target, the lesson is where the user settled, not each step. Highest-value lessons.
2. **Repeated guidance** — Instructions the user gave more than once. Across separate sessions this counts even where each instance reads as ordinary steering on its own.
3. **Skill-shaped knowledge** — Domain expertise that was needed repeatedly, tool/API integration details that had to be looked up, decision frameworks that emerged for evaluating options, content templates or writing conventions that were refined, and multi-step workflows where ordering mattered (as reusable domain knowledge, not the workflow itself — see #4).
4. **New workflows** — Did this session establish a novel multi-step procedure, coordination pattern, or automation that worked? A successful workflow that would need to be repeated is a prime skill candidate — even if it ran fine this time. Distinct from #3: this captures the procedure itself as a repeatable artifact, not knowledge about how to do it. Flag it.
5. **Preferences** — Formatting, naming, style, or tool choices the user expressed.
6. **Failure modes** — Approaches that failed, with what worked instead. For tool or script call failures, trace back to the information source that led to the error and make fixing that source the lesson (e.g., clarify a reference file, update skill instructions, add missing documentation). When the failure is a mistake in code that an automated check could have caught, read the project's check commands and CI configuration, once per run, before framing the lesson: a check that exists but that no git hook or CI job runs is the lesson.
7. **Domain knowledge** — Facts or conventions Codex needed but did not have.
8. **Improvement opportunities** — Out-of-scope improvements noticed during work: code that could be refactored, missing tests, performance issues, readability concerns, or feature ideas that were intentionally skipped to stay focused. **Skipped findings count here**: when code simplification or code review identified a genuine improvement or issue but it was skipped for this session, record it as a project improvement so it isn't lost.
9. **Trusted reviewer feedback** — Human PR review comments that reveal project conventions, patterns, or corrections. Trusted reviewers are repo collaborators with `admin` or `maintain` roles (determine via `gh api repos/{owner}/{repo}/collaborators --jq '.[] | select(.role_name == "admin" or .role_name == "maintain") | .login'`). Their feedback takes precedence over other reviewers and AI bots when there are contradictions.

Record each lesson with the evidence behind it, its origin (this session, or the past session it came from), the skill whose workflow it clearly arose from when there is one, and any reason the user did not state.

## Step 3: Run `$route-lessons` Skill

Run the `$route-lessons` skill with the lessons from Step 2. When the scan found none, say so instead.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.
