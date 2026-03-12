# Turbo

A modular collection of [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skills that speed up everyday dev tasks while keeping quality high. Heavily optimized and battle-tested with Claude Code and the Opus model.

## What Is This?

Turbo is a skill set for Claude Code. Each skill teaches Claude a specific workflow: reviewing code, creating PRs, investigating bugs, self-improving from session learnings, and more. The skills are designed to [work together](#how-skills-connect).

The key idea: skills aren't just standalone tools you use next to each other. They're [puzzle pieces](#the-puzzle-piece-philosophy) that connect into larger workflows. The main orchestrator, [`/finalize`](#the-main-workflow), chains testing, code simplification, AI review, committing, and PR creation into one command. But each piece is small and swappable. Replace one skill with your own and the rest of the pipeline still works.

The other core piece is [`/self-improve`](#self-improvement), which makes the whole system compound. After each session, it extracts lessons from the conversation and routes them to the right place: project CLAUDE.md, auto memory, or existing/new skills. Every session teaches Claude something, and future sessions benefit.

## What It's Not

Turbo amplifies your existing process. If your plan is vague, your architecture is unclear, and you skip every review finding, Turbo won't save you. Garbage in, garbage out.

It works best when your project has the right infrastructure in place:

- **Tests** — `/finalize` runs your test suite and writes missing tests. Without tests, there's no safety net. If your project doesn't have automated tests, [`/smoke-test`](#all-skills) (standalone skill, not part of `/finalize`) can fill the gap by launching your app and verifying changes manually, but real tests are always better.
- **Linters and formatters** — `/finalize` runs your linter after code review fixes. If you don't have one, style issues slip through.
- **Dead code analysis** — [`/find-dead-code`](#all-skills) (standalone skill, not part of `/finalize`) identifies unused code via parallel analysis, but it's even better when your project already has tools like `knip`, `vulture`, or `periphery` integrated.

The target audience is experienced developers who want to move faster without sacrificing quality. That said, beginners are welcome too. Turbo is a great way to learn how a professional dev workflow looks. Just don't blindly trust outputs. Review what Claude produces, understand *why* it made those choices, and build your own judgment alongside it.

## The Puzzle Piece Philosophy

Every skill is a self-contained piece. Orchestrator skills like `/finalize` compose them into workflows, but each piece works independently too.

Want to swap a piece? For example:
- Replace `/oracle` with your own setup (it's macOS-only and has a cookies workaround)
- Replace `/commit-rules` with your team's commit convention. The pipeline adapts.

The skills communicate through standard interfaces (git staging area, PR state, file conventions), not tight coupling.

## Sponsorship

If Turbo has helped you ship faster and you're so inclined, I'd greatly appreciate it if you'd consider [sponsoring my open source work](https://github.com/sponsors/tobihagemann).

## How Skills Connect

```mermaid
graph TD
    %% Planning pipeline (optional)
    subgraph planning ["Planning Pipeline (Optional)"]
        direction TB
        create-spec([/create-spec]):::plan --> create-prompt-plan([/create-prompt-plan]):::plan
        create-prompt-plan --> pick-next-prompt([/pick-next-prompt]):::plan
        pick-next-prompt --> plan-implementation([/plan-implementation]):::plan
    end

    plan-implementation -- "implement, then..." --> stage

    %% Finalize phases
    subgraph finalize ["/finalize — QA Orchestrator"]
        direction TB

        subgraph p1 ["Phase 1 — Stage & Test"]
            stage["1. Stage changes
2. Write missing tests"]:::git
        end

        subgraph p2 ["Phase 2 — Simplify Code"]
            simplify-code([/simplify-code]):::review
        end

        subgraph p3 ["Phase 3 — Code Review"]
            cr["1. Run /review-code
2. Simplify review fixes
3. Test and lint"]:::review
        end

        subgraph p4 ["Phase 4 — Self-Improve"]
            self-improve([/self-improve]):::know
        end

        subgraph p5 ["Phase 5 — Commit"]
            commit-staged([/commit-staged]):::git
        end

        subgraph p6 ["Phase 6 — Pull Request"]
            pr["1. /create-pr or /update-pr
2. /resolve-pr-comments"]:::git
        end

        stage --> simplify-code
        simplify-code --> cr
        cr --> self-improve
        self-improve --> commit-staged
        commit-staged --> pr
    end

    %% Simplify (multi-agent review)
    subgraph simplifycode ["/simplify-code — Multi-Agent Review"]
        sp-steps["1. Determine diff command
2. Launch 4 review agents
3. Fix issues"]:::review
    end

    simplify-code -. "runs review" .-> sp-steps

    %% Code review (reusable core)
    subgraph reviewcode ["/review-code — AI Review + Evaluation"]
        cr-peer([/peer-review]):::review -. "runs review" .-> codex([/codex]):::review --> cr-eval([/evaluate-findings]):::review
    end

    cr -. "runs review" .-> cr-peer

    %% Evaluate findings (confidence-based triage)
    subgraph evalfindings ["/evaluate-findings — Confidence-Based Triage"]
        ef-steps["1. Assess each finding
2. Devil's Advocate
3. Reconciliation
4. Present results"]:::review
    end

    cr-eval -. "triages findings" .-> ef-steps

    %% Debugging
    subgraph debugging ["/investigate — Root Cause Analysis"]
        inv-steps["1. Characterize
2. Isolate
3. Hypothesize
4. Test"]:::debug
        inv-steps -. "stuck after 2 cycles" .-> oracle([/oracle]):::debug
    end

    stage -. "test failures" .-> inv-steps

    %% Knowledge
    subgraph knowledge ["/self-improve — Self-Improvement"]
        si-steps["1. Detect Context
2. Scan Session
3. Filter
4. Route
5. Present
6. Execute"]:::know
        si-steps -. "skill-shaped lesson" .-> create-skill([/create-skill]):::know
        si-steps -. "out-of-scope fix" .-> note-improvement([/note-improvement]):::know
    end

    self-improve -. "has learnings" .-> si-steps

    classDef plan fill:#dcfce7,stroke:#22c55e,color:#14532d
    classDef review fill:#dbeafe,stroke:#3b82f6,color:#1e3a5f
    classDef debug fill:#ffedd5,stroke:#f97316,color:#7c2d12
    classDef know fill:#f3e8ff,stroke:#a855f7,color:#581c87
    classDef git fill:#fef9c3,stroke:#eab308,color:#713f12

    style planning fill:#f0fdf4,stroke:#22c55e,color:#14532d
    style finalize fill:#f8fafc,stroke:#3b82f6,color:#1e3a5f
    style simplifycode fill:#eff6ff,stroke:#3b82f6,color:#1e3a5f
    style reviewcode fill:#eff6ff,stroke:#3b82f6,color:#1e3a5f
    style evalfindings fill:#eff6ff,stroke:#3b82f6,color:#1e3a5f
    style debugging fill:#fff7ed,stroke:#f97316,color:#7c2d12
    style knowledge fill:#faf5ff,stroke:#a855f7,color:#581c87
    style p1 fill:#fefce8,stroke:#eab308,color:#713f12
    style p2 fill:#eff6ff,stroke:#3b82f6,color:#1e3a5f
    style p3 fill:#eff6ff,stroke:#3b82f6,color:#1e3a5f
    style p4 fill:#faf5ff,stroke:#a855f7,color:#581c87
    style p5 fill:#fefce8,stroke:#eab308,color:#713f12
    style p6 fill:#fefce8,stroke:#eab308,color:#713f12
```
## Quick Start

### Prerequisites

| Tool | What it's for | Install |
|---|---|---|
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | AI coding agent that runs Turbo skills | `npm install -g @anthropic-ai/claude-code` |
| [GitHub CLI](https://cli.github.com/) | PR creation, review comments, repo queries | `brew install gh` |
| [Codex CLI](https://github.com/openai/codex) | AI-powered code review in `/finalize` | `npm install -g @openai/codex` |

**Works best with:** Claude Code Max 5x, Max 20x, or Team plan with Premium seats (orchestrator workflows are context-heavy), ChatGPT Plus or higher (for codex review), and ChatGPT Pro or Business (for `/oracle`, where Pro models are the only ones that reliably solve very hard problems). That said, `/peer-review` and `/oracle` are designed as swappable puzzle pieces, so if you don't have access, replace them with alternatives that work for you.

### Automatic Setup (Recommended)

Open Claude Code and prompt:

```
Walk me through the Turbo setup. Read SETUP.md from the tobihagemann/turbo repo and guide me through each step.
```

Claude will install the skills, configure your environment, and walk you through each step interactively.

### Updating

Run `/update-turbo` in Claude Code to update all skills. It handles conflict detection, exclusion of custom skills, and cleanup of removed skills.

### Manual Setup

See [SETUP.md](SETUP.md) for the full guide, or follow the steps below.

#### 1. Install Skills

```bash
npx skills add tobihagemann/turbo --skill '*' --agent claude-code -g
```

Install all skills. Many depend on each other (e.g., `/finalize` orchestrates `/simplify-code`, `/peer-review`, `/evaluate-findings`, and more), so installing them individually will leave gaps in the workflows. See [skills.sh/docs](https://skills.sh/docs) for more on the skills CLI.

#### 2. Add `.turbo` to Global Gitignore

Some skills store project-level files in a `.turbo/` directory (specs, prompt plans, improvements). Add it to your global gitignore to keep project repos clean:

```bash
mkdir -p ~/.config/git
echo '.turbo/' >> ~/.config/git/ignore
```

This uses Git's standard XDG path (`$XDG_CONFIG_HOME/git/ignore`), which Git reads automatically without needing `core.excludesfile`. If `core.excludesfile` is already set, add `.turbo/` to that file instead.

#### 3. Allow All Skills

Orchestrator workflows like `/finalize` invoke many skills in sequence. Without allowlisting them, you'll get prompted for each one, breaking the flow.

Add all Turbo skills to the `permissions.allow` array in `~/.claude/settings.json`. Generate the entries from the Turbo repo:

```bash
gh api repos/tobihagemann/turbo/contents/skills --jq '.[].name' | sed 's/.*/"Skill(&)"/'
```

Merge the output into your existing `permissions.allow` array.

#### 4. Configure Context Tracking

Turbo workflows like `/finalize` consume significant context. Knowing how much context you have left prevents unexpected compaction mid-workflow.

Add this to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "jq -r '\"\\(.context_window.remaining_percentage | floor)% context left\"'"
  }
}
```

#### 5. Add Pre-Implementation Prep

Add this to your `~/.claude/CLAUDE.md` (create the file if it doesn't exist):

```markdown
# Pre-Implementation Prep

After plan approval (ExitPlanMode) and before making edits:
1. Run `/code-style` to load code style principles
2. Read all files referenced by the user in their request
3. Read all files mentioned in the plan
4. Read similar files in the project to mirror their style
```

#### 6. Disable Auto-Compact

Turbo's orchestrator workflows work best when you control compaction timing. Disable auto-compact in Claude Code via `/config`.

#### 7. Oracle Setup (Optional)

The `/oracle` skill requires additional setup (Chrome, Python, ChatGPT access). See the [oracle skill](skills/oracle/SKILL.md) for configuration via `~/.turbo/config.json`. If not set up, everything still works.

## The Main Workflow

The recommended way to use Turbo:

1. **Enter plan mode** and plan the implementation
2. **Approve the plan** (tip: clear context when approving to maximize room for implementation)
3. **Run `/finalize`** when you're done implementing

`/finalize` runs through these phases automatically:

1. **Stage & Test** — Stage changed files, write missing tests, run test suite
2. **Simplify Code** — Multi-agent review for reuse, quality, efficiency, clarity
3. **Code Review** — AI peer review, evaluate findings, apply fixes, re-test
4. **Self-Improve** — Extract learnings, route to CLAUDE.md / memory / skills
5. **Commit** — Formulate commit message, create commit
6. **Pull Request** — Create or update PR, optionally resolve review comments

### Context Management Tips

- **Disable auto-compact.** You want to control when compaction happens.
- **Run `/self-improve` before `/compact`.** Compaction loses conversational detail that `/self-improve` mines for lessons. Capture learnings first, then compact.
- **Keep >50% context free** before running `/finalize` (>40% may also work). If you're low, run `/self-improve`, then `/compact`.
- The status line from step 3 above makes this easy to track.

### Self-Improvement

`/self-improve` is another core skill. Run it anytime before your context runs out (it's also part of `/finalize` Phase 4). It scans the conversation for corrections, repeated guidance, failure modes, and preferences, then routes each lesson to the right place: project CLAUDE.md, auto memory, or existing/new skills. It routes lessons through Claude Code's built-in knowledge layers and, over time, makes Claude better at your specific project.

`/note-improvement` captures improvement opportunities that come up during work but are out of scope: code review findings you chose to skip, refactoring ideas, missing tests. These get tracked in `.turbo/improvements.md` so they don't get lost. Since `.turbo/` is gitignored, it doesn't clutter the repo.

## The Planning Pipeline (Optional)

For larger projects, Turbo offers a full spec-to-implementation pipeline. You can skip this entirely and jump straight to implementation + `/finalize`.

1. **Run `/create-spec`** — Guided discussion that produces a spec at `.turbo/spec.md`
2. **Run `/create-prompt-plan`** — Breaks the spec into context-sized prompts at `.turbo/prompts.md`
3. **For each prompt, open a new session:**
   1. Enter plan mode and run `/pick-next-prompt`
   2. Approve the plan (clear context to maximize room for implementation)
   3. Implement the changes
   4. `/compact` if needed, then `/finalize`

Each session handles one prompt. This keeps context focused and avoids running out mid-implementation.

## All Skills

### Orchestrators

| Skill | What it does |
|---|---|
| [`/finalize`](skills/finalize/SKILL.md) | Post-implementation QA: test, simplify, review, commit, PR |
| [`/review-feature-branch`](skills/review-feature-branch/SKILL.md) | Full branch review: code review + evaluation + optional finalization |
| [`/review-pr`](skills/review-pr/SKILL.md) | Full PR review: code review + PR comments + evaluation + optional finalization |

### Planning

| Skill | What it does |
|---|---|
| [`/create-spec`](skills/create-spec/SKILL.md) | Guided discussion that produces a spec at `.turbo/spec.md` |
| [`/plan-implementation`](skills/plan-implementation/SKILL.md) | Decompose work into sized, ordered implementation units |
| [`/create-prompt-plan`](skills/create-prompt-plan/SKILL.md) | Break a spec into context-sized implementation prompts |
| [`/pick-next-prompt`](skills/pick-next-prompt/SKILL.md) | Pick the next prompt from `.turbo/prompts.md` and plan it |
| [`/capture-context`](skills/capture-context/SKILL.md) | Capture session knowledge into the plan file before clearing context |

### Code Quality

| Skill | What it does |
|---|---|
| [`/code-style`](skills/code-style/SKILL.md) | Enforce mirror, reuse, and symmetry principles |
| [`/simplify-code`](skills/simplify-code/SKILL.md) | Multi-agent review for reuse, quality, efficiency, clarity |
| [`/review-code`](skills/review-code/SKILL.md) | AI code review + findings evaluation |
| [`/peer-review`](skills/peer-review/SKILL.md) | AI code review interface that delegates to `/codex` by default |
| [`/codex`](skills/codex/SKILL.md) | AI code review and task execution via codex CLI |
| [`/evaluate-findings`](skills/evaluate-findings/SKILL.md) | Confidence-based triage of review feedback |
| [`/find-dead-code`](skills/find-dead-code/SKILL.md) | Identify unused code via parallel analysis |

### Git & GitHub

| Skill | What it does |
|---|---|
| [`/commit-rules`](skills/commit-rules/SKILL.md) | Shared commit message rules and technical constraints |
| [`/stage-commit`](skills/stage-commit/SKILL.md) | Stage files and commit in one step |
| [`/commit-staged`](skills/commit-staged/SKILL.md) | Commit already-staged files with good message |
| [`/create-pr`](skills/create-pr/SKILL.md) | Draft and create a GitHub PR |
| [`/update-pr`](skills/update-pr/SKILL.md) | Update existing PR title and description |
| [`/fetch-pr-comments`](skills/fetch-pr-comments/SKILL.md) | Read-only summary of unresolved PR comments |
| [`/resolve-pr-comments`](skills/resolve-pr-comments/SKILL.md) | Evaluate, fix, and reply to PR comments |

### Debugging

| Skill | What it does |
|---|---|
| [`/investigate`](skills/investigate/SKILL.md) | Systematic root cause analysis for bugs and failures |
| [`/smoke-test`](skills/smoke-test/SKILL.md) | Launch the app and verify changes manually |
| [`/oracle`](skills/oracle/SKILL.md) | Consult ChatGPT when completely stuck (requires setup) |

### Knowledge & Maintenance

| Skill | What it does |
|---|---|
| [`/self-improve`](skills/self-improve/SKILL.md) | Extract session learnings to CLAUDE.md, memory, or skills |
| [`/note-improvement`](skills/note-improvement/SKILL.md) | Capture out-of-scope improvement ideas for later |
| [`/create-skill`](skills/create-skill/SKILL.md) | Create or update a skill with proper structure |
| [`/update-npm-deps`](skills/update-npm-deps/SKILL.md) | Smart npm dependency upgrades with breaking change research |
| [`/update-turbo`](skills/update-turbo/SKILL.md) | Update Turbo skills with conflict detection and cleanup |

## License

Distributed under the MIT License. See the [LICENSE](LICENSE) file for details.
