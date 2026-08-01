---
name: changelog-rules
description: "Shared changelog conventions and formatting rules referenced by /create-changelog and /update-changelog. Not typically invoked directly."
---

# Changelog Rules

The changelog is kept in `CHANGELOG.md` at the project root. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and projects using these conventions adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## File Structure

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] - 2024-03-15

### Added

- Add dark mode support ([#38](https://github.com/owner/repo/issues/38), [#42](https://github.com/owner/repo/pull/42))

### Fixed

- Fix crash on startup ([#40](https://github.com/owner/repo/issues/40), [#43](https://github.com/owner/repo/pull/43))

[Unreleased]: https://github.com/<owner>/<repo>/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/<owner>/<repo>/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/<owner>/<repo>/releases/tag/v1.1.0
```

## Changelog-Worthiness

Not every change belongs in a changelog. Changelogs are for humans, not machines.

**Skip** changes that are purely internal:

- Refactoring with no user-facing impact
- Code formatting, linting, whitespace
- Test additions or modifications (unless they indicate a fixed bug)
- CI/CD configuration
- Developer tooling (linters, editor config)
- Documentation updates (README, comments, docstrings)
- Dependency bumps with no behavior change

**Include** changes that affect users:

- New features or capabilities
- Changes to existing behavior
- Deprecated or removed functionality
- Bug fixes
- Security patches

## Entry Format

- Imperative present tense without trailing periods (e.g., "Add dark mode support")
- One bullet point per distinct change
- Concise but complete. Include enough context that users understand the impact.

### User-Centric Writing

Entries describe what changed **for the user**. Focus on outcomes and impact.

- Lead with a user-visible verb: "Add", "Fix", "Improve", "Allow", "Prevent", "Show", "Check". Avoid developer-centric verbs like "Enforce", "Implement", "Refactor", "Handle", "Register".
- Describe the experience, not the mechanism. "Show grouped notifications: the list buckets items by source before rendering" carries the mechanism after the colon; "Show notifications grouped by the app that sent them" states only what the user gets.
- When a change prevents a problem or protects the user, say what it does for them.

### Net Delta from the Last Release

Entries describe the change relative to the last released version.

- Judge each entry by whether a user of the previous release would observe the change. "No longer does X" or "removed the Y glitch" where X or Y never shipped is the obvious tell.
- A positively-phrased entry hides the same trap. "Allow renaming saved filters straight from the list, so fixing a typo takes one click" reads like a real improvement, yet it belongs to the feature when saved filters themselves arrived in the same unreleased cycle.
- When finalizing a release, compare the behavior at the last release tag against the behavior today: `git show <last-tag>:<path>`, plus `git log --follow -- <path>` when the file moved. A path that exists at the tag settles nothing on its own, since new behavior often lands in files that were already there.
- When the behavior an entry describes arrived after the tag, rewrite the entry as the net capability, fold it into whatever introduced that behavior, or drop it.
- Keep one entry per net user-visible change.

## PR and Issue References

Reference both the PR and any associated GitHub issue in each entry using inline parenthetical format with linked numbers in ascending order.

```markdown
- Add dark mode support ([#38](https://github.com/owner/repo/issues/38), [#42](https://github.com/owner/repo/pull/42))
```

To discover associated issues for a PR, run:

```bash
gh pr view <number> --json closingIssuesReferences --jq '.closingIssuesReferences[].number'
```

- If there is no associated issue, reference only the PR
- If there is no PR (e.g., backfilling from git tags), omit references

## Change Types

Standard types in this order when present: Added, Changed, Deprecated, Removed, Fixed, Security. Omit empty sections.

## Section Format

- Unreleased section always present at the top
- ISO 8601 dates (`YYYY-MM-DD`)
- Reverse chronological order (newest first)
- Blank line between each section header and its content
- Version comparison links at the bottom, derived from the repository's remote URL
- Detect whether the project uses `v`-prefixed tags (e.g., `v1.0.0`) or bare tags (e.g., `1.0.0`) and match that convention in comparison links
