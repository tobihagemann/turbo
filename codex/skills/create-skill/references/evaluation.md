# Evaluation and Iteration

How to validate that a skill actually works and refine it from observed behavior.

## Contents

- Build Evaluations First
- Develop Skills Iteratively with the Agent
- Observe How the Agent Navigates Skills

## Build Evaluations First

**Create evaluations BEFORE writing extensive documentation.** This ensures your Skill solves real problems rather than documenting imagined ones.

**Evaluation-driven development:**

1. **Identify gaps**: Run the agent on representative tasks without a Skill. Document specific failures or missing context
2. **Create evaluations**: Build three scenarios that test these gaps
3. **Establish baseline**: Measure the agent's performance without the Skill
4. **Write minimal instructions**: Create just enough content to address the gaps and pass evaluations
5. **Iterate**: Execute evaluations, compare against baseline, and refine

This approach ensures you're solving actual problems rather than anticipating requirements that may never materialize.

**Evaluation structure**: name the skills under test, the query, any input files, and a list of expected behaviors specific enough to grade against.

```json
{
  "skills": ["<skill-name>"],
  "query": "<the request a user would actually make>",
  "files": ["<input file path>"],
  "expected_behavior": [
    "<observable behavior 1, stated specifically enough to grade>",
    "<observable behavior 2>",
    "<observable behavior 3>"
  ]
}
```

> **Note:** This example demonstrates a data-driven evaluation with a simple testing rubric. There is not currently a built-in way to run these evaluations. Users can create their own evaluation system. Evaluations are your source of truth for measuring Skill effectiveness.

## Develop Skills Iteratively with the Agent

The most effective Skill development process involves the agent itself. Work with one session ("Session A") to design and refine the Skill, and test it with a fresh session ("Session B") on real tasks. Session A understands agent needs; Session B reveals gaps through real usage.

1. **Complete a task without a Skill** in Session A. Notice what context you repeatedly provide.
2. **Ask the agent to create the Skill**, capturing that context. The agent understands the Skill format natively and will generate properly structured SKILL.md content.
3. **Review for conciseness** and information architecture. Ask the agent to remove explanations it already knows, and to split reference content into separate files when it grows.
4. **Test with Session B** (a fresh session with the Skill installed) on related tasks. Observe whether it finds the right information, applies rules correctly, and succeeds.
5. **Return to Session A with specifics** when Session B struggles: "It forgot to filter by date — should we make that more prominent?" Apply refinements, then test again.
6. **Gather team feedback**: share with teammates and ask whether the Skill activates when expected, whether instructions are clear, and what's missing.

## Observe How the Agent Navigates Skills

As you iterate on Skills, pay attention to how the agent actually uses them in practice. Watch for:

- **Unexpected exploration paths**: Does the agent read files in an order you didn't anticipate? This might indicate your structure isn't as intuitive as you thought
- **Missed connections**: Does the agent fail to follow references to important files? Your links might need to be more explicit or prominent
- **Overreliance on certain sections**: If the agent repeatedly reads the same file, consider whether that content should be in the main SKILL.md instead
- **Ignored content**: If the agent never accesses a bundled file, it might be unnecessary or poorly signaled in the main instructions

Iterate based on these observations rather than assumptions. The `name` and `description` in your Skill's metadata are particularly critical. Codex uses these when deciding whether to trigger the Skill in response to the current task. Make sure they clearly describe what the Skill does and when it should be used.
