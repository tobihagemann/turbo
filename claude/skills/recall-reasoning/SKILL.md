---
name: recall-reasoning
description: "Recall the reasoning behind a past change by locating the Claude Code transcript that produced it. Use when the user asks to \"recall reasoning\", \"find reasoning\", \"look up reasoning\", \"recall implementation reasoning\", \"find the rationale\", \"why did I do X\", \"recall from transcripts\", or \"find the transcript for this commit\"."
---

# Recall Reasoning

Locate the Claude Code transcript that produced a given change and extract the implementer's reasoning. Useful for answering reviewer questions, writing post-hoc explanations, or recovering forgotten context.

## Inputs

Accept any of:

- A commit SHA
- A file path, optionally with a line number (`<path>:<line>`)
- A reviewer question plus surrounding context (file and line)
- A passage with no commit behind it, because the project is not a git repository or the change is uncommitted

If only a file is given, `git blame` resolves the commit that last touched the line.

## Step 1: Resolve the Commit and Run the Script

Call `scripts/find_transcript.py` with either `--commit <sha>` or `--file <path>[:<line>]`. Pass `--cwd /path/to/repo` when searching a different repo than the current working directory.

```bash
python3 <skill-dir>/scripts/find_transcript.py --file <path>:<line>
python3 <skill-dir>/scripts/find_transcript.py --commit <sha>
```

When there is no commit to resolve, because the project is not a git repository or `--file` returns `no-commit` for an uncommitted line, run `--phrase` with a distinctive stretch of the passage's current text, taken from a single line, instead. It skips git, ranks the project's transcripts by how often they handle the phrase, and returns the same JSON with `commit: null`.

```bash
python3 <skill-dir>/scripts/find_transcript.py --phrase "<distinctive text from the passage>"
```

With `--commit` or `--file`, the script:

1. Resolves the commit via `git rev-parse` or `git blame`
2. Enumerates directories under the effective Claude configuration home's `projects/` tree and filters their transcripts by authoritative `cwd` records, covering path encoding, truncation, collisions, and subdirectory launches
3. Ranks candidate transcripts whose mtime is within `--window-days` of the commit (default 14)
4. Scores candidates by mentions of touched files and tool-use edits on them
5. Extracts cleaned user prompts and substantive assistant text from the top candidates

The JSON output has `status`, `commit`, `project_dir` (the top candidate's directory when matched), `project_dirs` (directories with matching `cwd` records, limited to the time window when there is a commit), and `candidates` with `session_id`, `score`, `match_reasons`, and `excerpts`.

Status values:

- `ok` — candidates returned
- `no-commit` — couldn't resolve a commit
- `no-transcripts` — the effective Claude configuration home has no project transcript directories
- `no-match` — transcripts exist but none match the touched files in the window, or none mention the phrase

## Step 2: Read and Synthesize

If `status` is `ok`:

1. Start with the top candidate (highest score). Read its excerpts first.
2. If the excerpts already explain the change, stop. If they are thin or ambiguous, read the full transcript at `jsonl_path` directly for more context.
3. Ignore candidates with low scores or scores far below the top — they are false positives.
4. When the reasoning spans multiple excerpts, quote the most specific one.
5. In phrase mode, the `last match at` reason marks the last time the session handled the passage. When the question is about the passage's current state, read the transcript around that point.

Synthesize a concise summary tied to the question being answered:

- Lead with the **why**. The diff already shows the what.
- Quote the implementer's own words when they already say it well.
- Keep it to one or two paragraphs. Don't narrate the whole session.

If `status` is anything other than `ok`, report that no reasoning was found and fall back to reading the commit diff, when there is one, and the surrounding code. Say so explicitly so it's clear whether the answer still holds up.

## Step 3: Output

Return the reasoning in this shape:

```
**Commit:** <short-sha> — <subject>
**Transcript:** <session-id> (score <N>)

<one or two paragraphs of reasoning, quoting the implementer where useful>
```

If no transcript was found:

```
**Commit:** <short-sha> — <subject>
**Transcript:** none found (<status>)

<fallback explanation derived from reading the commit and current code>
```

In either shape, without a commit, write the first line as `**Commit:** none (not a git repository)` or `**Commit:** none (uncommitted)`.

Then use the TaskList tool and proceed to any remaining task.

## Rules

- Treat excerpts as evidence, not ground truth. The implementer's intent at the time may have changed. If the current code contradicts an excerpt, note the discrepancy.
- Only read the full `.jsonl` if the excerpts are insufficient. These files are large.
- Never quote noise prefixes like `<command-message>` or skill-loading stubs. The script filters these out, but stay alert if reading a transcript directly.
- If multiple candidates have similar high scores, name both and prefer the one whose time window contains the commit, or, without a commit, the one whose tool calls carry the phrase.
