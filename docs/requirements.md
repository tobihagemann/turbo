# Requirements

[← Back to Turbo](../README.md) · [Workflow guide](workflows.md) · [Prompt examples](examples.md) · [Customization](customization.md)

## Accounts and Tools

- **A coding agent plan with headroom.** Pipeline workflows are context-heavy. Both editions work best with higher-tier plans, such as Claude Max or ChatGPT Pro.
- **The other coding agent, for peer review.** `/finalize` uses it through [`/peer-review`](../claude/skills/peer-review/SKILL.md). The Claude edition uses the Codex CLI, which needs ChatGPT Plus or higher. The Codex edition uses the Claude Code CLI, which needs a Claude subscription.
- **[GitHub CLI](https://cli.github.com/)** (required). Powers PR and issue operations.
- **Node.js and `jq`.** Setup uses them to install the CLIs and copy the skills.
- **ChatGPT Pro or Business** (optional). Useful for [`/consult-oracle`](../claude/skills/consult-oracle/SKILL.md), which asks ChatGPT when you're completely stuck. The Pro tier is what reliably solves very hard problems.

[`/peer-review`](../claude/skills/peer-review/SKILL.md) and [`/consult-oracle`](../claude/skills/consult-oracle/SKILL.md) are designed to be swapped. If you don't have access, [replace them](customization.md#the-puzzle-piece-philosophy) with alternatives that work for you.

## What Setup Changes

The agent asks before changing user-level configuration. Setup touches:

- `~/.turbo/`: a clone of this repo and a `config.json` for update state, skill exclusions, and optional settings
- Your skills directory: `~/.claude/skills/` (Claude Code) or `~/.agents/skills/` (Codex)
- Your global instruction file: a few behavioral rules from `ADDITIONS.md` added to `~/.claude/CLAUDE.md` or `~/.codex/AGENTS.md` (see [Harness Instructions](customization.md#harness-instructions))
- Your global gitignore: `.turbo/` added, so plans and reports stay out of your repos
- Harness settings: a context status line and task tracking in `~/.claude/settings.json` (Claude Code), or opt-in feature flags and a raised subagent limit in `~/.codex/config.toml` (Codex)
- Optional steps you can decline: the oracle's own Chrome profile and a ChatGPT sign-in, and for Codex, importing Claude Code auto memory

The [Claude Code setup](../claude/SETUP.md) and [Codex setup](../codex/SETUP.md) guides list every step.

## Works Best With

Turbo builds on infrastructure your project already has:

- **Tests:** The [`/polish-code`](../claude/skills/polish-code/SKILL.md) loop inside [`/finalize`](../claude/skills/finalize/SKILL.md) runs your test suite and reviews coverage gaps. Without tests, there's no safety net. If your project has none, [`/smoke-test`](../claude/skills/smoke-test/SKILL.md) can fill the gap by launching your app and driving it through the [testing tools](#browser-and-ui-testing-tools) in the same loop, but real tests are always better.
- **Linters and formatters:** The [`/polish-code`](../claude/skills/polish-code/SKILL.md) loop runs your formatter and linter before code review. If you don't have one, style issues slip through.
- **Pre-commit hooks:** When [`/finalize`](../claude/skills/finalize/SKILL.md) commits, it triggers any pre-commit hooks you have configured and fixes hook failures before retrying. If your project uses tools like `husky`, `lint-staged`, or `pre-commit`, Turbo works with them automatically.
- **Existing analysis tools:** Skills like [`/find-dead-code`](../claude/skills/find-dead-code/SKILL.md) and [`/assess-technical-debt`](../claude/skills/assess-technical-debt/SKILL.md) lean on integrated tools (`knip`, `vulture`, `periphery`, `lizard`, `jscpd`) when your project already has them.

## Browser and UI Testing Tools

The [testing skills](workflows.md#browser-and-ui-testing) drive your app through these tools. The setup guides cover enabling them.

**Claude Code:**

- **[`/agent-browser`](https://github.com/vercel-labs/agent-browser) skill:** Browser automation with the most control for web app testing. Offered during setup.
- **`claude-in-chrome` MCP:** Built-in browser automation using your real Chrome browser. Used when `/agent-browser` is not installed.
- **`computer-use` MCP:** Built-in screen control for native app and UI testing on macOS.

**Codex** (both plugins ship in Codex's `openai-bundled` marketplace):

- **`browser-use@openai-bundled` plugin:** Browser automation for web app testing.
- **`computer-use@openai-bundled` plugin:** Screen control for native app and UI testing on macOS.
