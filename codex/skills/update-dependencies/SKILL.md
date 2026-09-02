---
name: update-dependencies
description: "Upgrade project dependencies with breaking change research for major version updates. Use when the user asks to \"update dependencies\", \"upgrade packages\", \"upgrade dependencies\", \"update deps\", \"upgrade deps\", \"update npm deps\", \"update Swift packages\", \"cargo update\", \"go get updates\", \"bundle update\", or \"pip upgrade\"."
---

# Update Dependencies

Upgrade project dependencies, researching breaking changes for major version updates.

Optional filter: `$ARGUMENTS` (e.g., `react`, `Alamofire`, `serde tokio`)

## Phase 1: Review Dependencies

Run the `$review-dependencies` skill to detect package managers and discover available updates. If no updates are available, stop.

## Phase 2: User Strategy Selection

Before summarizing, set aside packages whose version tracks a pinned runtime or platform rather than the newest release, such as runtime type definitions and platform SDKs. Find the pin the project declares (version manager file, `engines` field, container base image, CI setup step) and hold any version beyond it until the pin moves.

Present a summary showing:
- Count and list of major updates (with current → target versions)
- Count of minor updates
- Count of patch updates
- Packages set aside, each with the pin that governs it

Use `request_user_input` for upgrade strategy (Codex `request_user_input` allows up to 3 options per question, so the strategies are split across two questions):

**Question 1 — Header**: "Approach"
**Options**:
- **Cautious** — Upgrade minor/patch first, then major one-by-one with research
- **All at once** — Research all major changes, then upgrade everything together
- **Major handling** — Defer the major decision (Skip-major or Interactive)

When a major upgrade would force a migration that is costly to reverse, present a **Get a second opinion** option in place of **All at once**, keeping Question 1 at three options and leaving **Major handling** in place so Question 2 stays reachable. It runs the `$consult-claude` skill for which strategy the breaking changes warrant. Then resolve the strategy with that answer in hand, re-asking when the choice stays the user's. A freeform answer asking to upgrade everything together selects the All-at-once strategy.

If the user picks **Major handling**, ask a follow-up:

**Question 2 — Header**: "Major handling"
**Options**:
- **Skip major** — Only upgrade minor and patch versions
- **Interactive** — Ask for each major update individually
- **Cancel** — Cancel and return to the previous step

## Phase 3: Research Breaking Changes

For **each package with a major version update**:

### Step 1: Calculate Version Gap

Identify all major versions between current and target. For example:
- `react: 17.0.2 → 19.0.0` → research v18 AND v19 breaking changes
- `Alamofire: 4.9.1 → 6.0.0` → research v5 AND v6 breaking changes

### Step 2: Research Each Major Version

Search for migration documentation:

```
Web search: "[package-name] v[X] migration guide"
Web search: "[package-name] v[X] breaking changes"
```

Common sources: GitHub releases page, official docs, changelog files.

### Step 3: Extract Key Breaking Changes

Identify: API changes (renamed/removed functions), configuration changes, peer/transitive dependency requirements, behavioral changes, deprecated features now removed.

### Step 4: Search Codebase for Affected Code

Use `rg` to find usage of deprecated or changed APIs. Document which files are affected and what changes are needed.

Then check the package's installed consumers: read their declared peer or compatibility ranges and flag any range that excludes the target version. Toolchain consumers such as linters, type checkers, and build tooling can block a major even when the project's own code and configuration are clean. Carry each one into Phase 4 as a blocker.

## Phase 4: User Confirmation

For each major update, present:
- Package name and version transition
- Breaking changes found (summarized)
- Files potentially affected (count and list)
- Consumers whose declared ranges block the upgrade, when Phase 3 found any

Use `request_user_input` to confirm (Codex `request_user_input` allows up to 3 options per question, so the four actions are split across two questions):

**Question 1 — Header**: "Decision"
**Options**:
- **Proceed** — Continue with upgrades and migrations
- **Show details** — Display detailed breaking changes for review
- **Other action** — Defer the choice (Skip-package or Abort)

If the user picks **Other action**, ask a follow-up:

**Question 2 — Header**: "Other action"
**Options**:
- **Skip package** — Exclude a specific package from upgrade
- **Abort** — Cancel the upgrade process
- **Cancel** — Cancel and return to the previous step

If "Show details" selected, display full migration research, then ask again.

## Phase 5: Execute Upgrades

After every install command in this phase, run both checks below before any tests and before Phase 6.

1. **Confirm the installed tree moved** — spot-check the resolved version of one or two upgraded packages in the installed dependency tree against the manifest. An install can record the new versions while leaving the installed packages on their old ones, which makes every later check report on the pre-upgrade tree. When the two disagree, force a clean resolve: use the package manager's lockfile-respecting install where it has one, otherwise clear the installed tree and install again. Re-check afterward.
2. **Diff the package-manager configuration** — inspect the package-manager config files for entries the tool wrote on its own. A tool enforcing a safety guard, such as a minimum age before a release is installable or a provenance requirement, may record a per-package exclusion rather than refusing. Treat such an entry as the guard being bypassed: revert it, then pin the manifest to the newest version the guard admits, which resolves without an exclusion.

### Cautious Strategy

First upgrade minor and patch only using the package manager's semver-respecting update command, then run tests. If tests fail, stop before proceeding with major upgrades.

### Major Version Upgrades

Update the manifest file (version constraint) and run the install/resolve command. For package managers with a dedicated upgrade command, use it. For others (Swift PM, Maven, Gradle), edit the manifest directly.

## Phase 6: Apply Migrations

### Step 1: Run Codemods (if Available)

Some ecosystems provide automated migration tools:

| Ecosystem | Migration tools |
|---|---|
| React | `npx react-codemod [transform]` |
| Next.js | `npx @next/codemod [transform]` |
| Jest | `npx jest-codemods` |
| Angular | `npx ng update` |
| Rust | `cargo fix` for edition migrations |
| Python | `pyupgrade`, `python-modernize` |

### Step 2: Manual Code Changes

For changes requiring manual intervention:
1. Read the affected file
2. Apply the necessary transformation with `apply_patch`
3. Show the user what changed

### Step 3: Update Configuration Files

If configuration format changed, read current config, transform to new format, write updated config.

### Step 4: Sync Version-Pinned CI/Container References

Some packages pin their version outside the manifest, beyond the package manager's reach, so a green local run hides the drift. For every upgraded package (major, minor, or patch), search CI and container configs for the old version string with `rg "<old-version>" .github Dockerfile* docker-compose* .devcontainer` and bump it in lockstep:

- CI container images whose tag must track the package — e.g. a Playwright image tag kept in lockstep with the installed `@playwright/test` version.
- Base images and tool versions in `Dockerfile`, `.devcontainer/`, and `docker-compose.yml`.
- Pinned tool versions in CI setup steps (`actions/setup-node` `node-version`, `setup-python`, toolchain files).

## Phase 7: Verification

Run the project's test, build, and lint commands. Detect which commands are available from the project's config files and scripts. Use project-level task runners when present (`Makefile`, `Taskfile`, `justfile`, npm scripts, etc.).

When an upgraded package owns persisted schema, run the test tiers that exercise the real backing store rather than the default command alone. A tier that substitutes test doubles for the store passes on a schema the upgraded package no longer accepts. Diff the schema the package now generates against the one the project has migrated to; when they differ, return to Phase 6 for the migration the difference calls for, then re-run the tiers.

### Report Results

Summarize: packages upgraded (count), breaking changes addressed (count), files modified (count), test results, remaining manual tasks.

### Recommend Next Steps

If any migrations could not be automated:
- List specific changes the user needs to review
- Highlight deprecated patterns that need attention
- Note any runtime behavior changes to watch for

## Error Handling

### Discovery Tool Not Available

If the discovery tool is not installed, `$review-dependencies` will note it. Fall back to manual version checking via web search.

### Network Errors During Research

If web search/fetch fails: retry with alternative search terms, provide manual research links, proceed with caution warning that migration research may be incomplete.

### Test Failures After Upgrade

- Stop the upgrade process
- Suggest rollback: restore manifest and lockfile from git, then reinstall
- Identify which package likely caused the failure

### Migration Research Incomplete

If official migration docs are not found: check the package's repository for issues and discussions, note as "migration research incomplete — proceed with caution."
