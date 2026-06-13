---
name: codex-exec
description: "Run autonomous task execution using the codex CLI. Use when the user asks to \"codex exec\", \"run codex exec\", \"execute a task with codex\", or \"delegate to codex\"."
---

# Codex Exec

Autonomous task execution via the codex CLI. Runs non-interactively. Progress streams to stderr; final result on stdout.

```bash
codex exec "task description" < /dev/null
```

For large context, pipe it via stdin. The prompt stays as the argument, context is passed as `<stdin>` automatically:

```bash
cat context.txt | codex exec "question about the context"
```

## Sandbox

**All `codex` Bash calls require `dangerouslyDisableSandbox: true`** (network access to OpenAI API). Without it, codex crashes with an `Operation not permitted` panic from the `system-configuration` crate before the model runs.

## Stdin Gotcha

Codex reads from stdin whenever stdin is non-TTY (per `codex exec --help`: "If stdin is piped and a prompt is also provided, stdin is appended as a `<stdin>` block"). In subagent and subprocess contexts the harness leaves stdin connected to a pipe that never EOFs, so a bare `codex exec "..."` hangs forever, printing only `Reading additional input from stdin...`.

Always redirect stdin on non-piped invocations:

```bash
codex exec "task description" < /dev/null
```

The piped form (`cat context.txt | codex exec "..."`) is safe — `cat` closes the pipe after the file, sending EOF.

## Synchronous Execution

Run codex via the Bash tool as a foreground call (do not set `run_in_background`). Set `timeout: 600000`, the Bash maximum. A larger value is not honored: the harness backgrounds the call immediately and hard-kills codex at 600s, truncating its output. Within a valid timeout, codex runs foreground and returns its result synchronously when it finishes in time.

If codex outlives the timeout, the harness force-backgrounds it (returning a task ID and an output file path) and the run continues to completion uninterrupted. Recover it by reading the output file: `Read` the path, then `Read` it again once the `<task-notification>` reports completion. Never wait with `Monitor` (it returns immediately, and events that arrive after your final text are dropped), and never return the task ID, an interim file snapshot, or `"Waiting for codex to finish"` as the result — each is a false-empty return.

## Permission Levels

| Level | Flag | When to Use |
|-------|------|-------------|
| Read-only | `--sandbox read-only` | Analysis, code reading, generating reports |
| Workspace write | `--sandbox workspace-write` | Editing files within the project |
| Full access | `--sandbox danger-full-access` | Installing packages, running tests, system operations |
| Full auto | `--full-auto` | Combined with a sandbox level for unattended execution |

Omitting `--sandbox` falls back to the codex config and project trust level (trusted projects run workspace-write), so always pass the flag explicitly.

For fix or implementation tasks, default to `--sandbox workspace-write --full-auto` so Codex can edit files without confirmation prompts. Use `--sandbox read-only` for analysis or research tasks.

## Options

| Option | Description |
|--------|-------------|
| `--full-auto` | Allow file edits without confirmation prompts |
| `--sandbox <level>` | Permission level: `read-only`, `workspace-write`, `danger-full-access` |
| `--json` | JSON Lines output (progress + final message) |
| `-o <path>` | Write final message to a file |
| `--output-schema <path>` | Enforce JSON Schema on the output |
| `--ephemeral` | No persisted session files |
| `--skip-git-repo-check` | Bypass git repository requirement |

## Prompt Shaping

Codex uses XML tags in its own context scaffolding, so the model parses them natively. Structure prompts with XML tags for clearer responses:

- `<task>`: The concrete job and relevant context.
- `<structured_output_contract>`: Required output shape, ordering, and format.
- `<compact_output_contract>`: Same purpose but for concise prose responses.
- `<grounding_rules>`: When claims must be evidence-based.
- `<dig_deeper_nudge>`: Push past surface-level findings to check for second-order failures.
- `<verification_loop>`: When correctness matters — ask Codex to verify before finalizing.

Keep prompts compact, with tight output contracts. One clear task per exec call.

## Parallel Execution

Codex supports parallel sub-agents via `spawn_agent` / `wait_agent`. The model will not fan out unless the prompt explicitly requests it. See [references/parallel-execution.md](references/parallel-execution.md) for patterns and limitations.

## Interpreting Results

- Exec output is a starting point, not a guaranteed solution
- Cross-reference suggestions with project documentation and conventions
- Test incrementally rather than applying all changes at once
- For file-editing tasks, always review the diff before committing
