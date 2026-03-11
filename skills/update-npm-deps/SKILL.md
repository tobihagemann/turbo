---
name: update-npm-deps
description: This skill should be used when the user asks to "update dependencies", "upgrade npm packages", "check for updates", "update npm deps", or wants to intelligently upgrade npm dependencies with breaking change research.
argument-hint: [package-filter]
---

# Update NPM Dependencies

Upgrade npm dependencies intelligently, researching breaking changes for major version updates.

Optional filter: `$ARGUMENTS` (e.g., `react`, `react axios lodash`)

## Phase 1: Monorepo Detection

Search for `package.json` files in the project (excluding `node_modules`):

```bash
find . -name "package.json" -not -path "*/node_modules/*" -not -path "*/.git/*"
```

- If **one** found: proceed with that location
- If **multiple** found: use AskUserQuestion to let user choose which to update (multiSelect allowed)
- If **none** found: inform user and exit

## Phase 2: Discovery

For each selected package.json location:

1. Change to the directory containing package.json
2. Run npm-check-updates to discover available updates:

```bash
ncu --format group
```

If a filter was provided via `$ARGUMENTS`:
```bash
ncu --format group --filter "$ARGUMENTS"
```

3. Parse the output to categorize updates:
   - **Major** (breaking changes) - requires migration research
   - **Minor** (new features, backward compatible)
   - **Patch** (bug fixes)

4. Create TodoWrite tasks for each major update package

If no updates are available, inform the user and exit.

## Phase 3: User Strategy Selection

Present a summary showing:
- Count and list of major updates (with current → target versions)
- Count of minor updates
- Count of patch updates

Use AskUserQuestion to ask upgrade strategy:

**Header**: "Strategy"
**Options**:
- **Cautious** - Upgrade minor/patch first, then major one-by-one with research
- **All at once** - Research all major changes, then upgrade everything together
- **Skip major** - Only upgrade minor and patch versions
- **Interactive** - Ask for each major update individually

## Phase 4: Research Breaking Changes

For **each package with a major version update**:

### Step 4.1: Calculate Version Gap

Identify all major versions between current and target. For example:
- `react: 17.0.2 → 19.0.0` → research v18 AND v19 breaking changes
- `jest: 27.5.1 → 29.7.0` → research v28 AND v29 breaking changes

### Step 4.2: Research Each Major Version

For each major version in the gap, search for migration documentation:

```
WebSearch: "[package-name] v[X] migration guide"
WebSearch: "[package-name] v[X] breaking changes"
```

Common sources:
- GitHub releases: `https://github.com/[org]/[repo]/releases`
- Official docs migration guides
- Changelog files

### Step 4.3: Extract Key Breaking Changes

From the migration docs, identify:
- API changes (renamed/removed functions)
- Configuration changes
- Peer dependency requirements
- Behavioral changes
- Deprecated features now removed

### Step 4.4: Search Codebase for Affected Code

Use Grep to find usage of deprecated or changed APIs:

```
Grep: "[deprecated-function-name]"
Grep: "[changed-import-pattern]"
```

Document which files are affected and what changes are needed.

## Phase 5: User Confirmation

For each major update, present:
- Package name and version transition
- Breaking changes found (summarized)
- Files potentially affected (count and list)

Use AskUserQuestion to confirm:

**Header**: "Confirm"
**Options**:
- **Proceed** - Continue with upgrades and migrations
- **Show details** - Display detailed breaking changes for review
- **Skip package** - Exclude a specific package from upgrade
- **Abort** - Cancel the upgrade process

If "Show details" selected, display full migration research, then ask again.

## Phase 6: Execute Upgrades

### For Cautious Strategy

First, upgrade minor and patch only:
```bash
ncu -u --target minor
npm install
```

Run tests to verify:
```bash
npm test
```

If tests fail, stop and inform user before proceeding with major upgrades.

### Upgrade Major Versions

For each major version upgrade (or all at once based on strategy):

Single package:
```bash
ncu -u --filter [package-name]
npm install
```

All packages:
```bash
ncu -u
npm install
```

## Phase 7: Apply Migrations

For each major update with identified code changes:

### Step 7.1: Run Codemods (if available)

Some packages provide automated migration tools:
- React: `npx react-codemod [transform-name]`
- Jest: `npx jest-codemods`
- Next.js: `npx @next/codemod [transform-name]`

### Step 7.2: Manual Code Changes

For changes requiring manual intervention:
1. Read the affected file
2. Apply the necessary transformation using Edit
3. Show the user what changed

### Step 7.3: Update Configuration Files

If configuration format changed:
1. Read current config
2. Transform to new format
3. Write updated config

## Phase 8: Verification

Run available verification commands:

```bash
npm test
```

If build script exists:
```bash
npm run build
```

If lint script exists:
```bash
npm run lint
```

### Report Results

Summarize:
- Packages upgraded (count)
- Breaking changes addressed (count)
- Files modified (count)
- Test results: pass/fail
- Remaining manual tasks (if any)

### Recommend Next Steps

If any migrations could not be automated:
- List specific changes the user needs to review
- Highlight deprecated patterns that need attention
- Note any runtime behavior changes to watch for

## Error Handling

### ncu Not Available

If `ncu` is not found, suggest:
```bash
npm install -g npm-check-updates
```

### Network Errors During Research

If WebSearch/WebFetch fails:
- Retry with alternative search terms
- Provide manual research links
- Proceed with caution, warning user that migration research may be incomplete

### Test Failures After Upgrade

- Stop the upgrade process
- Suggest rollback: `git checkout package.json package-lock.json && npm install`
- Identify which package likely caused the failure

### Migration Research Incomplete

If official migration docs are not found:
- Check npm package page for links
- Search GitHub issues for migration discussions
- Note as "migration research incomplete - proceed with caution"
