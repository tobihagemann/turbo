---
name: recall-rationale
description: "Recall why a past change was made, drawing on Codex session history when available and falling back to commit diff and surrounding code. Use when the user asks to \"recall the rationale\", \"find the rationale\", \"look up the rationale\", \"why did I do X\", \"why did we do X\", \"why was this changed\", or \"find the transcript for this commit\"."
---

# Recall Rationale

Recover why a change was made. Prefer Codex session history when it can be found; otherwise derive the explanation from git history and current code.

## Inputs

Accept any of:

- A commit SHA
- A file path, optionally with a line number (`<path>:<line>`)
- A reviewer question plus surrounding context
- A passage with no commit behind it, because the project is not a git repository or the change is uncommitted

If only a file is given, use `git blame` to resolve the commit that last touched the line.

## Step 1: Resolve the Commit

Resolve the target commit:

```bash
git rev-parse <sha>
git blame -L <line>,<line> -- <path>
```

Collect the commit subject, changed files, and relevant diff:

```bash
git show --stat --oneline <sha>
git show -- <path>
```

When there is no commit to resolve, because the project is not a git repository or `git blame` finds no commit for the line (it reports `Not Committed Yet`, or fails because the file is untracked), skip the git commands and carry a distinctive stretch of the passage's current text into Step 2, taken from a single line and free of quotes and backslashes, which session files store escaped.

## Step 2: Search Codex Session History

If Codex session files are available, search them for the commit SHA, touched file paths, branch name, and distinctive user request text. Without a commit, search for the passage text instead, list the matching files with `rg -l`, and keep only those whose first-line `session_meta` record has a `cwd` at or inside the project directory.

Write the patterns to a file with `apply_patch`, one per line, then match them literally:

```bash
rg -F -f <pattern-file> ~/.codex/sessions
```

`-F` is required, not just safer: an unescaped `$` inside request text is a regex anchor and silently drops the match.

Read only the smallest relevant transcript excerpts. Prefer sessions close to the commit time and sessions that mention both the file and the task. Without a commit, disregard matches from this search itself (the pattern-file write and the search commands), prefer sessions whose tool calls carry the passage and that mention it often, break ties by recency, and read around the chosen session's last mention when the question is about the passage's current state.

If no matching session is found, continue with the fallback path.

## Step 3: Synthesize

If session rationale was found:

- Lead with the **why**. The diff already shows the what.
- Quote or paraphrase only the relevant rationale.
- Keep the explanation to one or two paragraphs.

If no session rationale was found:

- Read the commit diff, when there is one, and the surrounding current code.
- Infer the most likely rationale from the code, tests, plan/spec artifacts, and PR context.
- Mark the output as fallback-derived.

## Step 4: Output

When session rationale was found:

```markdown
**Commit:** <short-sha> — <subject>
**Session:** <session reference>

<one or two paragraphs of rationale>
```

When no session rationale was found:

```markdown
**Commit:** <short-sha> — <subject>
**Session:** none found

<fallback explanation derived from git history and current code>
```

In either shape, without a commit, write the first line as `**Commit:** none (not a git repository)` or `**Commit:** none (uncommitted)`.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

## Rules

- Treat session excerpts as evidence, not ground truth.
- Do not read full transcript files unless excerpts are insufficient.
- If current code contradicts a remembered rationale, note the discrepancy.
