# Core Principles

Foundational decisions that apply to every skill: what to include, what to leave out, and how much freedom to give the agent.

## Contents

- Concise Is Key
- Skill Files Are Instructions, Not Documentation
- Set Appropriate Degrees of Freedom
- Test with All Models You Plan to Use

## Concise Is Key

The context window is a public good. Your Skill shares the context window with everything else Claude needs to know, including:

- The system prompt
- Conversation history
- Other Skills' metadata
- Your actual request

Not every token in your Skill has an immediate cost. At startup, only the metadata (name and description) from all Skills is pre-loaded. Claude reads SKILL.md only when the Skill becomes relevant, and reads additional files only as needed. However, being concise in SKILL.md still matters: once Claude loads it, every token competes with conversation history and other context.

**Default assumption**: Claude is already very smart

Only add context Claude doesn't already have. Challenge each piece of information:

- "Does Claude really need this explanation?"
- "Can I assume Claude knows this?"
- "Does this paragraph justify its token cost?"

Give the instruction and the minimum needed to act on it. Background on what a format is, why a library is popular, or how to install a standard tool is almost always cuttable — a concise instruction that costs 50 tokens routinely expands to 150 when padded with that kind of preamble.

## Skill Files Are Instructions, Not Documentation

A skill file tells Claude what to do. It is not a place to explain what the skill is, why it exists, how it fits into the broader collection, or what its design history is. Claude does not benefit from narrator prose — a human reader might, but skills are loaded into an agent's context, not read by humans at design time.

Common drift patterns to strip on sight:

- **Meta-framing** — sentences that describe the skill file to its own reader: "This SKILL.md is the router...", "This skill wraps X with Y...", "This file acts as..." If Claude is reading the file, it already knows it's reading the file.
- **Cross-skill commentary** — "This skill is the sibling/counterpart/successor of /other-skill." Skills should be self-contained and not reference which pipelines call them or which siblings they relate to.
- **Marketing or positioning copy** — "X is the structured alternative to Y" or "X is the preferred way to do Z." That kind of framing belongs in a README, not a skill file.
- **Architecture commentary** — explaining the data model or file layout as standalone prose when the instructions already imply the structure. If the steps tell Claude to "write the index to `<path>`," a separate sentence saying "the index is a thin manifest" adds nothing.
- **Historical rationale** — "X happens here because Y would cause Z." Keep only the rule; drop the backstory unless it actively prevents a rationalization the agent would otherwise make.
- **Tautological boundary statements** — "X is Y's job; this skill only does Z." If the positive instructions are correct, boundaries are already implicit.
- **"Caller" phrasing** — "the caller," "caller passed," "caller provides." Skills run in a conversational context, not a function-call context. This is narrator language about who invoked the skill rather than instruction to the agent, and it is ambiguous about whether "the caller" is the user, another skill, or the pipeline agent. Prefer passive voice ("if a plan path was provided") or a named role when the distinction actually matters.

When in doubt, compare a new or edited skill against the simplest existing skills in the same collection. If a lean neighbor skill opens with a one-line purpose and jumps straight into Task Tracking or Step 1, and your skill has three paragraphs of context before the first instruction, the extra paragraphs are almost certainly drift.

## Set Appropriate Degrees of Freedom

Match the level of specificity to the task's fragility and variability.

**High freedom** (text-based instructions):

Use when:

- Multiple approaches are valid
- Decisions depend on context
- Heuristics guide the approach

The instruction names the objective and the checks that matter, leaving sequencing and technique to the agent.

**Medium freedom** (pseudocode or scripts with parameters):

Use when:

- A preferred pattern exists
- Some variation is acceptable
- Configuration affects behavior

The instruction supplies a template or a parameterized signature and says to customize as needed.

**Low freedom** (specific scripts, few or no parameters):

Use when:

- Operations are fragile and error-prone
- Consistency is critical
- A specific sequence must be followed

The instruction gives an exact command and states that it must not be modified or extended with additional flags.

## Test with All Models You Plan to Use

Skills act as additions to models, so effectiveness depends on the underlying model. Test your Skill with each model you plan to use — what works for Opus may need more guidance for Haiku, and what's clear for Haiku may over-explain for Opus.
