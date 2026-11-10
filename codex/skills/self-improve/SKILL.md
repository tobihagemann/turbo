---
name: self-improve
description: "Extract lessons from this session or past sessions and route them to instructions, memory, or skills. Use when the user asks to \"self-improve\", \"extract lessons\", or \"what did we learn\"."
---

# Self-Improve

Review the current conversation, or the project's past sessions when asked, to extract durable lessons and route each one to the right knowledge layer.

## Step 1: Detect Context

Available destinations:

- **Project AGENTS.md** — the instruction file in the project root, plus any nested ones in subdirectories. At each level use `AGENTS.override.md` when one is present, otherwise `AGENTS.md`: an override replaces that directory's `AGENTS.md` rather than adding to it, so a lesson written to a shadowed file never loads.
- **Auto memory** — one writable memory target resolved for the canonical project root. Prefer a synced Claude Code project-memory source, then a memory-update target explicitly named by the active harness. If neither resolves, skip this destination.
- **Skills** — Project skills at `.agents/skills/` (walked from project root down to cwd), user-installed skills at `~/.agents/skills/` (resolve symlinks)

Resolve the canonical project root as the Git top-level containing the working directory, or the physical working directory outside a repository. Resolve Auto memory in this order:

1. **Synced Claude Code source memory** — Read `~/.turbo/config.json`. When `codex.sharedClaudeAutoMemory` is exactly `true`, treat shared-memory setup as complete for every project and use this branch. Resolve `autoMemoryDirectory` from Claude Code's managed settings, then project-local `.claude/settings.local.json`, then the user `<Claude config home>/settings.json`; exclude checked-in `.claude/settings.json`, where Claude Code ignores this security-sensitive field. Use the expanded override when set. Otherwise locate the resource directory under `~/.codex/memories/extensions/external_agent_import/resources/` whose `scope.json` matches the canonical project root, take its directory name as the exact Claude project key, and use `projects/<project key>/memory/` under `CLAUDE_CONFIG_DIR` when set or `~/.claude/`. Treat `false`, a missing or invalid key, and an unreadable `~/.turbo/config.json` as not opted in and continue to the harness target.
2. **Harness memory update target** — Otherwise use a project-specific memory file or additive note intake that the active harness instructions explicitly name for memory updates.
3. **No target** — Otherwise skip Auto memory and route lessons through the remaining destinations.

Treat imported extension resources and the harness's consolidated memory files as read-only. For the resolved target, list the directory when applicable and read its index before routing lessons.

Discover the project instruction files (the root file and any nested ones in subdirectories, resolved through the override rule above) and read them. When those files or the resolved Auto memory target point at a knowledge base the repo maintains, read its index too; it is a documentation source for Step 3 rather than a routing destination. List all skill directories with the `description` frontmatter of each SKILL.md, but leave the bodies unread until Step 2.

Read the top-level `checkout` key from `~/.turbo/config.json` when the file exists. When it names a directory holding `codex/skills/`, that directory is the user's Turbo clone or fork. Treat any other value as unset, and say so in the Step 5 routing plan.

### Skill Ownership Detection

Resolve the absolute path of the directory this `SKILL.md` was loaded from, and use it as `<this skill's directory>` below. When `../../.codex-plugin/plugin.json` relative to it exists and names the plugin `turbo`, that directory's parent is the Turbo plugin's skills folder. Otherwise this skill runs from an override or a leftover copy, no folder is known to be Turbo's, and only a `$turbo:` invocation marks a turbo skill. Classify every skill this session touched by where it was loaded from, never by its name alone:

- Skills that live in the project are user/project skills
- A skill is a turbo skill when it ran as `$turbo:<name>`, or when its `SKILL.md` was read from the Turbo plugin's skills folder. A same-named skill loaded from `~/.agents/skills/` or the project overrides the Turbo skill, and its lessons go to that override
- For every skill in `~/.agents/skills/` not classified as turbo, overrides included, read [references/package-managed-skills.md](references/package-managed-skills.md) once and apply its Classify the Skill section to each
- A skill that no bullet above classifies is ownership-unresolved when the session's record shows the folder it was loaded from, and package-managed otherwise

**Exception:** If the current project IS the turbo repo (i.e., the working directory contains this skill collection), route turbo skill lessons through the **Existing user/project skill** destination in Step 4 — edits go directly to `codex/skills/<name>/` in the project, with no handoff and no contribution flow.

**Verification rule (mandatory before routing in Step 4):** For every candidate skill that is about to be routed as turbo and ran in this session, find the load that ran it in this session's record: a `$turbo:` invocation or the `SKILL.md` path it read. Confirm that the load came from the Turbo plugin's skills folder. For a candidate that did not run, confirm that `<Turbo plugin's skills folder>/<name>/SKILL.md` exists and that no skill of that name exists in `~/.agents/skills/` or the project. Do not rely on a name match, remembered listings from earlier in the session, or filename hits in grep output: a personal or project skill of the same name is an override, not the turbo skill. Classify a candidate that fails this rule again by the bullets above. The rule applies under the exception above too.

## Step 2: Gather Session Evidence and Scan for Lessons

### Recover Pre-Compaction Evidence

**Skip** when the conversation is visible in full from the user's own first message.

When it starts from a summary of earlier work instead, recover the compacted turns from the on-disk rollout file. Spawn a single sub-agent (inherited model defaults). The sub-agent's prompt must include:

1. The absolute path of the project root
2. A distinctive phrase from the visible conversation, for confirming which rollout file belongs to this session
3. An instruction to read `<this skill's directory>/references/transcript-miner.md` for rollout file location, extraction, and output format

Treat the returned items as raw evidence for the scan below.

### Sweep Past Sessions

**Run** when asked to distill sessions beyond the current one: read [references/past-session-sweep.md](references/past-session-sweep.md) and follow it. **Skip** otherwise.

### Identify Session Skills

Before scanning for lessons, identify which skills were loaded during this session:

- Scan the conversation for skill invocations, `$turbo:`-prefixed ones included, and `SKILL.md` reads from `~/.agents/skills/` or the Turbo plugin's skills folder
- Build a list of session skills, marking each as turbo, user/project, package-managed, or ownership-unresolved (using the detection from Step 1)
- This list informs routing in Step 4: when a lesson clearly arose from a specific skill's workflow, that skill is the natural routing target

### Scan for Lessons

Scan the full conversation with this priority:

1. **Corrections** — Where the user interrupted, said "no", "actually", "stop", "not like that", redirected, or manually fixed something Codex did wrong. Highest-value lessons.
2. **Repeated guidance** — Instructions the user gave more than once. Across separate sessions this counts even where each instance reads as ordinary steering on its own.
3. **Skill-shaped knowledge** — Domain expertise that was needed repeatedly, tool/API integration details that had to be looked up, decision frameworks that emerged for evaluating options, content templates or writing conventions that were refined, and multi-step workflows where ordering mattered (as reusable domain knowledge, not the workflow itself — see #4).
4. **New workflows** — Did this session establish a novel multi-step procedure, coordination pattern, or automation that worked? A successful workflow that would need to be repeated is a prime skill candidate — even if it ran fine this time. Distinct from #3: this captures the procedure itself as a repeatable artifact, not knowledge about how to do it. Flag it.
5. **Preferences** — Formatting, naming, style, or tool choices the user expressed.
6. **Failure modes** — Approaches that failed, with what worked instead. For tool or script call failures, trace back to the information source that led to the error and route the fix there (e.g., clarify a reference file, update skill instructions, add missing documentation). When the failure is a mistake in code that an automated check could have caught, read the project's check commands and CI configuration, once per run, before framing the lesson: a check that exists but that no git hook or CI job runs is the lesson.
7. **Domain knowledge** — Facts or conventions Codex needed but did not have.
8. **Improvement opportunities** — Out-of-scope improvements noticed during work: code that could be refactored, missing tests, performance issues, readability concerns, or feature ideas that were intentionally skipped to stay focused. **Skipped findings count here**: when code simplification or code review identified a genuine improvement or issue but it was skipped for this session, route it as a project improvement so it isn't lost.
9. **Trusted reviewer feedback** — Human PR review comments that reveal project conventions, patterns, or corrections. Trusted reviewers are repo collaborators with `admin` or `maintain` roles (determine via `gh api repos/{owner}/{repo}/collaborators --jq '.[] | select(.role_name == "admin" or .role_name == "maintain") | .login'`). Their feedback takes precedence over other reviewers and AI bots when there are contradictions.

After scanning, read the SKILL.md of every skill a candidate lesson could touch: the session skills, plus any skill whose description from Step 1 covers a lesson's domain.

## Step 3: Filter

Keep only lessons that are:
- **Stable** — likely to remain true across future sessions
- **Non-obvious** — Codex would not already know this
- **Actionable** — can be expressed as a rule or instruction
- **Not already covered** — no rule in the files read in Steps 1 and 2, in the `references/` and other supporting files of the skills read in Step 2, or in the project's own knowledge stores already covers it, even as a special case. A lesson drawn from one incident is covered when an existing general rule, followed, would have prevented that incident; a workflow is covered only when an existing skill already encodes its steps. Search those sources for each candidate's keywords, then judge coverage by meaning rather than by shared wording. When the covering rule was in context during the incident and still read past, because its wording, scope, or placement let the incident through, keep the lesson as a revision of that rule in place, adding no new rule; otherwise discard it. A prose rule does not cover a rule a tool can decide from the code alone. When the session broke such a rule, keep the lesson as a new lesson rather than a revision. A lesson covered only in an unrelated subtree's AGENTS.md still counts as uncovered for the subtree it actually applies to.
- **Still a concern** — the issue is not already fixed by changes made in this session, such as a bug that was found and fixed or a missing feature that was added. **Exception: a successful workflow or procedure is not "resolved"; it stays a skill candidate.** When sweeping past sessions, judge this against the current state of the code and docs rather than against this session's changes.

Discard anything session-specific, speculative, one-off, or already resolved by code changes in this session (but not successful workflows — see exception above). If no lessons survive filtering, tell the user and stop.

## Step 4: Route Each Lesson

Assign each surviving lesson to exactly one destination. Apply the routing rules in this order. The first that applies to a lesson decides its destination:

1. **Package-managed skills**
2. **Mechanical rules**
3. **Revisions**
4. **Skill-first rule**
5. The destination table, with the **Tiebreakers** settling a lesson that fits more than one row

**Package-managed skills (mandatory):** A lesson for a skill Step 1 classified as package-managed or ownership-unresolved routes by the Route Its Lessons section of [references/package-managed-skills.md](references/package-managed-skills.md).

**Mechanical rules (mandatory):** Classify each lesson that states a rule for the project's code as mechanical or judgment. A mechanical rule is one a tool can decide from the code alone: a fixed pattern, a banned call, an import shape, a file-location rule. Route it to **Deterministic check** alone, writing it to no instruction file, memory, or skill. A rule that takes judgment to apply routes by the remaining rules like any other lesson.

**Revisions:** A lesson Step 3 kept as a revision routes to the destination that holds the rule it revises, as an update-in-place. When the rule lives in a source that is not a routing destination, route the lesson by the remaining rules like any other. When the rule lives in a turbo skill, its destination is **Existing turbo skill**, or **Existing user/project skill** under Step 1's turbo repo exception: the revision goes where any other lesson for that skill goes, never into the plugin's copy.

**Skill-first rule (mandatory):** Check whether the lesson corrects, refines, or adds a guardrail to any existing skill's behavior — turbo or user/project. This includes lessons about skipping steps, wrong defaults, missing edge cases, or any "don't do X when running $skill-name" correction. If yes, route to that skill. Do not route skill corrections to auto memory or AGENTS.md.

| Destination | Criteria |
|---|---|
| **Project backlog** | Actionable improvement to existing **code**: refactoring, performance, reliability, readability, testing, or DX. Not for documentation fixes — factual errors in AGENTS.md belong in the **Project AGENTS.md** row. Route to `.turbo/backlog.md` via the `$backlog` skill. |
| **Deterministic check** | A mechanical rule for the project's code, or an existing check that nothing runs. The work is building the check or wiring it in: a rule in the linter the project already uses, a git hook, or a CI job, whichever its existing tooling makes cheapest. Route to `.turbo/backlog.md` via the `$backlog` skill. |
| **Auto memory** | Discovered knowledge with no skill home: API quirks, debugging workarounds, compiler gotchas, tool pitfalls, user preferences. Must not overlap with any existing skill's domain — if it does, route to the skill instead (see skill-first rule above). A lesson the package-managed skills rule sends here stays here, whatever domain it overlaps, as does a turbo skill lesson the user declines to propose upstream in Step 6. When Step 1 resolved no Auto memory target, report a lesson one of those rules sends here as unrouted, and leave the skill it applies to unedited. |
| **Project AGENTS.md** | Intentional project decisions: conventions, architecture, stack choices, build setup, module boundaries. Also factual corrections to AGENTS.md content (wrong commands, outdated paths, incorrect conventions) — fix these directly, do not defer to Project backlog. When the lesson applies only to one subtree, route it to the nearest enclosing AGENTS.md; reserve the root file for project-wide decisions. |
| **Existing user/project skill** | Lesson would improve a skill's instructions, supporting files, or reference materials, add a missing edge case, correct its workflow, or refine its trigger conditions. Route to any skill whose *domain* covers the lesson — not just the skill worked on in this session. Changes go to the skill file directly. No contribution flow. |
| **New skill** | A cohesive body of knowledge emerged that deserves its own on-demand context. The test: would this knowledge be too large for an AGENTS.md section, and should it only be loaded when relevant? |
| **Existing turbo skill** | Same criteria as **Existing user/project skill** above, but for turbo skills. **Before routing here, apply Step 1's verification rule; a skill it classifies as other than turbo routes to the Existing user/project skill destination instead, subject to the package-managed skills rule above.** Changes are not applied in this session: they go into a handoff in the Turbo checkout when `checkout` is set, and are offered upstream otherwise (see Step 6). |
| **No destination** | Does not clearly fit any destination. Drop it. |

**Splitting heuristic:** When a session creates scripts or multi-step procedures, split the lesson: a brief pointer goes to AGENTS.md (script names, purpose), and the full workflow goes to a skill. Don't collapse them into a single AGENTS.md entry.

**Tiebreakers (in priority order):**
1. **Skill vs. AGENTS.md → always the skill**, a turbo skill included.
2. **Skill vs. auto memory → always the skill.** If a lesson falls within the domain of an existing skill, it goes to the skill. Auto memory is for knowledge that has no skill home, and for the domain of a skill a package manager maintains.
3. **AGENTS.md vs. auto memory** — intentional decisions go to AGENTS.md. Discovered knowledge (gotchas, workarounds, quirks) goes to auto memory.
4. **Lesson vs. improvement** — if the item is *knowledge to remember*, it's a lesson. If it's *work to do later*, it's an improvement. They don't compete — the same session can produce both.

## Step 5: Present Routing Plan

Output a table as text before making any changes:

```
| # | Lesson | Destination | Action |
|---|--------|-------------|--------|
| 1 | Always use X for... | Project AGENTS.md | Append to ## Conventions |
| 2 | The $pr skill should... | ~/.agents/skills/pr | Update references/create.md Phase 2 |
| 3 | Multi-step deploy workflow | New project skill | Create new skill |
| 4 | User prefers short commit msgs | Auto memory | Update <resolved memory target> |
| 5 | $finalize should skip step 3 when... | Turbo skill: finalize | Handoff to Turbo checkout |
```

For each lesson, show: concise summary, exact target file/skill, and whether it's an append, update-in-place, or new creation. For Auto memory, name the resolved source or harness update target and state when a source write still requires import and consolidation before Codex can recall it. The approval covers the durable memory write at that displayed target. Turbo skill lessons show `Handoff to Turbo checkout` as the action when `checkout` is set, and `Propose upstream` otherwise, naming the Auto memory target that receives the lesson if the user declines to propose it.

Then use `request_user_input` with these options: **Approve** or **Reject**.

## Step 6: Execute

Apply approved changes in order:

1. **Backlog** — For items routed to the project backlog or to a deterministic check, run the `$backlog` skill with the summary, location, and rationale for each, and for a deterministic check the mechanism it goes into.
2. **Updates to auto memory** — Re-read the approved target immediately before writing. For a synced Claude Code source, match the existing topic-file and index conventions, leave `.consolidate-lock` untouched, and report propagation as pending; the lesson becomes available to Codex only after successful import and consolidation. Claim completed recall only after verifying it. For a harness memory update target, follow the active memory instructions; when they name an additive note intake, create a new note rather than editing consolidated memory files. Keep imported extension resources read-only in every branch.
3. **Updates to AGENTS.md** — Read the target file selected in Step 4 (the root file or a nested subtree file, resolved through the override rule in Step 1), find the right section, append or update in place. Match the tone and format already present.
4. **Updates to user/project skills** — Run the `$write-skill` skill to apply changes to any file inside the skill directory (SKILL.md, references, scripts, assets).
5. **New skills** — Run the `$write-skill` skill for each new skill. Provide the trigger conditions and relevant context from the session.
6. **Turbo skill lessons** — Edit no file in the Turbo plugin's skills folder: a plugin update replaces it. Read [references/turbo-skill-lessons.md](references/turbo-skill-lessons.md) and follow it.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

## Writing Guidelines

- Match the tone and format of the target file
- Use imperative mood and short declarative sentences
- Group related insights under a descriptive heading
- Omit rationale unless the rule would seem arbitrary without it
- Never include temporary state, in-progress work, or task-specific details
- Keep lessons generic—avoid overly concrete examples; state the rule, not the instance
- For AGENTS.md: write as agent documentation — project rules any AI agent on this repo should follow
- For auto memory: write as personal project notes — concise, operational, organized by topic
- For skills: follow the conventions in the existing skill collection
- For files that live in the repo (AGENTS.md and project skills): name only mechanisms that live in the repo too; describe an installed skill's behavior generically
