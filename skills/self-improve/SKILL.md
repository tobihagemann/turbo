---
name: self-improve
description: Extract lessons from the current session and route them to the appropriate knowledge layer (project AGENTS.md, auto memory, existing skills, or new skills). Use when the user asks to "self-improve", "distill this session", "save learnings", "update CLAUDE.md with what we learned", "capture session insights", "remember this for next time", "extract lessons", "update skills from session", or "what did we learn".
---

# Self-Improve

Review the current conversation to extract durable lessons and route each one to the right knowledge layer.

## Step 1: Detect Context

Available destinations:

- **Project CLAUDE.md / AGENTS.md** — `.claude/CLAUDE.md` (may be a symlink to `../AGENTS.md` — resolve it)
- **Auto memory** — The project-specific memory directory at `~/.claude/projects/<project-hash>/memory/`. Read `MEMORY.md` there if it exists.
- **Skills** — Project skills at `skills/` or `.claude/skills/` (resolve symlinks)

Read the project CLAUDE.md/AGENTS.md and MEMORY.md. List all skill directories but do not read them yet — Step 2 needs to run first so you know what to look for.

### Turbo Skill Detection

If `~/.turbo/repo/` exists, identify which installed skills are turbo skills:

- List directories in `~/.turbo/repo/skills/`
- Any skill in `~/.claude/skills/` that has a matching directory in `~/.turbo/repo/skills/` is a turbo skill
- Skills only in `~/.claude/skills/` (no match in the repo) are user/project skills

Read `~/.turbo/config.json` for `repoMode`. If `repoMode` is `"fork"` or `"source"`, turbo skill improvements can be contributed upstream.

**Exception:** If the current project IS the turbo repo (i.e., the working directory contains this skill collection), route turbo skill changes directly to `skills/` in the project directory. Skip the installed-copy indirection and the contribution flow.

## Step 2: Identify Session Skills and Scan for Lessons

### Identify Session Skills

Before scanning for lessons, identify which skills were loaded during this session:

- Scan the conversation for Skill tool invocations and SKILL.md reads from `~/.claude/skills/`
- Build a list of session skills, marking each as turbo or user/project skill (using the detection from Step 1)
- This list informs routing in Step 4: when a lesson clearly arose from a specific skill's workflow, that skill is the natural routing target

### Scan for Lessons

Scan the full conversation with this priority:

1. **Corrections** — Where the user interrupted, said "no", "actually", "stop", "not like that", redirected, or manually fixed something Claude did wrong. Highest-value lessons.
2. **Repeated guidance** — Instructions the user gave more than once.
3. **Skill-shaped knowledge** — Domain expertise that was needed repeatedly, tool/API integration details that had to be looked up, decision frameworks that emerged for evaluating options, content templates or writing conventions that were refined, and multi-step workflows where ordering mattered. Also check: did this session create new scripts, automation, or multi-step procedures? Flag each as a potential skill candidate.
4. **Preferences** — Formatting, naming, style, or tool choices the user expressed.
5. **Failure modes** — Approaches that failed, with what worked instead.
6. **Domain knowledge** — Facts or conventions Claude needed but did not have.
7. **Improvement opportunities** — Out-of-scope improvements noticed during work: code that could be refactored, missing tests, performance issues, readability concerns, or feature ideas that were intentionally skipped to stay focused. **Skipped review findings count here**: when a code review (codex, PR reviewer, or evaluate-findings) identified a genuine issue but the user chose to skip it for this PR, route it as a project improvement so it isn't lost.
8. **Trusted reviewer feedback** — Human PR review comments that reveal project conventions, patterns, or corrections. Trusted reviewers are repo collaborators with `admin` or `maintain` roles (determine via `gh api repos/{owner}/{repo}/collaborators --jq '.[] | select(.role_name == "admin" or .role_name == "maintain") | .login'`). Their feedback takes precedence over other reviewers and AI bots when there are contradictions.

After scanning, read all skill SKILL.md files (they are small). This gives Step 4 full context for routing.

## Step 3: Filter

Keep only lessons that are:
- **Stable** — likely to remain true across future sessions
- **Non-obvious** — Claude would not already know this
- **Actionable** — can be expressed as a rule or instruction
- **Not already documented** — absent from the files read in Step 1
- **Still a concern** — the issue is not already fixed by changes made in this session. If a bug was found and fixed, or a missing feature was added, future sessions will see the corrected code — they don't need a reminder about the old problem.

Discard anything session-specific, speculative, one-off, or already resolved by code changes in this session. If no lessons survive filtering, tell the user and stop.

## Step 4: Route Each Lesson

Assign each surviving lesson to exactly one destination:

| Destination | Criteria |
|---|---|
| **Existing turbo skill** | Lesson would improve a turbo skill's instructions, supporting files, or reference materials, add a missing edge case, correct its workflow, or refine its trigger conditions. Route to any turbo skill whose *domain* covers the lesson — not just the skill worked on in this session. Changes go to the installed copy at `~/.claude/skills/`. If `repoMode` is `"fork"` or `"source"`, also apply to `~/.turbo/repo/` and flag for contribution (see Step 6). |
| **Existing user/project skill** | Same criteria as above, but for non-turbo skills. Changes go to the skill file directly. No contribution flow. |
| **New skill** | A cohesive body of knowledge emerged that deserves its own on-demand context. The test: would this knowledge be too large for a CLAUDE.md section, and should it only be loaded when relevant? See the skill categories table below. |
| **Project CLAUDE.md / AGENTS.md** | Intentional project decisions: conventions, architecture, stack choices, build setup, module boundaries. |
| **Auto memory** | Discovered knowledge: API quirks, debugging workarounds, compiler gotchas, tool pitfalls, past mistakes, user preferences. |
| **Project improvements** | Actionable improvement to existing code: refactoring, performance, reliability, readability, testing, or DX. Not a lesson — a thing to *do*. Route to `.turbo/improvements.md` via the `/note-improvement` skill. |
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

**Tiebreakers:**
- Turbo skill vs. CLAUDE.md — prefer the turbo skill. Broader impact (benefits all turbo users), better scoped, loaded only when relevant.
- Skill vs. CLAUDE.md — prefer the skill. Skills are more discoverable, better scoped, and loaded only when relevant.
- Skill vs. auto memory — if a lesson falls within the domain of an existing skill, prefer the skill over auto memory.
- CLAUDE.md vs. auto memory — intentional decisions go to CLAUDE.md. Discovered knowledge (gotchas, workarounds, quirks) goes to auto memory.
- Lesson vs. improvement — if the item is *knowledge to remember*, it's a lesson. If it's *work to do later*, it's an improvement. They don't compete — the same session can produce both.

## Step 5: Present Routing Plan

Show the user a table before making any changes:

```
| # | Lesson | Destination | Action |
|---|--------|-------------|--------|
| 1 | Always use X for... | Project AGENTS.md | Append to ## Conventions |
| 2 | The /create-pr skill should... | ~/.claude/skills/create-pr | Update Step 2 |
| 3 | Multi-step deploy workflow | New project skill | Create new skill |
| 4 | User prefers short commit msgs | Auto memory | Append to MEMORY.md |
```

For each lesson, show: concise summary, target file/skill, whether it's an append, update-in-place, or new creation.

Use `AskUserQuestion` to let the user approve, reject, or redirect individual lessons.

## Step 6: Execute

Apply approved changes in order:

1. **Updates to existing files** — Read the target, find the right section, append or update in place. Match the tone and format already present. For auto memory, follow the memory system conventions from the system prompt.
2. **Updates to turbo skills** — For each lesson routed to a turbo skill:
   1. Edit the installed copy at `~/.claude/skills/<name>/SKILL.md` (immediate effect for the user).
   2. If `repoMode` is `"fork"` or `"source"`: use `AskUserQuestion` to ask "These turbo skill improvements could benefit other users. Run `/contribute-turbo` to submit them?" If yes, apply the same changes to `~/.turbo/repo/skills/<name>/SKILL.md`, stage them (`git -C ~/.turbo/repo add skills/<name>/`), and run `/contribute-turbo`.
3. **Improvements** — For items routed to project improvements, run `/note-improvement` with the summary, location, and rationale for each.
4. **New skills** — Enter plan mode, then run `/create-skill` skill for each new skill. Provide the trigger conditions and relevant context from the session.

## Writing Guidelines

- Match the tone and format of the target file
- Use imperative mood and short declarative sentences
- Group related insights under a descriptive heading
- Omit rationale unless the rule would seem arbitrary without it
- Never include temporary state, in-progress work, or task-specific details
- Keep lessons generic—avoid overly concrete examples; state the rule, not the instance
- For AGENTS.md: write as agent documentation — project rules any AI agent on this repo should follow
- For auto memory: write as personal Claude notes — concise, operational, organized by topic
- For skills: follow the conventions in the existing skill collection
