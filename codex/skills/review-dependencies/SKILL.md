---
name: review-dependencies
description: "Detect package managers and CI action pins, then discover outdated or vulnerable dependencies. Returns structured findings without upgrading. Use when the user asks to \"review dependencies\", \"check for outdated packages\", \"check dependencies\", \"scan dependencies\", \"dependency review\", \"check for outdated GitHub Actions\", or \"are my workflow actions up to date\"."
---

# Review Dependencies

Detect package managers and CI action pins, then discover outdated or vulnerable dependencies. Analysis only. Does not upgrade.

## Step 1: Detect Package Managers

Identify which package managers are in use by searching for config files:

| Config file | Package manager | Lockfile | Ecosystem |
|---|---|---|---|
| `package.json` | npm / yarn / pnpm | `package-lock.json` / `yarn.lock` / `pnpm-lock.yaml` | Node.js |
| `Package.swift`, `*.xcodeproj` | Swift Package Manager | `Package.resolved` | Swift |
| `pyproject.toml`, `requirements.txt`, `setup.py` | pip / poetry / uv | `poetry.lock`, `uv.lock` | Python |
| `Cargo.toml` | cargo | `Cargo.lock` | Rust |
| `go.mod` | Go modules | `go.sum` | Go |
| `Gemfile` | Bundler | `Gemfile.lock` | Ruby |
| `pom.xml` | Maven | — | Java |
| `build.gradle`, `build.gradle.kts` | Gradle | `gradle.lockfile` | Java/Kotlin |
| `.github/workflows/*.yml` / `.yaml`, `action.yml` / `.yaml` | GitHub Actions | — | CI |

Swift dependencies can live in `Package.swift` or be configured directly in the Xcode project file (`.xcodeproj`/`.xcworkspace`). For Xcode-managed dependencies, inspect the project's package references.

Detection steps:

1. Search for config files in the project root and subdirectories (exclude vendored directories)
2. If a lockfile exists, use the corresponding package manager variant (e.g., `yarn.lock` → yarn, `pnpm-lock.yaml` → pnpm)
3. When the repo declares a dependency automation config (`.github/dependabot.yml` / `.yaml`, `renovate.json`, `.github/renovate.json`), read it and add every ecosystem it declares to the set found by the config-file search
4. When the repo has a GitHub remote, list open dependency PRs with `gh pr list --author app/dependabot` (or `app/renovate`), and mark each upgrade one of them already proposes
5. If **multiple instances of the same package manager** found (e.g., monorepo with several `package.json` files): use `request_user_input` to let the user pick one (Codex `request_user_input` choices are mutually exclusive). For an "all of them" workflow, ask follow-up free-form input or run the review per instance.
6. If **multiple package managers** found: use `request_user_input` to let the user pick one. Exclude the CI ecosystem from that choice and review it alongside whichever the user picks
7. If **none** found across every step above: inform user and stop

## Step 2: Discovery

Run the appropriate discovery command to find available updates:

| Package manager | Discovery command | Notes |
|---|---|---|
| npm | `ncu --format group` | Requires `npm-check-updates`. Suggest `npm install -g npm-check-updates` if missing. |
| yarn | `ncu --format group` or `yarn upgrade-interactive` | |
| pnpm | `ncu --format group` or `pnpm outdated` | |
| Swift PM | Check resolved versions in `Package.resolved` against latest releases via web search | No built-in outdated command. Read `Package.swift` or inspect the Xcode project to identify dependencies and their current version constraints. |
| pip | `pip list --outdated` | |
| poetry | `poetry show --outdated` | |
| uv | `uv pip list --outdated` | |
| cargo | `cargo outdated` | Requires `cargo-outdated`. Fall back to comparing `Cargo.toml` versions via web search. |
| Go modules | `go list -m -u all` | |
| Bundler | `bundle outdated` | |
| Maven | `mvn versions:display-dependency-updates` | |
| Gradle | `gradle dependencyUpdates` | Requires `com.github.ben-manes.versions` plugin. |
| GitHub Actions | `gh api repos/<owner>/<repo>/releases/latest --jq .tag_name`, compared against each `uses:` ref | No outdated command. Take `<owner>/<repo>` from the ref's first two path segments. Read a SHA-pinned ref's version from its trailing comment (`uses: <owner>/<action>@<sha> # v1.2.3`). Compare only the components the ref pins, so `@v7` is current against `v7.0.1`. Fall back to `repos/<owner>/<repo>/tags` when the release 404s or its tag namespace differs from the ref's, and to web search when the action is not hosted on GitHub. Exclude local (`./…`), `<repo-relative>` (`$/…`), and Docker (`docker://…`) refs, which pin no release. |

Categorize updates:
- **Major** (breaking changes) — requires migration research
- **Minor** (new features, backward compatible)
- **Patch** (bug fixes)

## Step 3: Report Findings

If the discovery tool is not installed, suggest the installation command (see Step 2 notes column). If no tool exists for the ecosystem, fall back to manual version checking via web search.

If no updates are available, report that dependencies are up to date.

## Output Format

Format each finding as:

```
### [P<N>] <title (imperative, <=80 chars)>

**Package:** `<name>` <current> -> <latest>
**Manager:** <npm/pip/cargo/etc.>
**Proposed:** <open automation PR already covering this upgrade, when one exists>

<one paragraph: why this matters, known vulnerabilities if any, major version gap>
```

After all findings, add:

```
## Overall Verdict

**Dependencies:** <up to date | updates available>

<summary with counts: N major, N minor, N patch>
```

## Priority Levels

- **P0** — Known security vulnerability (CVE) in the current version
- **P1** — Multiple major versions behind (e.g., React 17 → 19)
- **P2** — One major version behind or significantly outdated minor versions
- **P3** — Minor or patch updates available
