---
name: create-skill
description: "Create a new skill or update an existing skill that extends Claude's capabilities with specialized knowledge, workflows, or tool integrations. Use when the user asks to \"create a skill\", \"make a new skill\", \"build a skill\", \"scaffold a skill\", \"write a skill for...\", or \"new skill that does...\"."
---

# Create Skill

This skill guides the creation of effective skills. Authoring guidance is split across the reference files below. Read the ones the current step needs rather than all of them.

| Reference | Covers |
|---|---|
| [references/principles.md](references/principles.md) | Conciseness, instructions-not-documentation, degrees of freedom |
| [references/structure.md](references/structure.md) | Frontmatter, naming, descriptions, progressive disclosure, file layout |
| [references/writing.md](references/writing.md) | Prose rules: terminology, phrasing, conditions, thresholds |
| [references/workflows.md](references/workflows.md) | Step/phase structure, feedback loops, exit signals, output patterns |
| [references/composition.md](references/composition.md) | Depending on, invoking, and fanning out to other skills |
| [references/tools.md](references/tools.md) | Agent, Bash, AskUserQuestion, and MCP tool invocation |
| [references/evaluation.md](references/evaluation.md) | Evaluations and iterating on a skill from observed behavior |
| [references/scripts.md](references/scripts.md) | Skills that bundle executable code |
| [references/harness.md](references/harness.md) | Harness tool names, permission modes, and discovery paths |

For conceptual background on how Skills work, see the Skills overview on platform.claude.com.

## Step 1: Understanding the Skill with Concrete Examples

Skip this step only when the skill's usage patterns are already clearly understood. It remains valuable even when working with an existing skill.

To create an effective skill, clearly understand concrete examples of how the skill will be used. This understanding can come from either direct user examples or generated examples that are validated with user feedback.

For example, when building an image-editor skill, relevant questions include:

- "What functionality should the image-editor skill support? Editing, rotating, anything else?"
- "Can you give some examples of how this skill would be used?"
- "I can imagine users asking for things like 'Remove the red-eye from this image' or 'Rotate this image'. Are there other ways you imagine this skill being used?"
- "What would a user say that should trigger this skill?"

To avoid overwhelming users, avoid asking too many questions in a single message. Start with the most important questions and follow up as needed for better effectiveness.

Conclude this step when there is a clear sense of the functionality the skill should support.

## Step 2: Planning the Reusable Skill Contents

To turn concrete examples into an effective skill, analyze each example by:

1. Considering how to execute on the example from scratch
2. Identifying what scripts, references, and assets would be helpful when executing these workflows repeatedly

Example: When building a `pdf-editor` skill to handle queries like "Help me rotate this PDF," the analysis shows:

1. Rotating a PDF requires re-writing the same code each time
2. A `scripts/rotate_pdf.py` script would be helpful to store in the skill

Example: When designing a `frontend-webapp-builder` skill for queries like "Build me a todo app" or "Build me a dashboard to track my steps," the analysis shows:

1. Writing a frontend webapp requires the same boilerplate HTML/React each time
2. An `assets/hello-world/` template containing the boilerplate HTML/React project files would be helpful to store in the skill

Example: When building a `big-query` skill to handle queries like "How many users have logged in today?" the analysis shows:

1. Querying BigQuery requires re-discovering the table schemas and relationships each time
2. A `references/schema.md` file documenting the table schemas would be helpful to store in the skill

To establish the skill's contents, analyze each concrete example to create a list of the reusable resources to include: scripts, references, and assets.

When creating a new skill, establish with that list in hand whether the skill earns its existence. The contents fail that test when they compensate for a problem fixable at its source, when they serve a one-time job rather than a recurring one, or when the instruction files the harness already loads cover them. Where any of those holds, state which one and name the alternative — the upstream fix, a runbook, or a doc pointer — then use `AskUserQuestion` to let the user choose between that alternative and building the skill anyway, and continue from their answer. When updating an existing skill, apply the test to the change in hand and record any doubt about the whole skill's reason to exist beside the finished edit.

## Step 3: Initializing the Skill

Skip this step if the skill being developed already exists and iteration is needed. In this case, continue to the next step.

When creating a new skill from scratch, create the skill directory with:

- A `SKILL.md` file with proper YAML frontmatter (`name` and `description`) and TODO placeholders for the body
- Resource directories as needed: `scripts/`, `references/`, and/or `assets/`

After initialization, customize or remove the generated files as needed.

## Step 4: Edit the Skill

When editing the (newly-generated or existing) skill, remember that the skill is being created for another instance of Claude to use. Focus on including information that would be beneficial and non-obvious to Claude. Consider what procedural knowledge, domain-specific details, or reusable assets would help another Claude instance execute these tasks more effectively.

To begin implementation, start with the reusable resources identified above: `scripts/`, `references/`, and `assets/` files. Note that this step may require user input. For example, when implementing a `brand-guidelines` skill, the user may need to provide brand assets or templates to store in `assets/`, or documentation to store in `references/`.

Before writing SKILL.md, read [references/principles.md](references/principles.md), [references/structure.md](references/structure.md), and [references/writing.md](references/writing.md). These apply to every skill.

Then read the references matching what this skill does:

- Multi-step or looping workflow → [references/workflows.md](references/workflows.md), plus [references/tools.md](references/tools.md) when it gates on user input
- Depends on or fans out to other skills → [references/composition.md](references/composition.md), plus [references/tools.md](references/tools.md) when it fans out
- Dispatches Agent, Bash, `AskUserQuestion`, or MCP calls → [references/tools.md](references/tools.md)
- Bundles executable scripts → [references/scripts.md](references/scripts.md)
- Targets a specific harness primitive, or depends on an exact tool name, limit, or discovery path → [references/harness.md](references/harness.md)

Read [references/evaluation.md](references/evaluation.md) when validating the skill against real tasks or refining it from observed behavior.

## Task Tracking

At the start of Step 5, use `TaskCreate` to create a task for each remaining step:

- "Review the skill" for Step 5
- "Run /evaluate-findings skill" for Step 6
- "Run /apply-findings skill" for Step 7
- "Verify" for Step 8

## Step 5: Review the Skill

After writing all files, spawn a subagent (`model: "opus"`, no `name`) to review the skill. Wait for it to report before continuing; do not relaunch it if it has not yet reported. The subagent should read [references/skill-reviewer.md](references/skill-reviewer.md) for review guidelines, read all skill files, and produce a review report following the format in the guidelines. Its prompt must direct it to treat the shared working tree and its git index as read-only and to review by reading and reasoning; fixes happen in Step 7. HEAD stays where it is: read other refs with `git show <ref>:<path>` rather than `git checkout` or `git switch`.

- **For new skills**, frame the review as open-ended: propose improvements, convention checks, writing quality.
- **For modified skills** (simplification, restructuring, bug fix), frame the review as regression-focused: check whether the change broke anything. Tell the reviewer not to propose new features.
- **For same-session iteration** (re-reviewing a skill after applying findings from a previous review in the same session), treat as modified: the review is checking whether the fixes broke anything.
- **For batch changes** (multiple skills created or modified in the same session), group the work by distinct change rather than by skill. Two skills received the same change when the edited text is identical; otherwise each is a distinct change. Launch one review subagent per distinct change, plus one subagent covering every site of a change applied identically across several skills. Give that subagent the full site list, and have it check each site in its own local context and flag any comparable location in the batch that should have received the change but did not. Emit all of those Agent tool calls in one assistant message. Each Agent call uses `model: "opus"` and no `name`. Wait for every agent to report before continuing. Do not begin the next step on a partial set, and do not relaunch an agent that has not yet reported. State the total count and which sites map to which subagent when emitting the calls.

## Step 6: Run `/evaluate-findings` Skill

Run the `/evaluate-findings` skill on the review findings.

## Step 7: Run `/apply-findings` Skill

Run the `/apply-findings` skill on the evaluated findings.

## Step 8: Verify

When the skill bundles executable code, run the project's test suite and report the result: state pass or fail with the failing output, rather than closing the workflow on an assumption that the suite still passes. When the skill bundles none, or the project has no suite to run, say so.

Then use the TaskList tool and proceed to any remaining task.
