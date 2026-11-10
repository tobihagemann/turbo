# Past-Session Sweep

Propose a cutoff first: take the newest modification time in the memory directory from Step 1, state it, then use `AskUserQuestion` to confirm sweeping from it or sweeping the whole history. That timestamp records a memory write rather than a completed sweep: present it as a bound on the work, never as what a previous run covered. When the directory is absent or empty, sweep the whole history without asking.

Spawn a single subagent (`model: "opus"`, no `name`). Wait for it to report before continuing; do not relaunch it if it has not yet reported. The subagent's prompt must include:

1. The absolute path of the project root
2. The confirmed cutoff as an ISO-8601 timestamp, or that there is none
3. The absolute path of [transcript-miner.md](transcript-miner.md), with an instruction to read it and follow its sweep process

Treat the returned items as raw evidence for the lesson scan.
