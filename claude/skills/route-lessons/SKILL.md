---
name: route-lessons
description: "Route lessons to instructions, auto memory, skills, the backlog, or a Turbo handoff after approval. Use when asked to \"route lessons\" or \"where should this lesson go\"."
---

# Route Lessons

Route each candidate lesson to the knowledge layer it belongs in.

Take the candidates passed in, or the lessons the user names. Each carries the lesson, the evidence behind it, its origin (the current session, a past session, or a file such as a memory note), the skill it arose from when there is one, and any reason the user did not state. When none were passed in and the user names none, say so and continue with Step 7.

## Task Tracking

Use `TaskCreate` to create a task for each step:

1. Detect context
2. Read the skills the lessons touch
3. Filter
4. Route each lesson
5. Present routing plan
6. Execute
7. Report outcomes

## Step 1: Detect Context

Available destinations:

- **Project CLAUDE.md / AGENTS.md** — The root `.claude/CLAUDE.md` (may be a symlink to `../AGENTS.md` — resolve it), plus any nested `CLAUDE.md` / `AGENTS.md` files in subdirectories.
- **Auto memory** — The project-specific memory directory named by the active harness. An effective `autoMemoryDirectory` setting overrides its location; otherwise it normally lives at `<Claude config home>/projects/<encoded project root>/memory/`, where the config home is `CLAUDE_CONFIG_DIR` when set and `~/.claude` otherwise. The key replaces every character outside `A-Za-z0-9` with `-`, and long keys may be truncated and hashed, so prefer the exact harness-provided path over recomputing it. List the directory and read `MEMORY.md` if it exists.
- **Skills** — Project skills at `skills/` or `.claude/skills/` (resolve symlinks)

Discover the project CLAUDE.md/AGENTS.md files (the root file and any nested ones in subdirectories) and read them, then read MEMORY.md. When those files point at a knowledge base the repo maintains, read its index too; it is a documentation source for Step 3, and a routing destination only when the CLAUDE.md/AGENTS.md files name it one. Also read any document of rules for one area that those files tell agents to read before working in that area; Step 4 routes lessons to it. Note each other destination the CLAUDE.md/AGENTS.md files name for a kind of knowledge, outside skills and instruction files, with the process they give for writing to it and the subtree of the file that names it; Step 4 routes lessons to it too. List all skill directories with the `description` frontmatter of each SKILL.md, but leave the bodies unread until Step 2.

Read the top-level `checkout` key from `~/.turbo/config.json` when the file exists. When it names a directory holding `claude/skills/`, that directory is the user's Turbo clone or fork. Treat any other value as unset, and say so in the Step 5 routing plan.

### Skill Ownership Detection

When `${CLAUDE_SKILL_DIR}/../../.claude-plugin/plugin.json` exists and names the plugin `turbo`, the Turbo plugin's skills folder is `${CLAUDE_SKILL_DIR}/..`. Otherwise this skill runs from an override or a leftover copy, no folder is known to be Turbo's, and only a `turbo:` invocation marks a turbo skill. Scan the conversation for Skill tool invocations, `turbo:`-prefixed ones included, the base directory each skill load reported, and SKILL.md reads from `~/.claude/skills/` or the Turbo plugin's skills folder. Classify every skill a candidate lesson could touch, meaning the skill it arose from and any skill whose description covers its domain, by where it was loaded from, never by its name alone:

- Skills that live in the project are user/project skills
- A skill is a turbo skill when it ran as `turbo:<name>`, or when the base directory its load reported, or the path its `SKILL.md` was read from, lies in the Turbo plugin's skills folder. A same-named skill loaded from `~/.claude/skills/` or the project overrides the Turbo skill, and its lessons go to that override. A skill this session did not load is a turbo skill when `<Turbo plugin's skills folder>/<name>/SKILL.md` exists and no skill of that name exists in `~/.claude/skills/` or the project
- For every skill in `~/.claude/skills/` not classified as turbo, overrides included, read [references/package-managed-skills.md](references/package-managed-skills.md) once and apply its Classify the Skill section to each
- A skill that no bullet above classifies is ownership-unresolved when the session's record shows the folder it was loaded from, and package-managed otherwise

**Exception:** If the current project IS the turbo repo (i.e., the working directory contains this skill collection), route turbo skill lessons through the **Existing user/project skill** destination in Step 4 — edits go directly to `claude/skills/<name>/` in the project, with no handoff and no contribution flow.

**Verification rule (mandatory before routing in Step 4):** For every candidate skill that is about to be routed as turbo and ran in this session, find the load that ran it in this session's record: a `turbo:` Skill tool invocation, the base directory a load reported, or a `SKILL.md` read. Confirm that the load came from the Turbo plugin's skills folder. For a candidate that did not run, confirm that `<Turbo plugin's skills folder>/<name>/SKILL.md` exists and that no skill of that name exists in `~/.claude/skills/` or the project. Do not rely on a name match, remembered listings from earlier in the session, or filename hits in grep output: a personal or project skill of the same name is an override, not the turbo skill. Classify a candidate that fails this rule again by the bullets above. The rule applies under the exception above too.

## Step 2: Read the Skills the Lessons Touch

Read the SKILL.md of every skill Step 1 classified.

## Step 3: Filter

Keep only lessons that are:
- **Stable** — likely to remain true across future sessions
- **Non-obvious** — Claude would not already know this
- **Actionable** — can be expressed as a rule or instruction
- **Not already covered** — no rule in the files read in Steps 1 and 2, in the `references/` and other supporting files of the skills read in Step 2, or in the project's own knowledge stores already covers it, even as a special case. The lesson's own origin counts as no coverage. Search those sources for each candidate's keywords, then judge coverage by meaning rather than by shared wording:
  - A lesson drawn from one incident is covered when an existing general rule, followed, would have prevented that incident. A workflow is covered only when an existing skill already encodes its steps.
  - When the covering rule was in context during the incident and still read past, because its wording, scope, or placement let the incident through, keep the lesson as a revision of that rule in place, adding no new rule. Otherwise discard it. A candidate whose origin is a file has no incident: discard it when covered.
  - A prose rule does not cover a rule a tool can decide from the code alone. When the incident broke such a rule, keep the lesson as a new lesson rather than a revision.
  - A lesson covered only in an unrelated subtree's CLAUDE.md/AGENTS.md still counts as uncovered for the subtree it actually applies to.
- **Still a concern** — the issue is not already fixed in the current code and docs, such as a bug that was since fixed or a missing feature that was since added. **Exception: a successful workflow or procedure is not "resolved"; it stays a skill candidate.**

Discard anything session-specific, speculative, one-off, or already resolved (but not successful workflows — see exception above). When no lessons survive filtering, say so and continue with Step 7.

## Step 4: Route Each Lesson

Assign each surviving lesson to exactly one destination. Apply the routing rules in this order. The first that applies to a lesson decides its destination:

1. **Package-managed skills**
2. **Mechanical rules**
3. **Revisions**
4. **Skill-first rule**
5. **Project routing**
6. The destination table, with the **Tiebreakers** settling a lesson that fits more than one row

A lesson whose destination holds its origin needs no write: leave it out of Steps 5 and 6, and report it in Step 7 as kept where it is.

**Package-managed skills (mandatory):** A lesson for a skill Step 1 classified as package-managed or ownership-unresolved routes by the Route Its Lessons section of [references/package-managed-skills.md](references/package-managed-skills.md).

**Mechanical rules (mandatory):** Classify each lesson that states a rule for the project's code as mechanical or judgment. A mechanical rule is one a tool can decide from the code alone: a fixed pattern, a banned call, an import shape, a file-location rule. Route it to **Deterministic check** alone, writing it to no instruction file, memory, or skill. A rule that takes judgment to apply routes by the remaining rules like any other lesson.

**Revisions:** A lesson Step 3 kept as a revision routes to the destination that holds the rule it revises, as an update-in-place. When the rule lives in a source that is not a routing destination, route the lesson by the remaining rules like any other. When the rule lives in a turbo skill, its destination is **Existing turbo skill**, or **Existing user/project skill** under Step 1's turbo repo exception: the revision goes where any other lesson for that skill goes, never into the plugin's copy.

**Skill-first rule (mandatory):** Check whether the lesson corrects, refines, or adds a guardrail to any existing skill's behavior — turbo or user/project. This includes lessons about skipping steps, wrong defaults, missing edge cases, or any "don't do X when running /skill-name" correction. If yes, route to that skill. Do not route skill corrections to auto memory or CLAUDE.md.

**Project routing:** A lesson of a kind Step 1 noted a destination for, within the subtree of the file that names it, routes to **Project-named destination**.

| Destination | Criteria |
|---|---|
| **Project backlog** | Actionable improvement to existing **code**: refactoring, performance, reliability, readability, testing, or DX. Not for documentation fixes — factual errors in CLAUDE.md belong in the **Project CLAUDE.md / AGENTS.md** row. Route to `.turbo/backlog.md` via the `/backlog` skill. |
| **Deterministic check** | A mechanical rule for the project's code, or an existing check that nothing runs. The work is building the check or wiring it in: a rule in the linter the project already uses, a git hook, or a CI job, whichever its existing tooling makes cheapest. The work also clears the existing violations and makes the check block new occurrences, and a new check gets an error message that names the fix the lesson calls for. Route to `.turbo/backlog.md` via the `/backlog` skill. |
| **Auto memory** | Discovered knowledge with no skill home: API quirks, debugging workarounds, compiler gotchas, tool pitfalls, user preferences. Must not overlap with any existing skill's domain — if it does, route to the skill instead (see skill-first rule above). A lesson the package-managed skills rule sends here stays here, whatever domain it overlaps, as does a turbo skill lesson the user declines to propose upstream in Step 6. |
| **Project CLAUDE.md / AGENTS.md** | Intentional project decisions: conventions, architecture, stack choices, build setup, module boundaries. Also factual corrections to CLAUDE.md content (wrong commands, outdated paths, incorrect conventions) — fix these directly, do not defer to Project backlog. When the lesson applies only to one subtree, route it to the nearest enclosing CLAUDE.md/AGENTS.md; reserve the root file for project-wide decisions. When those files tell agents to read a document of rules for the lesson's area, write the lesson there under its matching section. |
| **Project-named destination** | A destination Step 1 noted for the lesson's kind of knowledge, such as a knowledge base. Write to it by the process the project's instruction files give. |
| **Existing user/project skill** | Lesson would improve a skill's instructions, supporting files, or reference materials, add a missing edge case, correct its workflow, or refine its trigger conditions. Route to any skill whose *domain* covers the lesson — not just the skill the lesson arose from. Changes go to the skill file directly. No contribution flow. |
| **New skill** | A cohesive body of knowledge emerged that deserves its own on-demand context. The test: would this knowledge be too large for a CLAUDE.md section, and should it only be loaded when relevant? |
| **Existing turbo skill** | Same criteria as **Existing user/project skill** above, but for turbo skills. **Before routing here, apply Step 1's verification rule; a skill it classifies as other than turbo routes to the Existing user/project skill destination instead, subject to the package-managed skills rule above.** Changes are not applied in this session: they go into a handoff in the Turbo checkout when `checkout` is set, and are offered upstream otherwise (see Step 6). |
| **No destination** | Does not clearly fit any destination. Drop it. |

**Splitting heuristic:** When a lesson establishes new scripts or a new multi-step procedure, split it: a brief pointer goes to CLAUDE.md (script names, purpose), and the full workflow goes to a skill. Don't collapse them into a single CLAUDE.md entry.

**Tiebreakers (in priority order):**
1. **Skill vs. CLAUDE.md → always the skill**, a turbo skill included.
2. **Skill vs. auto memory → always the skill.** If a lesson falls within the domain of an existing skill, it goes to the skill. Auto memory is for knowledge that has no skill home, and for the domain of a skill a package manager maintains.
3. **CLAUDE.md vs. auto memory** — intentional decisions go to CLAUDE.md. Discovered knowledge (gotchas, workarounds, quirks) goes to auto memory.
4. **Lesson vs. improvement** — if the item is *knowledge to remember*, it's a lesson. If it's *work to do later*, it's an improvement. They don't compete — the same session can produce both.

## Step 5: Present Routing Plan

**Skip** when no lesson needs a write, and continue with Step 7.

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

For each lesson, show: concise summary, exact target file/skill, and whether it's an append, update-in-place, or new creation. When a lesson's origin is a file, start its action with `move from <file>` when Step 7 would mark the lesson moved once its write lands, and with `from <file>` otherwise. When a lesson carries a reason the user did not state, show that reason in its row, marked *inferred*, so the approval covers it. For Auto memory, name the resolved project-memory target so the approval covers the durable write at that path. Turbo skill lessons show `Handoff to Turbo checkout` as the action when `checkout` is set, and `Propose upstream` otherwise, naming the Auto memory target that receives the lesson if the user declines to propose it.

Then use `AskUserQuestion` with these options: **Approve** or **Reject**.

## Step 6: Execute

**Skip** when Step 5 was skipped or the user rejected the plan.

Apply approved changes in order:

1. **Backlog** — For items routed to the project backlog or to a deterministic check, run the `/backlog` skill with the summary, location, and rationale for each, and for a deterministic check the mechanism it goes into, the existing violations it must clear to block new occurrences, and for a new check the fix its error message names.
2. **Updates to auto memory** — Read the target, find the right section, append or update in place, following the memory system conventions from the system prompt.
3. **Updates to CLAUDE.md / AGENTS.md** — Read the target file selected in Step 4 (the root file, a nested subtree file, or a rules document one of them points to), find the right section, append or update in place. Match the tone and format already present.
4. **Updates to user/project skills** — Run the `/write-skill` skill to apply changes to any file inside the skill directory (SKILL.md, references, scripts, assets).
5. **New skills** — Run the `/write-skill` skill for each new skill. Provide the trigger conditions and the evidence behind each lesson.
6. **Turbo skill lessons** — Edit no file in the Turbo plugin's skills folder: a plugin update replaces it. Read [references/turbo-skill-lessons.md](references/turbo-skill-lessons.md) and follow it.
7. **Project-named destinations** — Write each lesson by the process the project's instruction files give for its destination, running any project skill that process names.

## Step 7: Report Outcomes

Output each candidate lesson in the words it was passed, with its origin and its outcome: written (naming each file it landed in and its destination), handed off to the Turbo checkout, filed upstream (with the issue URL), not filed upstream, kept where it is, rejected, failed (with the error), dropped in Step 4 (with the reason), or discarded in Step 3 (with the reason). Mark as moved each lesson whose origin is a file and that was written to a destination other than Auto memory or the backlog, handed off, or filed upstream.

Then use the TaskList tool and proceed to any remaining task.

## Writing Guidelines

- Match the tone and format of the target file
- Use imperative mood and short declarative sentences
- Group related insights under a descriptive heading
- Omit rationale unless the rule would seem arbitrary without it
- Never include temporary state, in-progress work, or task-specific details
- Keep lessons generic—avoid overly concrete examples; state the rule, not the instance
- Write each rule at the narrowest level that would have prevented the mistake on the next, different case: broader than the instance, narrower than a universal rule. The same correction on two or more cases confirms that level. Test it: an agent reading only the rule, and its reason when given, should produce what the user wanted. When it would not, add the value, name, or exception the rule itself depends on
- For AGENTS.md: write as agent documentation — project rules any AI agent on this repo should follow
- For auto memory: write as personal project notes — concise, operational, organized by topic
- For skills: follow the conventions in the existing skill collection
- For files that live in the repo (CLAUDE.md / AGENTS.md, the rules documents they point to, project-named destinations, and project skills): name only mechanisms that live in the repo too; describe an installed skill's behavior generically
