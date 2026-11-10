# Past-Session Sweep

Propose a cutoff first. How depends on which Auto memory target Step 1 resolved. A memory timestamp records a write rather than a completed sweep: present it as a bound on the work, never as what a previous run covered.

- **Synced Claude Code source memory** — take its newest modification time and state that Claude Code writes also advance it, so it may omit unswept Codex sessions. Use `request_user_input` with whole Codex history as the recommended option and that timestamp as the bounded option. When that gate cannot reach the user, sweep the whole Codex history and say so in the report.
- **Harness memory update target** — take its newest modification time, state it, then use `request_user_input` to confirm sweeping from it or sweeping the whole history. When that gate cannot reach the user, sweep from the proposed cutoff and say so in the report.
- **No target** — sweep the whole history without asking.

Spawn a single sub-agent (inherited model defaults). The sub-agent's prompt must include:

1. The absolute path of the project root
2. The confirmed cutoff as an ISO-8601 timestamp, or that there is none
3. An instruction to read `<this skill's directory>/references/transcript-miner.md` and follow its sweep process

Treat the returned items as raw evidence for the lesson scan.
