---
name: consult-codex
description: "Multi-turn consultation with Codex CLI for second opinions, brainstorming, or collaborative problem-solving. Use when the user asks to \"consult codex\", \"ask codex\", \"get codex's opinion\", \"brainstorm with codex\", \"discuss with codex\", or \"chat with codex\"."
---

# Consult Codex

Multi-turn consultation with Codex CLI. Maintains a conversation across multiple turns using session persistence, unlike single-shot `/codex-exec`.

## Step 1: Gather Context

Identify the 2-5 files most relevant to the problem. Formulate a clear, specific question. Include what has been tried and relevant constraints.

## Step 2: Start Session

Run `codex exec` with `-o` to capture the response cleanly. Default to `-s read-only` for safety. Use `-s workspace-write` when the consultation requires running code or reading files outside the workspace.

**All `codex` Bash calls require `dangerouslyDisableSandbox: true`** (network access to OpenAI API). Use `.turbo/` as the temp directory — it is in the working directory (sandbox-writable), gitignored, and avoids `$TMPDIR` path mismatches between sandbox and non-sandbox mode.

**Non-piped `codex exec` invocations require `< /dev/null`** to avoid hanging on stdin. Codex reads from stdin whenever stdin is non-TTY, and in subprocess contexts the harness leaves stdin connected to a pipe that never EOFs — codex blocks forever, printing only `Reading additional input from stdin...`. The piped form (`cat file | codex exec "..."`) is safe — `cat` closes the pipe after the file.

Generate a random session tag at the start to keep files unique for parallel use, and print the absolute path prefix it produces:

```bash
CODEX_TAG=$(head -c 4 /dev/urandom | xxd -p) && mkdir -p "$PWD/.turbo/codex" && echo "$PWD/.turbo/codex/$CODEX_TAG"
```

Substitute the printed value for `<prefix>` in every later command of this consultation. Shell variables do not survive between Bash tool calls, and an earlier `cd` in a compound command leaves the session in a different directory, so a relative path resolves against that directory instead.

Number the `-o` file by turn — `<prefix>-1.txt` for the first, `<prefix>-2.txt` for the next, and so on. A turn that reuses the previous turn's path finds that turn's complete answer waiting there, so a read landing before the current turn finishes returns the wrong answer with nothing to mark it as stale.

```bash
codex exec -s read-only -o "<prefix>-1.txt" "<question>" < /dev/null
```

### Prompt Shaping

Structure the question using XML tags for clearer Codex responses:

- `<task>`: The concrete question and relevant context.
- `<compact_output_contract>`: Desired output shape and brevity requirements.
- `<structured_output_contract>`: Same purpose but for structured/schema responses.
- `<grounding_rules>`: When claims must be evidence-based (review, research, root-cause analysis).
- `<dig_deeper_nudge>`: Push past surface-level findings to check for second-order failures.
- `<verification_loop>`: When correctness matters — ask Codex to verify before finalizing.
- `<merit_only>`: When a recommendation is wanted, bar answers that appeal to scope.
- `<style_constraints>`: When the answer must follow a house style, name the shapes that style forbids.

Example prompt for a diagnosis question:

```
<task>Diagnose why the auth middleware rejects valid tokens after the session refactor.</task>
<compact_output_contract>Return: (1) most likely root cause, (2) evidence, (3) smallest safe next step.</compact_output_contract>
<grounding_rules>Ground every claim in the provided context or tool outputs. Label hypotheses explicitly.</grounding_rules>
```

For correctness-critical questions, add `<verification_loop>` asking Codex to verify its answer before finalizing.

When a recommendation is wanted, add `<merit_only>`: state that "out of scope" or "leave it alone" is not an acceptable argument on its own, and that recommending no change must be justified on technical merit. Pair it with `<compact_output_contract>` demanding one pick per decision, the reasoning, and the strongest counterargument to that pick, with hedging across options ruled out.

When the consultation is a prose rewrite bound by a house style, add `<style_constraints>` naming the shapes that style forbids in the first prompt, so they do not have to be corrected across follow-up turns. Common ones: prefixing a summary with a grammatical subject the convention omits, expanding a pronoun to its full noun phrase at every occurrence, and splitting a sentence so a condition is restated in both halves.

Keep prompts compact, with tight output contracts. One clear task per Codex turn.

For context that does not belong in the argument, write a context file with the Write tool and pipe it via stdin. The prompt stays as the argument, context pipes in as `<stdin>` automatically:

```bash
cat "<prefix>-ctx.txt" | codex exec -s read-only -o "<prefix>-1.txt" "<question>"
```

A `cat` that fails does not stop the run: codex executes on the bare prompt, burns the full timeout, and returns nothing. Read the stderr chrome for the `cat` error rather than waiting on the `-o` file.

Route text you did not author through this channel whatever its size — a diff, file contents, a code comment, a plan or spec, third-party feedback, command output. Keep backticks and `$` out of the quoted argument even in text you wrote, since both stay live inside it. Write the context file with the Write tool so nothing is interpreted on the way in.

Parse the `session id:` line from the CLI output. This UUID is needed for follow-up turns.

The `session id:` line appears only in the stderr chrome, never on stdout and never in the `-o` file. When a follow-up turn may be needed, do not discard stderr with `2>/dev/null` or capture stdout alone — either silently drops the session id and makes `resume` impossible. If output must be truncated, `2>&1 | grep` for `session id:` so the id is always retained.

Run via the Bash tool as a foreground call (`timeout: 600000`, the Bash maximum; do not set `run_in_background`) per turn. A larger timeout is not honored: the harness backgrounds the call immediately and hard-kills codex at 600s, truncating its output. A consult that outlives a valid timeout is normally force-backgrounded: the result carries a task ID and the run continues to completion, so recover the answer by reading the current turn's `-o` file, then reading it again once the `<task-notification>` reports completion. For a backgrounded run the `session id:` is in the task's output file rather than the immediate tool result, so `grep` that file for it when a follow-up turn is needed. An over-max timeout also returns a task ID but truncates the output at 600s, so check that file for a complete answer rather than assuming the run finished. Rarely the result is an error exit (code 143) reading `Command timed out after <duration>` with no task ID; codex was hard-killed and the `-o` file was never written, so `resume` the session id from Step 2 with the next turn's `-o` path and an instruction to answer immediately, rather than re-running the consult from scratch. Never wait with `Monitor`, and never return the task ID or an interim file snapshot as the result — each is a false-empty return.

## Step 3: Read and Evaluate Response

The `-o` file contains only Codex's response (cleaner than stdout, which includes CLI chrome and tool-use logs). Read the current turn's `-o` file. If the output is too large for the Read tool, read stdout from the Bash tool result instead.

Assess whether:
- The answer is sufficient and actionable
- Follow-up questions would improve the answer
- The response contradicts known project facts (verify before accepting)
- The recommendation would violate a documented constraint (follow up rather than discarding or adopting it)

If no follow-up is needed, skip to the Synthesize step.

## Step 4: Follow Up

Resume the session with the parsed session ID (not `--last`, which is unsafe for parallel use). `<turn>` continues the count from Step 2, so the first follow-up writes `<prefix>-2.txt`:

```bash
codex exec resume <session-id> -o "<prefix>-<turn>.txt" "<follow-up question>" < /dev/null
```

When the follow-up carries text you did not author, write it to a file with the Write tool and pass `-` so the prompt is read from stdin instead:

```bash
cat "<prefix>-followup.txt" | codex exec resume <session-id> -o "<prefix>-<turn>.txt" -
```

With `-`, stdin is the whole prompt rather than a `<stdin>` block appended to an argument, so instruction and context share the one file. Leave off `< /dev/null` here — the pipe supplies stdin, and `cat` sends EOF.

The `-s` flag is not available for `resume`. It inherits sandbox settings from the original session.

When the recommendation would violate a documented constraint, quote the constraint back and ask Codex to argue it out: whether the constraint is sound or was set without the problem Codex identified in view, whether that problem is reachable given code Codex may not have accounted for, and what the best fix that respects the constraint is. Ask it to quantify the exposure rather than assert it, and say that reversing its prior recommendation is acceptable.

Return to Step 3. Cap at 5 turns to prevent runaway conversations.

## Step 5: Synthesize

Summarize the key insights from the consultation. Cross-reference suggestions with project documentation and conventions before applying. Codex suggestions are starting points, not guaranteed solutions.

When the consultation rewrote prose rather than answering a question, check the rewrite against the source yourself before adopting it. Treat its own report that the rewrite is faithful as a claim awaiting verification. Verify the source's own factual claims against what they describe, since a rewrite can be faithful to a source that was itself wrong. Read for these drift shapes in the rewrite:

- a tense change that promotes a capability into an event
- a compression that promotes a hedge into a fact, or flattens out the reasoning that made a sentence worth keeping
- a rule promoted into an enforcement claim
- a narrowing that recasts an absence of information as a limitation of what it describes
- a figure or claim re-attributed to a different subject than the source gave it, the predicate left intact
- an inverted direction in a described mapping
- a term renamed in prose, drifting from the identifier it documents
- a precise word swapped for a vaguer one, or a dropped modifier that carried the argument
- dropped markup or function words, articles included
- a split that separates clauses whose relationship is the point
- a split that strands a pronoun on the wrong noun

Take the plainer sentences and keep the load-bearing why.

When the consultation was opened from a pending question, resolve that question with the answer in hand, re-asking the user when the choice stays theirs. Then use the TaskList tool and proceed to any remaining task.
