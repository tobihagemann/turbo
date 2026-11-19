# Past-Session Sweep

Propose a cutoff first. Resolve the canonical project root as the Git top-level containing the working directory, or the physical working directory outside a repository. Then take the first memory target below that resolves. When the resolved target is absent or holds nothing, treat it as **No target**. A memory timestamp records a write rather than a completed sweep: present it as a bound on the work, never as what a previous run covered.

- **Synced Claude Code source memory** — applies when `codex.sharedClaudeAutoMemory` in `~/.turbo/config.json` is exactly `true`; treat `false`, a missing or invalid key, and an unreadable file as not opted in. Resolve its directory in this order:
  1. The expanded `autoMemoryDirectory` override from Claude Code's managed settings, then project-local `.claude/settings.local.json`, then the user `<Claude config home>/settings.json`. Exclude checked-in `.claude/settings.json`.
  2. Otherwise `projects/<project key>/memory/` under `CLAUDE_CONFIG_DIR` when set or `~/.claude/`. The project key is the name of the resource directory under `~/.codex/memories/extensions/external_agent_import/resources/` whose `scope.json` matches the canonical project root.

  Take its newest modification time and state that Claude Code writes also advance it, so it may omit unswept Codex sessions. Use `request_user_input` with whole Codex history as the recommended option and that timestamp as the bounded option. When that gate cannot reach the user, sweep the whole Codex history and say so in the report.
- **Harness memory update target** — a project-specific memory file or additive note intake that the active harness instructions explicitly name for memory updates. Take its newest modification time, state it, then use `request_user_input` to confirm sweeping from it or sweeping the whole history. When that gate cannot reach the user, sweep from the proposed cutoff and say so in the report.
- **No target** — sweep the whole history without asking.

Spawn a single sub-agent (inherited model defaults). The sub-agent's prompt must include:

1. The absolute path of the project root
2. The confirmed cutoff as an ISO-8601 timestamp, or that there is none
3. An instruction to read `<this skill's directory>/references/transcript-miner.md` and follow its sweep process

Treat the returned items as raw evidence for the lesson scan.
