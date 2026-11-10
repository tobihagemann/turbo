# Package-Managed Skills

## Classify the Skill

Read `~/.agents/.skill-lock.json`. Its top-level `skills` object is keyed by skill name, and a skill listed there was installed from a source that replaces it wholesale on its next update. Match on the resolved path rather than the name alone, against the entry's `skillPath`, so a local fork that replaced the installed copy is not mistaken for it.

- **Package-managed** — the skill matches an entry.
- **Ownership-unresolved** — the skill matches no entry, or the file does not exist. Absence settles nothing: such a skill may still be one a package manager replaces.

## Route Its Lessons

**Package-managed:** route the lesson straight to **Auto memory**, recording the skill it applies to, with no question put to the user.

**Ownership-unresolved:** before routing a lesson to the skill, say plainly that an edit to it survives only while the user maintains the skill themselves. Then use `AskUserQuestion` to ask which is the case, with the options phrased as that effect: edits to this skill stick, or the next update overwrites them.

- **Edits stick** — route the lesson by the remaining routing rules.
- **The next update overwrites them** — route the lesson to **Auto memory**, recording the skill it applies to.
