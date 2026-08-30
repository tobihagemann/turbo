# Transcript Miner Guidelines

Recover session evidence that context compaction dropped, from the transcript Claude Code persists on disk. Read and report; change nothing.

## Mining Process

### 1. Locate the Transcript

Claude Code writes every session to `<Claude config home>/projects/<encoded-cwd>/<session-id>.jsonl`, where the config home is `CLAUDE_CONFIG_DIR` when set and `~/.claude` otherwise. The key replaces every character outside `A-Za-z0-9` with `-`; long keys may be truncated and hashed. A session started in a subdirectory uses its own key. Use a harness-provided project directory only when it has this transcript-storage shape; a custom auto-memory directory is independent. Otherwise match the normal encoded project root as a prefix:

```bash
ROOT="<project root>"
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
if [[ "$CLAUDE_HOME" == "~/"* ]]; then CLAUDE_HOME="$HOME/${CLAUDE_HOME:2}"; fi
ls -t "$CLAUDE_HOME/projects/$(printf '%s' "$ROOT" | sed 's|[^A-Za-z0-9]|-|g')"*/*.jsonl | head -5
```

The current session is the most recently modified file. Confirm it by grepping for the distinctive phrase you were given, using a short fragment that sits on one line and contains no quote characters: the stored text is JSON-escaped. When the phrase is absent, try the next file down, since concurrent sessions in the same project share the directory. When no prefix match exists, enumerate the most recently modified project directories and verify candidates from their recorded `cwd`; this covers truncated keys and encoding collisions without guessing the internal hash.

If the directory or a matching transcript cannot be found, report that in one line and stop.

### 2. Extract the User Side

Each line is a record with `type`, `timestamp`, `sessionId`, and `isSidechain`. Conversation records are typed `user` and `assistant` and carry `message.content`, either a string or a list of parts typed `text`, `tool_use`, or `tool_result`. The remaining types hold harness state.

Two filters matter. Records with `isSidechain: true` are subagent conversations where the user never speaks. Many user records hold harness-injected text that reads like user speech: slash command wrappers, bash I/O, system reminders, cross-session notifications, and skill-loading preambles. Those wrappers still carry the arguments the user typed after a slash command, so salvage the arguments instead of dropping the record whole.

A message the user types while a tool call is in flight never becomes a `user` record. It persists as an `attachment` record whose `attachment.type` is `queued_command`, holding the text in `attachment.prompt` in the same string-or-parts shape. Take the ones whose `attachment.origin.kind` is `human`, which excludes the harness notifications queued the same way. The record sits at the point of delivery and carries the timestamp of the moment the user typed it.

An answer given through `AskUserQuestion` produces no text part either. The `user` record carrying it holds a `toolUseResult.answers` object mapping each question to the answer, and a `toolUseResult.annotations` object holding free text the user typed. When they typed instead of selecting an option, `answers` holds a placeholder and the words live only in `annotations`, so read both. Each answer is either an option label the user selected or the free text they typed, so both are their own words. Read these objects rather than the `tool_result` part rendering the same content as prose: its opening wording varies across harness versions, and its closing harness instruction would otherwise land in the quoted evidence.

Print the real user turns:

```bash
python3 - "<transcript path>" <<'PY'
import json, re, sys

NOISE = ("<command-message>", "<command-name>", "<local-command-stdout>",
         "<local-command-caveat>", "<bash-input>", "<bash-stdout>", "<bash-stderr>",
         "<system-reminder>", "<task-notification>", "Base directory for this skill:",
         "Called the ", "Caveat: The messages below were generated",
         "(Re-invocation of", "Skill /", "Another Claude session sent")

ARGS = re.compile(r"<command-args>(.*?)</command-args>|\nARGUMENTS:\s*(.*)\Z", re.S)

# Stored in answers when the user typed free text instead of selecting an
# option; the text itself lands in annotations, so answers alone loses it.
NOTES_ONLY = "(notes only)"


def typed_text(text):
    """Return what the user actually typed, or None for pure harness noise."""
    if not text.startswith(NOISE):
        return text
    salvaged = [g.strip() for m in ARGS.finditer(text) for g in m.groups() if g]
    return "\n".join(salvaged) or None


def elide(text):
    """Keep the opening and the operative ending of an unusually long turn."""
    if len(text) <= 6000:
        return text
    return text[:4000] + "\n[...]\n" + text[-2000:]


def flatten(content):
    """Join the text of a payload that is either a string or a list of parts."""
    if isinstance(content, str):
        parts = [content]
    else:
        parts = [p.get("text", "") for p in content or []
                 if isinstance(p, dict) and p.get("type") == "text"]
    return "\n".join(p for p in parts if p).strip()


def answered(rec):
    """Join a record's AskUserQuestion answers as "<question>"="<answer>" pairs."""
    result = rec.get("toolUseResult")
    answers = result.get("answers") if isinstance(result, dict) else None
    if not isinstance(answers, dict):
        return ""
    notes = result.get("annotations")
    notes = notes if isinstance(notes, dict) else {}
    pairs = []
    for question, answer in answers.items():
        note = notes.get(question)
        note = note.get("notes") if isinstance(note, dict) else None
        if note and answer == NOTES_ONLY:
            answer = note
        elif note:
            answer = f"{answer} / {note}"
        pairs.append(f'"{question}"="{answer}"')
    return "\n".join(pairs)


seen = ()
for line in open(sys.argv[1], encoding="utf-8"):
    try:
        rec = json.loads(line)
    except ValueError:
        continue
    if rec.get("isSidechain"):
        continue
    kind = rec.get("type")
    if kind == "user":
        content = rec.get("message", {}).get("content")
        text = "\n".join(t for t in (flatten(content), answered(rec)) if t)
    elif kind == "attachment":
        att = rec.get("attachment") or {}
        if att.get("type") != "queued_command":
            continue
        if (att.get("origin") or {}).get("kind") != "human":
            continue
        text = flatten(att.get("prompt"))
    else:
        continue
    if not text:
        continue
    typed = typed_text(text)
    if not typed:
        continue
    stamp = rec.get("timestamp", "")
    if (stamp, typed) != seen:
        seen = (stamp, typed)
        print(f"--- {stamp}\n{elide(typed)}\n")
PY
```

A session driven entirely by skill pipelines can yield no typed user turns at all. Then the evidence lives on the assistant side: rerun the extraction with the `user` branch's type check changed to `assistant`, keeping the same flattening.

### 3. Identify Evidence

Read the extracted turns in order and collect:

- **Corrections** — the user interrupted, said no, redirected, or fixed something by hand
- **Repeated guidance** — the same instruction given more than once
- **Preferences** — formatting, naming, style, or tool choices the user expressed
- **Failure modes** — an approach that failed, with what replaced it
- **Other** — anything else that stays true beyond this session

A correction is ambiguous without the thing it corrected. For each one, locate its record with `grep -n "<timestamp>" "<transcript path>"` and read the preceding records with a line-range slice such as `sed -n '<start>,<end>p'` to see what prompted it, then state that in one line. Two hits mean a queued message: slice back from the earlier one, where the user was still watching the work that prompted it.

Keep items that would still hold in a future session. Drop one-off instructions that only steer the task at hand.

## Sweep Process

Follow this instead of the Mining Process when mining the project's whole history rather than one session.

### 1. List Every Transcript

Keep every Mining Process filter except the distinctive-phrase match, and add one the sweep needs on its own: the prefix glob also matches sibling projects whose encoded name extends the root's, so filter on the `cwd` the records carry. Take the matches oldest first:

```bash
python3 - "<project root>" <<'PY'
import glob, json, os, sys

root = os.path.realpath(os.path.expanduser(sys.argv[1]))
config_home = os.path.expanduser(os.environ.get("CLAUDE_CONFIG_DIR") or "~/.claude")
paths = glob.glob(os.path.join(config_home, "projects", "*", "*.jsonl"))
for path in sorted(paths, key=os.path.getmtime):
    seen = set()
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            try:
                cwd = json.loads(line).get("cwd")
            except ValueError:
                continue
            if not cwd or cwd in seen:
                continue
            seen.add(cwd)
            resolved = os.path.realpath(os.path.expanduser(cwd))
            if resolved == root or resolved.startswith(root + os.sep):
                print(path)
                break
PY
```

Drop the most recently modified match: that is the live session, already covered by the scan that dispatched you. When no file matches, or none remains after that drop, report it in one line and stop.

Drop what a previous run already distilled: files older than the cutoff you were given, and the turns preceding the last `/self-improve` invocation in any file that holds one. That invocation is a `<command-name>/self-improve</command-name>` record, which the extraction below discards as a harness wrapper, so find it in the raw file and slice from there, resolving each transcript to the path the next step reads:

```bash
LINE=$(grep -n 'command-name>/self-improve<' "<transcript>" | tail -1 | cut -d: -f1)
INPUT="<transcript>"
if [ -n "$LINE" ]; then
  INPUT="<scratch>/<session-id>.jsonl"
  tail -n +$((LINE + 1)) "<transcript>" > "$INPUT"
fi
```

Match that record shape rather than the bare string `/self-improve`, which also matches the installed skill path and ordinary prose.

### 2. Extract Each One

Run the Mining Process extraction script unchanged over each resolved input path rather than writing a fresh one. Without its `NOISE` filter the output is mostly injected skill preambles and the typed turns are buried.

Loop over those paths in a single Bash call, printing each transcript's own path as a header before its extraction and appending both to one scratch file outside the repo. Read that file rather than the extraction output, in oldest-first slices when it is large, carrying the candidate items from each slice forward into the next.

### 3. Identify Evidence Across Sessions

Collect per the Mining Process categories, tracing the context of a correction only for items that survive as candidates. Note where the same guidance appears in more than one session: repetition across sessions is the signal that separates a documentation gap from one-off steering.

Report per the Output Format below, adding a `**Sessions**` line to each entry naming the transcripts it came from.

## Output Format

```
## Recovered Evidence

### <category>: <one-line claim>
- **Quote**: "<verbatim user words>"
- **Context**: <what prompted it>
- **When**: <timestamp>
- **Sessions**: <transcript paths — sweep only>
```

Order the entries by the category order above. When nothing durable survives, say so in one line.
