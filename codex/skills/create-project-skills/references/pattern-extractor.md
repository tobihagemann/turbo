# Pattern Extractor Guidelines

Scan the codebase for convention patterns in one assigned category. Return a single structured list of findings using the format at the end of this file. Do not write code, modify files, or propose implementation steps.

## Contents

- Extraction Process
- Pattern Categories
  - Naming conventions
  - File organization
  - Framework usage
  - Data access and persistence
  - Error handling and logging
  - Testing conventions
  - State management
  - API and service boundaries
  - Styling and UI
  - Domain modeling and types
  - Concurrency and async
  - Build, scripts, and dev tooling
- Finding Format

## Extraction Process

### 1. Focus on the Assigned Category

The parent prompt names one category from the taxonomy below. Work only on that category. Ignore patterns that belong to other categories even when they surface during the search.

### 2. Survey Systematically

- Use shell glob expansion or `find` to locate candidate files by name pattern.
- Use `rg` to find specific symbols, imports, or patterns across files.
- Read files only after a glob or `rg` result indicates they are relevant.
- Issue multiple tool calls in parallel when searching for different things simultaneously.
- Look for repeated patterns across unrelated modules and recent commits. Isolated occurrences do not establish convention.

### 3. Skip Already-Documented Conventions

The parent prompt lists conventions already documented in `AGENTS.md`. Do not report those as new findings.

### 4. Emit Findings

Use the Finding Format section at the end of this file. One entry per distinct pattern. If the category yields no meaningful patterns, return a single "no patterns detected" line per the Finding Format.

## Pattern Categories

### Naming Conventions

**What to look for:** file names, directory names, class and type names, protocol or interface names, function and method names, variable and property names, constants, enum cases, test names, acronym casing, prefix or suffix conventions for specific roles (e.g., `*ViewModel`, `*Repository`, `use*` hooks).

**Evidence sources:** any source file. Look for repeated patterns across many files to distinguish convention from coincidence.

**Quality signals:** a linter or formatter config encoding the pattern, the same shape used across multiple subsystems and authors, the pattern applied even in recent commits.

### File Organization

**What to look for:** top-level directory layout, per-feature vs per-layer organization, where tests live relative to source, where generated or vendored code is placed, where configuration lives, how modules or packages are split.

**Evidence sources:** directory tree, manifest files, import or module paths, workspace configuration.

**Quality signals:** consistent placement across features, a documented structure in a README or architecture doc, build configuration that enforces the layout.

### Framework Usage

**What to look for:** how the project uses its primary frameworks (React hooks patterns, Vue composables, SwiftUI view structure, Django views and middleware, Rails controllers and concerns, Spring annotations, etc.). Both idiomatic and project-specific deviations.

**Evidence sources:** feature modules, component or view files, framework integration points.

**Quality signals:** the same framework idiom used across unrelated features, a wrapper or base class that encodes the convention, custom lint rules.

### Data Access and Persistence

**What to look for:** ORM or query builder usage, repository or data-access object patterns, transaction boundaries, caching layers, migration conventions, how queries are parameterized and composed, how related entities are loaded.

**Evidence sources:** data layer directories, repository or model files, query helpers, migration files.

**Quality signals:** a single way of writing queries across the codebase, shared base classes or helpers, documented transaction patterns.

### Error Handling and Logging

**What to look for:** custom error or exception types, how errors propagate (thrown, returned as result types, wrapped), logging library and log levels, structured logging fields, how user-facing errors differ from internal errors, retry and backoff patterns.

**Evidence sources:** shared error modules, logging utilities, service boundaries, API handlers.

**Quality signals:** a small number of well-defined error types, consistent logging context fields, documented retry policies.

### Testing Conventions

**What to look for:** test file naming and location, test framework choice and assertion style, fixture and factory patterns, mocking approach, test data builders, naming of test cases, how integration vs unit tests are separated, snapshot testing usage.

**Evidence sources:** test directories, test utility files, CI configuration.

**Quality signals:** consistent test structure across features, shared test helpers, tests written alongside recent code changes.

### State Management

**What to look for:** state container choice (Redux, Zustand, Pinia, Combine, observable objects, etc.), how state is scoped (global, feature, local), side-effect handling (thunks, sagas, effects), selector and derived-state patterns, how state shape evolves with features.

**Evidence sources:** store or state directories, feature state slices, action and reducer definitions.

**Quality signals:** a uniform state shape pattern across features, documented slice or module boundaries.

### API and Service Boundaries

**What to look for:** how HTTP clients are constructed and shared, request and response type definitions, authentication and header handling, pagination and error response shapes, internal service-to-service communication patterns, API versioning, rate limiting.

**Evidence sources:** client or service directories, generated API types, middleware or interceptor code.

**Quality signals:** a single client wrapper used everywhere, typed request and response schemas, consistent error-mapping layer.

### Styling and UI

**What to look for:** styling approach (CSS modules, Tailwind, styled-components, design tokens), design system components, spacing and typography scales, theming, accessibility conventions, responsive breakpoints, icon handling.

**Evidence sources:** component libraries, style or theme directories, design token files, Storybook or similar.

**Quality signals:** components composed from a design system rather than bespoke styles, consistent token usage, documented design system.

### Domain Modeling and Types

**What to look for:** core domain types and where they live, value vs entity distinction, identifier patterns (branded types, UUIDs, strongly-typed IDs), invariants enforced at the type level, serialization and deserialization boundaries, enum vs union type patterns.

**Evidence sources:** domain or model directories, type definition files, schema files.

**Quality signals:** types shared across layers (domain, API, storage), invariants enforced in constructors or smart constructors, consistent identifier strategy.

### Concurrency and Async

**What to look for:** async primitive choice (async/await, futures, promises, actors, Combine, RxJS), concurrency boundaries, cancellation patterns, thread-safety conventions, background work scheduling, queue usage, race-condition prevention.

**Evidence sources:** async utility files, background job modules, concurrency-heavy features.

**Quality signals:** a uniform async idiom across features, documented cancellation strategy, actor or queue boundaries that match module structure.

### Build, Scripts, and Dev Tooling

**What to look for:** package manager and lockfile, custom build scripts, code generation steps, pre-commit or pre-push hooks, CI pipeline structure, environment configuration, developer setup scripts.

**Evidence sources:** root manifest files, scripts directories, `.github/workflows/` or equivalent, Makefiles or justfiles, pre-commit configs.

**Quality signals:** scripts documented in the README, lint and test steps wired into CI, consistent environment variable handling.

## Finding Format

Each finding follows the structure below. Use this exact format so the evaluation step can aggregate uniformly.

```markdown
**Category:** <category name from the list above>
**Pattern:** <one-line convention statement>
**Evidence:** <file:line>, <file:line>, <file:line>
**Frequency:** <occurrences> / <eligible sites>
**Variants:** <competing variants observed, or "none">
**Notes:** <anything that affects quality evaluation: recency, author spread, linter backing>
```

If a category yields no meaningful patterns (e.g., state management in a backend-only service), return a single line: `**Category:** <name> — no patterns detected.`
