# Skill Metadata and Structure

Frontmatter rules, naming, and how to lay out a skill directory so the agent loads only what it needs.

## Contents

- YAML Frontmatter
- Naming Conventions
- Writing Effective Descriptions
- Progressive Disclosure Patterns
- Avoid Deeply Nested References
- Separation of Concerns Between Layers
- Use Forward Slashes in Paths
- Compute Relative Paths from the File's Actual Location
- Structure Longer Reference Files with Table of Contents

## YAML Frontmatter

The SKILL.md frontmatter requires two fields:

`name`:

- Maximum 64 characters
- Must contain only lowercase letters, numbers, and hyphens
- Cannot contain XML tags
- Cannot contain reserved words: "openai", "codex", "chatgpt"

`description`:

- Must be non-empty
- Maximum 1024 characters
- Cannot contain XML tags
- Should describe what the Skill does and when to use it

**Quoting values**: Quote frontmatter values that contain YAML special characters. Unquoted `: ` (colon-space) breaks parsing. When in doubt, wrap the value in double quotes and escape inner quotes with `\"`.

```yaml
# Bad — colon-space breaks YAML parsing
description: Adapts to repo mode: fork creates a PR

# Good — quoted value
description: "Adapts to repo mode: fork creates a PR"
```

## Naming Conventions

Use consistent naming patterns to make Skills easier to reference and discuss. Consider using **gerund form** (verb + -ing) for Skill names, as this clearly describes the activity or capability the Skill provides.

Remember that the `name` field must use lowercase letters, numbers, and hyphens only.

**Good naming examples (gerund form)**:

- `processing-pdfs`
- `analyzing-spreadsheets`
- `managing-databases`
- `testing-code`
- `writing-documentation`

**Acceptable alternatives**:

- Noun phrases: `pdf-processing`, `spreadsheet-analysis`
- Action-oriented: `process-pdfs`, `analyze-spreadsheets`

**Avoid**:

- Vague names: `helper`, `utils`, `tools`
- Overly generic: `documents`, `data`, `files`
- Reserved words: `openai-helper`, `codex-tools`, `chatgpt-helper`
- Inconsistent patterns within your skill collection

## Writing Effective Descriptions

The `description` field enables Skill discovery and should include both what the Skill does and when to use it.

> **Warning: Always write in third person**. The description is injected into the system prompt, and inconsistent point-of-view can cause discovery problems.
>
> - **Good:** "Processes Excel files and generates reports"
> - **Avoid:** "I can help you process Excel files"
> - **Avoid:** "You can use this to process Excel files"

**Be specific and include key terms**. Include both what the Skill does and specific triggers/contexts for when to use it.

Each Skill has exactly one description field. The description is critical for skill selection: Codex uses it to choose the right Skill from potentially 100+ available Skills. Your description must provide enough detail for the agent to know when to select this Skill, while the rest of SKILL.md provides the implementation details.

An effective description names the concrete operations and then the trigger contexts and user phrasings that should activate the skill. Avoid vague descriptions like `Helps with documents`, `Processes data`, or `Does stuff with files`.

## Progressive Disclosure Patterns

SKILL.md serves as an overview that points the agent to detailed materials as needed, like a table of contents in an onboarding guide.

**Practical guidance:**

- Keep SKILL.md body under 500 lines for optimal performance
- Split content into separate files when approaching this limit
- Use the patterns below to organize instructions, code, and resources effectively

A Skill can grow from a single SKILL.md to a directory of bundled content that the agent loads only when needed:

```text
skill-name/
├── SKILL.md              # Main instructions (loaded when triggered)
├── references/
│   ├── advanced.md       # Loaded as needed
│   └── reference.md      # API reference (loaded as needed)
└── scripts/
    ├── analyze.py        # Utility script (executed, not loaded)
    └── validate.py       # Validation script
```

Three patterns cover most cases:

- **High-level guide with references** — SKILL.md carries a quick-start path inline and links out to one file per advanced topic. The agent loads a linked file only when the task reaches that topic.
- **Domain-specific organization** — for Skills spanning multiple domains, give each domain its own reference file so a question about one domain never loads the others. Pair this with a grep hint in SKILL.md when the files are large enough that the agent should search rather than read them whole.
- **Conditional details** — keep the common path inline and link out only the branches, so the rare or heavyweight branch costs nothing on a typical run.

## Avoid Deeply Nested References

The agent may partially read files when they're referenced from other referenced files. When encountering nested references, the agent might use commands like `head -100` to preview content rather than reading entire files, resulting in incomplete information.

**Keep references one level deep from SKILL.md**. All reference files should link directly from SKILL.md to ensure the agent reads complete files when needed.

- ✗ **Avoid**: SKILL.md links to `advanced.md`, which links to `details.md`, which holds the actual information.
- ✓ **Good**: SKILL.md links directly to `advanced.md`, `reference.md`, and `examples.md`, each self-contained.

## Separation of Concerns Between Layers

When SKILL.md links to sub-files, each layer must own exactly one concern:

- **SKILL.md (router)**: Routing decisions, shared config, links to sub-files. Does not summarize or repeat sub-file content.
- **Sub-files (leaves)**: Self-contained instructions for one mode or topic. Assumes the routing decision is already made. Does not contain cross-mode routing tables.

Routing tables, decision logic, and shared config belong in SKILL.md only. Sub-files should never route back to siblings, and SKILL.md should not summarize sub-file commands. When other skills reference a sub-file, they should point to the skill and name the sub-file: "Run the `$skill-name` skill and consult sub-file.md to ..."

## Use Forward Slashes in Paths

Always use forward slashes in file paths, even on Windows:

- ✓ **Good**: `scripts/helper.py`, `reference/guide.md`
- ✗ **Avoid**: `scripts\helper.py`, `reference\guide.md`

Unix-style paths work across all platforms; Windows-style paths cause errors on Unix systems.

## Compute Relative Paths from the File's Actual Location

When a skill file references another file in the same skill, the relative path resolves from the file's own location, not from `SKILL.md`. A reference file at `skills/X/references/foo.md` linking to a sibling at `skills/X/references/bar.md` writes `bar.md`, not `references/bar.md`.

Use markdown links rather than inline code for cross-references. `[bar.md](bar.md)` matches how `SKILL.md` links to its references and how skills link to each other; inline `` `bar.md` `` reads as a path mention but loses the click-through and the convention.

- ✗ **Avoid**: From `skills/X/references/spec-mode.md`: "follow `references/plan-mode.md`" — broken path; not a link.
- ✓ **Good**: From `skills/X/references/spec-mode.md`: "follow [plan-mode.md](plan-mode.md)".

## Structure Longer Reference Files with Table of Contents

For reference files longer than 100 lines, include a table of contents at the top. This ensures the agent can see the full scope of available information even when previewing with partial reads. List the section headings under a `## Contents` heading near the top of the file, then the sections themselves.

The agent can then read the complete file or jump to specific sections as needed.
