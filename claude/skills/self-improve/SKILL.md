---
name: self-improve
description: "Extract lessons from the current session, or sweep the project's past sessions when asked, and route them to the appropriate knowledge layer (project AGENTS.md, auto memory, existing skills, or new skills). Use when the user asks to \"self-improve\", \"distill this session\", \"distill past sessions\", \"sweep past sessions\", \"extract lessons from all sessions\", \"save learnings\", \"update CLAUDE.md with what we learned\", \"capture session insights\", \"remember this for next time\", \"extract lessons\", \"update skills from session\", or \"what did we learn\"."
---

# Self-Improve

Review the current conversation, or the project's past sessions when asked, to extract durable lessons and route each one to the right knowledge layer.

## Step 1: Detect Context

Available destinations:

- **Project CLAUDE.md / AGENTS.md** — The root `.claude/CLAUDE.md` (may be a symlink to `../AGENTS.md` — resolve it), plus any nested `CLAUDE.md` / `AGENTS.md` files in subdirectories. Claude Code loads a subdirectory's file on demand when files in that subtree are accessed, so a lesson scoped to one subtree belongs in the nearest enclosing file, with the root reserved for project-wide rules.
- **Auto memory** — The project-specific memory directory named by the active harness. An effective `autoMemoryDirectory` setting overrides its location; otherwise it normally lives at `<Claude config home>/projects/<encoded project root>/memory/`, where the config home is `CLAUDE_CONFIG_DIR` when set and `~/.claude` otherwise. The key replaces every character outside `A-Za-z0-9` with `-`, and long keys may be truncated and hashed, so prefer the exact harness-provided path over recomputing it. List the directory and read `MEMORY.md` if it exists.
- **Skills** — Project skills at `skills/` or `.claude/skills/` (resolve symlinks)

Discover the project CLAUDE.md/AGENTS.md files (the root file and any nested ones in subdirectories) and read them, then read MEMORY.md. When those files point at a knowledge base the repo maintains, read its index too; it is a documentation source for Step 3 rather than a routing destination. List all skill directories but do not read them yet — Step 2 needs to run first so you know what to look for.

### Skill Ownership Detection

Classify every skill this session touched:

- Skills that live in the project are user/project skills
- If `~/.turbo/repo/` exists, list directories in `~/.turbo/repo/claude/skills/`; any skill in `~/.claude/skills/` with a matching directory there is a turbo skill
- Every other skill in `~/.claude/skills/` is either one the user maintains or one a package manager installed and replaces on its next update. Nothing in the directory distinguishes the two, so carry its ownership as unresolved into Step 4

**Verification rule (mandatory before routing in Step 4):** For every candidate skill that is about to be routed as turbo, confirm with a fresh `test -d ~/.turbo/repo/claude/skills/<name>` check that the skill actually lives in the turbo repo. Do not rely on remembered listings from earlier in the session, filename hits in grep output, or assumptions based on where a SKILL.md was read from. A miss here mislabels a user/project skill as turbo, triggers the contribution flow unnecessarily, and can introduce session-specific content into a shared skill — so the check is not optional.

**Exception:** If the current project IS the turbo repo (i.e., the working directory contains this skill collection), route turbo skill lessons through the **Existing user/project skill** destination in Step 4 — edits go directly to `claude/skills/<name>/` in the project, with no installed-copy indirection and no contribution flow.

## Step 2: Gather Session Evidence and Scan for Lessons

### Recover Pre-Compaction Evidence

**Skip** when the conversation is visible in full from the user's own first message.

When it starts from a summary of earlier work instead, recover the compacted turns from the on-disk transcript. Spawn a single subagent (`model: "opus"`, no `name`). Wait for it to report before continuing; do not relaunch it if it has not yet reported. The subagent's prompt must include:

1. The absolute path of the project root
2. A distinctive phrase from the visible conversation, for confirming which transcript belongs to this session
3. An instruction to read [references/transcript-miner.md](references/transcript-miner.md) for transcript location, extraction, and output format

Treat the returned items as raw evidence for the scan below.

### Sweep Past Sessions

**Run** when asked to distill sessions beyond the current one. **Skip** otherwise.

Propose a cutoff first: take the newest modification time in the memory directory from Step 1, state it, then use `AskUserQuestion` to confirm sweeping from it or sweeping the whole history. A memory file's timestamp records a write rather than a completed sweep, so it bounds the work without settling what a previous run covered. When the directory is absent or empty, sweep the whole history without asking.

Spawn a single subagent (`model: "opus"`, no `name`). Wait for it to report before continuing; do not relaunch it if it has not yet reported. The subagent's prompt must include:

1. The absolute path of the project root
2. The confirmed cutoff as an ISO-8601 timestamp, or that there is none
3. An instruction to read [references/transcript-miner.md](references/transcript-miner.md) and follow its sweep process

Treat the returned items as raw evidence for the scan below.

### Identify Session Skills

Before scanning for lessons, identify which skills were loaded during this session:

- Scan the conversation for Skill tool invocations and SKILL.md reads from `~/.claude/skills/`
- Build a list of session skills, marking each as turbo, user/project, or ownership-unresolved (using the detection from Step 1)
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

After scanning, read all skill SKILL.md files (they are small). This gives Step 4 full context for routing.

## Step 3: Filter

Keep only lessons that are:
- **Stable** — likely to remain true across future sessions
- **Non-obvious** — Claude would not already know this
- **Actionable** — can be expressed as a rule or instruction
- **Not already documented** — absent from the files read in Steps 1 and 2, from each skill's `references/` and other supporting files, and from the project's own knowledge stores. Search all of those for each candidate's keywords rather than assuming. A lesson documented only in an unrelated subtree's CLAUDE.md/AGENTS.md still counts as undocumented for the subtree it actually applies to.
- **Still a concern** — the issue is not already fixed by changes made in this session. If a bug was found and fixed, or a missing feature was added, future sessions will see the corrected code — they don't need a reminder about the old problem. **Exception: successful workflows and procedures are not "resolved" — they're skill candidates precisely because they worked and will need to be repeated.** When sweeping past sessions, judge this against the current state of the code and docs rather than against this session's changes.

Discard anything session-specific, speculative, one-off, or already resolved by code changes in this session (but not successful workflows — see exception above). If no lessons survive filtering, tell the user and stop.

## Step 4: Route Each Lesson

Assign each surviving lesson to exactly one destination.

**Skill-first rule (mandatory):** Before consulting the table below, check whether the lesson corrects, refines, or adds a guardrail to any existing skill's behavior — turbo or user/project. This includes lessons about skipping steps, wrong defaults, missing edge cases, or any "don't do X when running /skill-name" correction. If yes, route to that skill. Do not route skill corrections to auto memory or CLAUDE.md — they belong in the skill they correct. This rule is not a preference; it is a hard constraint that takes precedence over the table rows below.

**Package-managed skills (mandatory):** A skill under `~/.claude/skills/` that Step 1 left ownership-unresolved may be one a package manager replaces wholesale on its next update, discarding any edit made here. Before routing a lesson to such a skill, say plainly that an edit to it survives only while the user maintains it themselves. Then use `AskUserQuestion` to ask which is the case, with the options phrased as that effect: edits to this skill stick, or the next update overwrites them. Route the lesson to **Auto memory** when a package manager maintains the skill, recording the skill it applies to so the knowledge survives the next update. For those skills this rule outranks the skill-first rule, the routing table rows, and the tiebreakers below.

| Destination | Criteria |
|---|---|
| **Project improvements** | Actionable improvement to existing **code**: refactoring, performance, reliability, readability, testing, or DX. Not for documentation fixes — factual errors in CLAUDE.md belong in the **Project CLAUDE.md / AGENTS.md** row. Route to `.turbo/improvements.md` via the `/note-improvement` skill. |
| **Auto memory** | Discovered knowledge with no skill home: API quirks, debugging workarounds, compiler gotchas, tool pitfalls, user preferences. Must not overlap with any existing skill's domain — if it does, route to the skill instead (see skill-first rule above). A lesson the package-managed skills rule sends here stays here, whatever domain it overlaps. |
| **Project CLAUDE.md / AGENTS.md** | Intentional project decisions: conventions, architecture, stack choices, build setup, module boundaries. Also factual corrections to CLAUDE.md content (wrong commands, outdated paths, incorrect conventions) — fix these directly, do not defer to Project improvements. When the lesson applies only to one subtree, route it to the nearest enclosing CLAUDE.md/AGENTS.md; reserve the root file for project-wide decisions. |
| **Existing user/project skill** | Lesson would improve a skill's instructions, supporting files, or reference materials, add a missing edge case, correct its workflow, or refine its trigger conditions. Route to any skill whose *domain* covers the lesson — not just the skill worked on in this session. Changes go to the skill file directly. No contribution flow. |
| **New skill** | A cohesive body of knowledge emerged that deserves its own on-demand context. The test: would this knowledge be too large for a CLAUDE.md section, and should it only be loaded when relevant? See the skill categories table below. |
| **Existing turbo skill** | Same criteria as **Existing user/project skill** above, but for turbo skills. **Before routing here, run `test -d ~/.turbo/repo/claude/skills/<name>`; if the directory does not exist, route to the Existing user/project skill destination instead, subject to the package-managed skills rule above.** Changes go to the installed copy at `~/.claude/skills/`, and are flagged for contribution (see Step 6). |
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
4. **Skill vs. auto memory → always the skill.** If a lesson falls within the domain of an existing skill, it goes to the skill. Auto memory is for knowledge that has no skill home, and for the domain of an ownership-unresolved skill a package manager maintains.
5. **CLAUDE.md vs. auto memory** — intentional decisions go to CLAUDE.md. Discovered knowledge (gotchas, workarounds, quirks) goes to auto memory.
6. **Lesson vs. improvement** — if the item is *knowledge to remember*, it's a lesson. If it's *work to do later*, it's an improvement. They don't compete — the same session can produce both.

## Step 5: Present Routing Plan

Output a table as text before making any changes:

```
| # | Lesson | Destination | Action |
|---|--------|-------------|--------|
| 1 | Always use X for... | Project AGENTS.md | Append to ## Conventions |
| 2 | The /create-pr skill should... | ~/.claude/skills/create-pr | Update Step 2 |
| 3 | Multi-step deploy workflow | New project skill | Create new skill |
| 4 | User prefers short commit msgs | Auto memory | Update <resolved memory target> |
```

For each lesson, show: concise summary, exact target file/skill, and whether it's an append, update-in-place, or new creation. For Auto memory, name the resolved project-memory target so the approval covers the durable write at that path.

Then use `AskUserQuestion` with these options: **Approve** or **Reject**.

## Step 6: Execute

Apply approved changes in order:

1. **Improvements** — For items routed to project improvements, run the `/note-improvement` skill with the summary, location, and rationale for each.
2. **Updates to auto memory** — Read the target, find the right section, append or update in place, following the memory system conventions from the system prompt.
3. **Updates to CLAUDE.md / AGENTS.md** — Read the target file selected in Step 4 (the root file or a nested subtree file), find the right section, append or update in place. Match the tone and format already present.
4. **Updates to user/project skills** — Run the `/create-skill` skill to apply changes to any file inside the skill directory (SKILL.md, references, scripts, assets).
5. **New skills** — Run the `/create-skill` skill for each new skill. Provide the trigger conditions and relevant context from the session.
6. **Updates to turbo skills** — For each lesson routed to a turbo skill:
   1. Read `~/.turbo/repo/claude/SKILL-CONVENTIONS.md` so turbo-specific conventions are in context before any editing.
   2. Run the `/create-skill` skill to update the installed copy at `~/.claude/skills/<name>/`.

   Once every turbo skill edit is in place and reviewed, use `AskUserQuestion` to ask "These turbo skill improvements could benefit other users. Propose them upstream?" When the user confirms, run the `/contribute-turbo` skill once for all of them.

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
