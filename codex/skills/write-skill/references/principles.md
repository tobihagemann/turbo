# Core Principles

Foundational decisions that apply to every skill: what to include, what to leave out, and how much freedom to give the agent.

## Contents

- Concise Is Key
- Skill Files Are Instructions, Not Documentation
- Retire the Guardrail a New Rule Makes Unreachable
- Set Appropriate Degrees of Freedom
- Test with All Models You Plan to Use

## Concise Is Key

The context window is a public good. Your Skill shares the context window with everything else the agent needs to know, including:

- The system prompt
- Conversation history
- Other Skills' metadata
- Your actual request

Not every token in your Skill has an immediate cost. Codex injects SKILL.md as a contextual user fragment only when a `$skill-name` token appears in the current turn's input; metadata (name and description) is harvested separately for discovery. So additional reference files cost nothing until they are read. However, being concise in SKILL.md still matters: once the agent loads it, every token competes with conversation history and other context.

**Default assumption**: the agent is already very smart

Only add context the agent doesn't already have. Challenge each piece of information:

- "Does the agent really need this explanation?"
- "Can I assume the agent knows this?"
- "Does this paragraph justify its token cost?"

Give the instruction and the minimum needed to act on it. Background on what a format is, why a library is popular, or how to install a standard tool is almost always cuttable — a concise instruction that costs 50 tokens routinely expands to 150 when padded with that kind of preamble.

## Skill Files Are Instructions, Not Documentation

A skill file tells the agent what to do. It is not a place to explain what the skill is, why it exists, how it fits into the broader collection, or what its design history is. The agent does not benefit from narrator prose — a human reader might, but skills are loaded into an agent's context, not read by humans at design time.

Common drift patterns to strip on sight:

- **Meta-framing** — sentences that describe the skill file to its own reader: "This SKILL.md is the router...", "This skill wraps X with Y...", "This file acts as..." If the agent is reading the file, it already knows it's reading the file.
- **Cross-skill commentary** — "This skill is the sibling/counterpart/successor of $other-skill." Skills should be self-contained and not reference which pipelines call them or which siblings they relate to.
- **Marketing or positioning copy** — "X is the structured alternative to Y" or "X is the preferred way to do Z." That kind of framing belongs in a README, not a skill file.
- **Architecture commentary** — explaining the data model or file layout as standalone prose when the instructions already imply the structure. If the steps tell the agent to "write the index to `<path>`," a separate sentence saying "the index is a thin manifest" adds nothing.
- **Historical rationale** — "X happens here because Y would cause Z." Keep only the rule; drop the backstory unless it actively prevents a rationalization the agent would otherwise make.
- **Tautological boundary statements** — "X is Y's job; this skill only does Z." If the positive instructions are correct, boundaries are already implicit.
- **"Caller" phrasing** — "the caller," "caller passed," "caller provides." Skills run in a conversational context, not a function-call context. This is narrator language about who invoked the skill rather than instruction to the agent, and it is ambiguous about whether "the caller" is the user, another skill, or the pipeline agent. Prefer passive voice ("if a plan path was provided") or a named role when the distinction actually matters.

When in doubt, compare a new or edited skill against the simplest existing skills in the same collection. If a lean neighbor skill opens with a one-line purpose and jumps straight into a Plan section or Step 1, and your skill has three paragraphs of context before the first instruction, the extra paragraphs are almost certainly drift.

## Retire the Guardrail a New Rule Makes Unreachable

Much of a skill's text is a guardrail: it compensates for a failure mode, for a mode the agent might select, or for a behavior of the surrounding machinery. A change that removes what a guardrail compensates for leaves that guardrail unreachable — and unreachable text survives review, because it still reads as sound advice.

Run the check at the moment a rule is added or changed rather than as a later cleanup pass. Name what each guardrail near the change was compensating for, then establish whether that condition can still arise. When it cannot, delete the guardrail in the same edit. Sweep the skill's reference files alongside the file being edited, since a rule in one routinely guards a condition described in another.

The tell is a change that removes the condition rather than discouraging it: the harness no longer exposes the mode, the interface no longer accepts the input, or the new rule strips the precondition the guardrail needs, leaving it nothing to fire on in any run that follows the rule.

Keep the guardrail when the condition survives the rule. A prohibition constrains what the agent should do without removing what it can do, so anything guarding against the agent's own drift stays, as does every fallback for a cause the rule does not reach: harness errors, unavailable tools, and the divergences a project records deliberately.

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

Skills act as additions to models, so effectiveness depends on the underlying model. Test your Skill with each model you plan to use — terser models may need more explicit guidance, and stronger models may not need explanations that smaller ones do.
