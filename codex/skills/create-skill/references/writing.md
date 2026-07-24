# Writing the Body

Sentence-level and section-level rules for the prose inside a skill.

## Contents

- Keep a Short Intro Paragraph
- Use Consistent Terminology
- Use Generic Examples
- Prefer Positive Phrasing
- State Conditions Explicitly
- Prefer Qualitative Descriptions for Judgment Calls
- Avoid Time-Sensitive Information
- Avoid Redundant Rules Sections
- Provide a Default Rather Than Too Many Options
- Verify Code Fence Pairing After Multi-Template Edits

## Keep a Short Intro Paragraph

YAML frontmatter (name, description) is stripped before the skill body is loaded into context. If the title and steps don't make the skill's purpose obvious, a one-line intro paragraph after the `# Title` heading can help orient execution. Keep it short, avoid restating the description verbatim, and omit it entirely if the steps already make the purpose clear.

## Use Consistent Terminology

Choose one term and use it throughout the Skill:

**Good - Consistent**:

- Always "API endpoint"
- Always "field"
- Always "extract"

**Bad - Inconsistent**:

- Mix "API endpoint", "URL", "API route", "path"
- Mix "field", "box", "element", "control"
- Mix "extract", "pull", "get", "retrieve"

Consistency helps the agent understand and follow instructions.

## Use Generic Examples

Skills may be used across different projects. Avoid project-specific details in examples — use generic placeholders instead.

- ✗ **Avoid**: "Run `python3 manage.py migrate` to update the Acme database schema. Click the 'Deploy to Acme Staging' button."
- ✓ **Good**: "Run the project's migration command to update the database schema. Click the deployment button for the target environment."

If a skill is project-specific by design (lives in the project repo, not in a shared location), project-specific examples are acceptable. But skills intended for reuse across projects should use generic placeholders.

Also consider whether inline examples are needed at all. Parenthetical examples like "(e.g. click the Submit button)" often add no value when the instruction is already clear. Prefer concise instructions without examples over instructions cluttered with obvious ones.

## Prefer Positive Phrasing

State what to do. Imperative verbs ("defer", "limit", "exclude", "halt", "describe") give the agent a clear action; chains of "Never X. Don't Y. Avoid Z." force the agent to invert the prohibition into an action before acting on it.

- ✗ **Avoid**: "Never modify files in `vendor/`. Files there are managed by the package manager."
- ✓ **Good**: "Treat files in `vendor/` as read-only."

The positive form names the action and drops the explanatory clause that just restates the boundary.

Use negative phrasing only when a positive imperative cannot articulate the rule unambiguously. When an explicit enumeration of prohibited items is load-bearing, prefer positive verbs ("Exclude", "Omit", "Reserve X for Y") over "Never include" or "Don't add". Redundant negative restatements — a rule paired with a tautological-boundary clause that says the same thing — are always trim targets.

## State Conditions Explicitly

If a step has a clear condition for when to execute and when to skip, state both directly. Don't soften it with "optionally" — that creates ambiguity about whether the step should actually run.

- ✗ **Avoid**: "Optionally spawn a sub-agent to verify findings."
- ✓ **Good**: "Spawn a sub-agent when there are 3+ non-trivial findings. **Skip** when all findings are clear-cut."

## Prefer Qualitative Descriptions for Judgment Calls

When a skill describes a threshold the agent must judge (when something is too large, when to split, when to combine), prefer qualitative descriptions over numeric heuristics. Numbers like "more than 15 files" or "3+ subsystems" feel precise but encourage box-ticking — agents tally and cross the threshold without engaging the underlying judgment. Qualitative descriptions ("the work would exhaust a session", "too many distinct conventions to absorb") force the agent to evaluate the actual situation.

- ✗ **Avoid**: "Split when a shell would touch more than 15-20 files or span 3+ unrelated subsystems."
- ✓ **Good**: "Split when the combined work would exhaust a single session: too much code to read in full, or too many distinct conventions to absorb."

Use numbers only when the threshold is mechanically verifiable and the count is the actual signal (e.g., "cap at 3 retries", "every R-id must appear in at least one Covers field").

## Avoid Time-Sensitive Information

Don't include information that will become outdated:

- ✗ **Avoid**: "Before August 2025, use the old API. After August 2025, use the new API."
- ✓ **Good**: Document the current method directly. If legacy guidance is needed, isolate it under an "Old patterns" section so it doesn't clutter primary instructions.

## Avoid Redundant Rules Sections

A Rules section should only contain information not already conveyed by the skill body. Before adding a rule, check whether the Process, workflow steps, or tables already encode the same behavior. If they do, the rule is wasted tokens.

## Provide a Default Rather Than Too Many Options

Don't present multiple approaches unless necessary. Name one default and give an escape hatch for the case that genuinely needs it.

- ✗ **Avoid**: "You can use library A, or library B, or library C, or..."
- ✓ **Good**: "Use library A. For <specific edge case>, use library B instead."

## Verify Code Fence Pairing After Multi-Template Edits

When inserting a second fenced code block alongside an existing one in the same skill section, verify that both fences pair correctly. Multi-template edits commonly produce orphan closing fences, especially when shared scaffolding (XML output contracts, output specs, dig-deeper nudges) needs to apply to both templates.

Two safe patterns:

1. **Each template fully self-contained**: Each fenced block contains its own copy of the shared scaffolding. Repetitive but unambiguous.
2. **Shared scaffolding in its own fence**: The shared content lives in a separate labeled fenced block, with prose explaining how to concatenate it with the template-specific blocks.

- ✗ **Avoid**: Two fenced template blocks where shared XML scaffolding appears as raw markdown between them, leaving an orphan closing ` ``` ` somewhere. Readers see the shared content as unparsed prose; rendering breaks.
- ✓ **Good**: Three fenced blocks (template A, template B, shared scaffolding) with `### ` subheadings naming each. Or two fenced blocks where each repeats the shared scaffolding internally.
