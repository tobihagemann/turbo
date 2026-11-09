---
name: self-improve
description: "Extract lessons from this session or past sessions and route them to instructions, memory, or skills. Use when the user asks to \"self-improve\", \"extract lessons\", or \"what did we learn\"."
---

# Self-Improve

Review the current conversation, or the project's past sessions when asked, to extract durable lessons and route each one to the right knowledge layer.

## Step 1: Detect Context

Available destinations:

- **Project CLAUDE.md / AGENTS.md** — The root `.claude/CLAUDE.md` (may be a symlink to `../AGENTS.md` — resolve it), plus any nested `CLAUDE.md` / `AGENTS.md` files in subdirectories. Claude Code loads a subdirectory's file on demand when files in that subtree are accessed, so a lesson scoped to one subtree belongs in the nearest enclosing file, with the root reserved for project-wide rules.
- **Auto memory** — The project-specific memory directory named by the active harness. An effective `autoMemoryDirectory` setting overrides its location; otherwise it normally lives at `<Claude config home>/projects/<encoded project root>/memory/`, where the config home is `CLAUDE_CONFIG_DIR` when set and `~/.claude` otherwise. The key replaces every character outside `A-Za-z0-9` with `-`, and long keys may be truncated and hashed, so prefer the exact harness-provided path over recomputing it. List the directory and read `MEMORY.md` if it exists.
- **Skills** — Project skills at `skills/` or `.claude/skills/` (resolve symlinks)

Discover the project CLAUDE.md/AGENTS.md files (the root file and any nested ones in subdirectories) and read them, then read MEMORY.md. When those files point at a knowledge base the repo maintains, read its index too; it is a documentation source for Step 3 rather than a routing destination. List all skill directories with the `description` frontmatter of each SKILL.md, but do not read the bodies yet — Step 2 needs to run first so you know what to look for.

Read the top-level `checkout` key from `~/.turbo/config.json` when the file exists. When it names a directory holding `claude/skills/`, that directory is the user's Turbo clone or fork. Treat any other value as unset, and say so in the Step 5 routing plan.

### Skill Ownership Detection

When `${CLAUDE_SKILL_DIR}/../../.claude-plugin/plugin.json` exists and names the plugin `turbo`, the Turbo plugin's skills folder is `${CLAUDE_SKILL_DIR}/..`. Otherwise this skill runs from an override or a leftover copy, no folder is known to be Turbo's, and only a `turbo:` invocation marks a turbo skill. Classify every skill this session touched by where it was loaded from, never by its name alone:

- Skills that live in the project are user/project skills
- A skill is a turbo skill when it ran as `turbo:<name>`, or when the base directory its load reported, or the path its `SKILL.md` was read from, lies in the Turbo plugin's skills folder. A same-named skill loaded from `~/.claude/skills/` or the project overrides the Turbo skill, and its lessons go to that override
- For every skill in `~/.claude/skills/` not classified as turbo, overrides included, read `~/.agents/.skill-lock.json`. Its top-level `skills` object is keyed by skill name, and a skill listed there was installed from a source that replaces it wholesale on its next update. Match on the resolved path rather than the name alone, against the entry's `skillPath`, so a local fork that replaced the installed copy is not mistaken for it. A skill that matches is package-managed. The signal runs one way: absence from the file leaves ownership genuinely open, so carry an unlisted skill into Step 4 as ownership-unresolved

**Verification rule (mandatory before routing in Step 4):** For every candidate skill that is about to be routed as turbo and ran in this session, find the load that ran it in this session's record: a `turbo:` Skill tool invocation, the base directory a load reported, or a `SKILL.md` read. Confirm that the load came from the Turbo plugin's skills folder. For a candidate that did not run, confirm that `<Turbo plugin's skills folder>/<name>/SKILL.md` exists and that no skill of that name exists in `~/.claude/skills/` or the project. Do not rely on a name match, remembered listings from earlier in the session, or filename hits in grep output: a personal or project skill of the same name is an override, not the turbo skill. A miss here mislabels a user/project skill as turbo, sends its lesson to a handoff or an upstream proposal unnecessarily, and can introduce session-specific content into a shared skill — so the check is not optional.

**Exception:** If the current project IS the turbo repo (i.e., the working directory contains this skill collection), route turbo skill lessons through the **Existing user/project skill** destination in Step 4 — edits go directly to `claude/skills/<name>/` in the project, with no handoff and no contribution flow.

## Step 2: Gather Session Evidence and Scan for Lessons

### Recover Pre-Compaction Evidence

**Skip** when the conversation is visible in full from the user's own first message.

When it starts from a summary of earlier work instead, recover the compacted turns from the on-disk transcript. Spawn a single subagent (`model: "opus"`, no `name`). Wait for it to report before continuing; do not relaunch it if it has not yet reported. The subagent's prompt must include:

1. The absolute path of the project root
2. A distinctive phrase from the visible conversation, for confirming which transcript belongs to this session
3. An instruction to read `${CLAUDE_SKILL_DIR}/references/transcript-miner.md` for transcript location, extraction, and output format

Treat the returned items as raw evidence for the scan below.

### Sweep Past Sessions

**Run** when asked to distill sessions beyond the current one. **Skip** otherwise.

Propose a cutoff first: take the newest modification time in the memory directory from Step 1, state it, then use `AskUserQuestion` to confirm sweeping from it or sweeping the whole history. A memory file's timestamp records a write rather than a completed sweep, so it bounds the work without settling what a previous run covered. When the directory is absent or empty, sweep the whole history without asking.

Spawn a single subagent (`model: "opus"`, no `name`). Wait for it to report before continuing; do not relaunch it if it has not yet reported. The subagent's prompt must include:

1. The absolute path of the project root
2. The confirmed cutoff as an ISO-8601 timestamp, or that there is none
3. An instruction to read `${CLAUDE_SKILL_DIR}/references/transcript-miner.md` and follow its sweep process

Treat the returned items as raw evidence for the scan below.

### Identify Session Skills

Before scanning for lessons, identify which skills were loaded during this session:

- Scan the conversation for Skill tool invocations, `turbo:`-prefixed ones included, the base directory each skill load reported, and SKILL.md reads from `~/.claude/skills/` or the Turbo plugin's skills folder
- Build a list of session skills, marking each as turbo, user/project, package-managed, or ownership-unresolved (using the detection from Step 1)
- This list informs routing in Step 4: when a lesson clearly arose from a specific skill's workflow, that skill is the natural routing target

### Scan for Lessons

Scan the full conversation with this priority:

1. **Corrections** — Where the user interrupted, said "no", "actually", "stop", "not like that", redirected, or manually fixed something Claude did wrong. Highest-value lessons.
2. **Repeated guidance** — Instructions the user gave more than once. Across separate sessions this counts even where each instance reads as ordinary steering on its own.
3. **Skill-shaped knowledge** — Domain expertise that was needed repeatedly, tool/API integration details that had to be looked up, decision frameworks that emerged for evaluating options, content templates or writing conventions that were refined, and multi-step workflows where ordering mattered (as reusable domain knowledge, not the workflow itself — see #4).
4. **New workflows** — Did this session establish a novel multi-step procedure, coordination pattern, or automation that worked? A successful workflow that would need to be repeated is a prime skill candidate — even if it ran fine this time. Distinct from #3: this captures the procedure itself as a repeatable artifact, not knowledge about how to do it. Flag it.
5. **Preferences** — Formatting, naming, style, or tool choices the user expressed.
6. **Failure modes** — Approaches that failed, with what worked instead. For tool or script call failures, trace back to the information source that led to the error and route the fix there (e.g., clarify a reference file, update skill instructions, add missing documentation).
7. **Domain knowledge** — Facts or conventions Claude needed but did not have.
8. **Improvement opportunities** — Out-of-scope improvements noticed during work: code that could be refactored, missing tests, performance issues, readability concerns, or feature ideas that were intentionally skipped to stay focused. **Skipped findings count here**: when code simplification or code review identified a genuine improvement or issue but it was skipped for this session, route it as a project improvement so it isn't lost.
9. **Trusted reviewer feedback** — Human PR review comments that reveal project conventions, patterns, or corrections. Trusted reviewers are repo collaborators with `admin` or `maintain` roles (determine via `gh api repos/{owner}/{repo}/collaborators --jq '.[] | select(.role_name == "admin" or .role_name == "maintain") | .login'`). Their feedback takes precedence over other reviewers and AI bots when there are contradictions.

After scanning, read the SKILL.md of every skill a candidate lesson could touch: the session skills, plus any skill whose description from Step 1 covers a lesson's domain. This gives Step 3 and Step 4 the context for filtering and routing.

## Step 3: Filter

Keep only lessons that are:
- **Stable** — likely to remain true across future sessions
- **Non-obvious** — Claude would not already know this
- **Actionable** — can be expressed as a rule or instruction
- **Not already covered** — no rule in the files read in Steps 1 and 2, in the `references/` and other supporting files of the skills read in Step 2, or in the project's own knowledge stores already covers it, even as a special case. A lesson drawn from one incident is covered when an existing general rule, followed, would have prevented that incident; a workflow is covered only when an existing skill already encodes its steps. Search those sources for each candidate's keywords, then judge coverage by meaning, since a general rule rarely shares an incident's wording. When the covering rule was in context during the incident and still read past, because its wording, scope, or placement let the incident through, keep the lesson as a revision of that rule in place, adding no new rule; otherwise discard it. A lesson covered only in an unrelated subtree's CLAUDE.md/AGENTS.md still counts as uncovered for the subtree it actually applies to.
- **Still a concern** — the issue is not already fixed by changes made in this session. If a bug was found and fixed, or a missing feature was added, future sessions will see the corrected code — they don't need a reminder about the old problem. **Exception: successful workflows and procedures are not "resolved" — they're skill candidates precisely because they worked and will need to be repeated.** When sweeping past sessions, judge this against the current state of the code and docs rather than against this session's changes.

Discard anything session-specific, speculative, one-off, or already resolved by code changes in this session (but not successful workflows — see exception above). If no lessons survive filtering, tell the user and stop.

## Step 4: Route Each Lesson

Assign each surviving lesson to exactly one destination.

**Revisions:** A lesson Step 3 kept as a revision routes to the destination that holds the rule it revises, as an update-in-place, ahead of the skill-first rule and the table; only the package-managed skills rule outranks it. When the rule lives in a source that is not a routing destination, route the lesson by the rules below like any other. When the rule lives in a turbo skill, its destination is **Existing turbo skill**, or **Existing user/project skill** under Step 1's turbo repo exception: the revision goes where any other lesson for that skill goes, never into the plugin's copy.

**Skill-first rule (mandatory):** Before consulting the table below, check whether the lesson corrects, refines, or adds a guardrail to any existing skill's behavior — turbo or user/project. This includes lessons about skipping steps, wrong defaults, missing edge cases, or any "don't do X when running /skill-name" correction. If yes, route to that skill. Do not route skill corrections to auto memory or CLAUDE.md — they belong in the skill they correct. This rule is not a preference; it is a hard constraint that takes precedence over the table rows below.

**Package-managed skills (mandatory):** A skill Step 1 classified as package-managed from the lock file routes its lesson straight to **Auto memory**, recording the skill it applies to, with no question put to the user: the lock file has already settled ownership. A skill under `~/.claude/skills/` that Step 1 left ownership-unresolved may still be one a package manager replaces wholesale on its next update, discarding any edit made here. Before routing a lesson to such a skill, say plainly that an edit to it survives only while the user maintains it themselves. Then use `AskUserQuestion` to ask which is the case, with the options phrased as that effect: edits to this skill stick, or the next update overwrites them. Route the lesson to **Auto memory** when a package manager maintains the skill, recording the skill it applies to so the knowledge survives the next update. For those skills this rule outranks the skill-first rule, the routing table rows, and the tiebreakers below.

| Destination | Criteria |
|---|---|
| **Project backlog** | Actionable improvement to existing **code**: refactoring, performance, reliability, readability, testing, or DX. Not for documentation fixes — factual errors in CLAUDE.md belong in the **Project CLAUDE.md / AGENTS.md** row. Route to `.turbo/backlog.md` via the `/backlog` skill. |
| **Auto memory** | Discovered knowledge with no skill home: API quirks, debugging workarounds, compiler gotchas, tool pitfalls, user preferences. Must not overlap with any existing skill's domain — if it does, route to the skill instead (see skill-first rule above). A lesson the package-managed skills rule sends here stays here, whatever domain it overlaps, as does a turbo skill lesson the user declines to propose upstream in Step 6. |
| **Project CLAUDE.md / AGENTS.md** | Intentional project decisions: conventions, architecture, stack choices, build setup, module boundaries. Also factual corrections to CLAUDE.md content (wrong commands, outdated paths, incorrect conventions) — fix these directly, do not defer to Project backlog. When the lesson applies only to one subtree, route it to the nearest enclosing CLAUDE.md/AGENTS.md; reserve the root file for project-wide decisions. |
| **Existing user/project skill** | Lesson would improve a skill's instructions, supporting files, or reference materials, add a missing edge case, correct its workflow, or refine its trigger conditions. Route to any skill whose *domain* covers the lesson — not just the skill worked on in this session. Changes go to the skill file directly. No contribution flow. |
| **New skill** | A cohesive body of knowledge emerged that deserves its own on-demand context. The test: would this knowledge be too large for a CLAUDE.md section, and should it only be loaded when relevant? See the skill categories table below. |
| **Existing turbo skill** | Same criteria as **Existing user/project skill** above, but for turbo skills. **Before routing here, apply Step 1's verification rule; when the skill's load did not come from the Turbo plugin's skills folder, route to the Existing user/project skill destination instead, subject to the package-managed skills rule above.** Changes are not applied in this session: they go into a handoff in the Turbo checkout when `checkout` is set, and are offered upstream otherwise (see Step 6). |
| **No destination** | Does not clearly fit any destination. Drop it. Routing a weak lesson is worse than losing it. |

**Skill categories:**

| Category | What it encodes | Example |
|---|---|---|
| Domain expertise | Best practices, patterns, API preferences | SwiftUI expert, Core Data guide |
| Tool/Service integration | API references, operations, ID formats | Paddle, Stripe, Keycloak |
| Decision framework | Judgment criteria, confidence levels, triage | Evaluate findings, performance audit |
| Content template | Writing conventions, tone, structure | Drafting, blog post, changelog |
| Knowledge/Research | Information discovery, schema definitions | Knowledge base, research process |
| Orchestrated workflow | Stateful multi-step procedures | Process ticket, process income |

**Splitting heuristic:** When a session creates scripts or multi-step procedures, split the lesson: a brief pointer goes to CLAUDE.md (script names, purpose), and the full workflow goes to a skill. Don't collapse them into a single CLAUDE.md entry.

**Tiebreakers (in priority order):**
1. **Skill correction → skill (hard rule).** Any lesson that corrects, constrains, or refines a skill's behavior MUST route to that skill. Never to auto memory, never to CLAUDE.md. This is the highest-priority routing rule, ahead of every tiebreaker below and yielding only to the package-managed skills rule above.
2. **Turbo skill vs. CLAUDE.md → always the turbo skill.** Broader impact (benefits all turbo users), better scoped, loaded only when relevant.
3. **Skill vs. CLAUDE.md → always the skill.** Skills are more discoverable, better scoped, and loaded only when relevant.
4. **Skill vs. auto memory → always the skill.** If a lesson falls within the domain of an existing skill, it goes to the skill. Auto memory is for knowledge that has no skill home, and for the domain of a skill a package manager maintains.
5. **CLAUDE.md vs. auto memory** — intentional decisions go to CLAUDE.md. Discovered knowledge (gotchas, workarounds, quirks) goes to auto memory.
6. **Lesson vs. improvement** — if the item is *knowledge to remember*, it's a lesson. If it's *work to do later*, it's an improvement. They don't compete — the same session can produce both.

## Step 5: Present Routing Plan

Output a table as text before making any changes:

```
| # | Lesson | Destination | Action |
|---|--------|-------------|--------|
| 1 | Always use X for... | Project AGENTS.md | Append to ## Conventions |
| 2 | The /pr skill should... | ~/.claude/skills/pr | Update references/create.md Phase 2 |
| 3 | Multi-step deploy workflow | New project skill | Create new skill |
| 4 | User prefers short commit msgs | Auto memory | Update <resolved memory target> |
| 5 | /finalize should skip step 3 when... | Turbo skill: finalize | Handoff to Turbo checkout |
```

For each lesson, show: concise summary, exact target file/skill, and whether it's an append, update-in-place, or new creation. For Auto memory, name the resolved project-memory target so the approval covers the durable write at that path. Turbo skill lessons show `Handoff to Turbo checkout` as the action when `checkout` is set, and `Propose upstream` otherwise, naming the Auto memory target that receives the lesson if the user declines to propose it.

Then use `AskUserQuestion` with these options: **Approve** or **Reject**.

## Step 6: Execute

Apply approved changes in order:

1. **Backlog** — For items routed to the project backlog, run the `/backlog` skill with the summary, location, and rationale for each.
2. **Updates to auto memory** — Read the target, find the right section, append or update in place, following the memory system conventions from the system prompt.
3. **Updates to CLAUDE.md / AGENTS.md** — Read the target file selected in Step 4 (the root file or a nested subtree file), find the right section, append or update in place. Match the tone and format already present.
4. **Updates to user/project skills** — Run the `/write-skill` skill to apply changes to any file inside the skill directory (SKILL.md, references, scripts, assets).
5. **New skills** — Run the `/write-skill` skill for each new skill. Provide the trigger conditions and relevant context from the session.
6. **Turbo skill lessons** — Edit no file in the Turbo plugin's skills folder: a plugin update replaces it.
   - **When `checkout` is set:** write every lesson routed to a turbo skill into one handoff file with the Write tool, at `<checkout>/.turbo/handoff/<YYYY-MM-DD>-turbo-lessons-<slug>.md`, where `<slug>` names the lessons' common subject. When that path already exists, append `-2`, `-3`, and so on to the slug until it is free. State the resolved path before writing. Record for each lesson:
     - Which turbo skill it targets, as a path under `claude/skills/<name>/` in the checkout
     - The change to make and where in the file it belongs
     - The session evidence that motivated it (the correction, failure, or repeated guidance)
   - **When `checkout` is unset:** use `AskUserQuestion` to ask whether to propose each turbo skill lesson upstream, since it could benefit other users. Ask one question per lesson, at most four per call. Write each lesson the user leaves out to **Auto memory** as in item 2, recording the turbo skill it applies to. Then, when any lesson remains to propose, run the `/contribute` skill once for all of them, passing each lesson's target skill, change, and evidence.

Then use the TaskList tool and proceed to any remaining task.

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
- For files that live in the repo (CLAUDE.md / AGENTS.md and project skills): name only mechanisms that live in the repo too; describe an installed skill's behavior generically
