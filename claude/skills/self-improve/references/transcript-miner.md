# Transcript Miner Guidelines

Recover session evidence that context compaction dropped, from the transcript Claude Code persists on disk. Read and report; change nothing.

## Mining Process

### 1. Locate the Transcript

Claude Code writes every session to `~/.claude/projects/<encoded-cwd>/<session-id>.jsonl`, where the encoding replaces both `/` and `.` with `-`. A session started in a subdirectory encodes to its own directory, so match the encoded project root as a prefix:

```bash
ROOT="<project root>"
ls -t "$HOME/.claude/projects/$(printf '%s' "$ROOT" | sed 's|[/.]|-|g')"*/*.jsonl | head -5
```

The current session is the most recently modified file. Confirm it by grepping for the distinctive phrase you were given, using a short fragment that sits on one line and contains no quote characters: the stored text is JSON-escaped. When the phrase is absent, try the next file down, since concurrent sessions in the same project share the directory.

If the directory or a matching transcript cannot be found, report that in one line and stop.

### 2. Extract the User Side

Each line is a record with `type`, `timestamp`, `sessionId`, and `isSidechain`. Conversation records are typed `user` and `assistant` and carry `message.content`, either a string or a list of parts typed `text`, `tool_use`, or `tool_result`. The remaining types hold harness state.

Two filters matter. Records with `isSidechain: true` are subagent conversations where the user never speaks. Many user records hold harness-injected text that reads like user speech: slash command wrappers, bash I/O, system reminders, cross-session notifications, and skill-loading preambles. Those wrappers still carry the arguments the user typed after a slash command, so salvage the arguments instead of dropping the record whole.

A message the user types while a tool call is in flight never becomes a `user` record. It persists as an `attachment` record whose `attachment.type` is `queued_command`, holding the text in `attachment.prompt` in the same string-or-parts shape. Take the ones whose `attachment.origin.kind` is `human`, which excludes the harness notifications queued the same way. The record sits at the point of delivery and carries the timestamp of the moment the user typed it.

An answer given through `AskUserQuestion` produces no text part either. It arrives inside a `user` record as a `tool_result` part opening with `The user answered`, carrying one or more `"<question>"="<answer>"` pairs and a trailing harness sentence. Each answer is either an option label the user selected or the free text they typed instead of selecting one, so both are their own words. Match on the opening of the part, since recovered-evidence reports quote the marker mid-text. Strip the trailing sentence to keep it out of the quoted evidence.

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
ANSWER = "The user answered"
TAIL = re.compile(r"\.\s*Read the answers carefully\b.*\Z", re.S)


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


def answered(content):
    """Join the AskUserQuestion answers carried by a payload's tool_result parts."""
    found = []
    for part in content if isinstance(content, list) else []:
        if not isinstance(part, dict) or part.get("type") != "tool_result":
            continue
        body = part.get("content")
        if isinstance(body, list):
            body = "\n".join(b.get("text", "") for b in body
                             if isinstance(b, dict))
        if not isinstance(body, str) or not body.strip().startswith(ANSWER):
            continue
        found.append(TAIL.sub("", body.strip()).strip())
    return "\n".join(found)


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
        text = "\n".join(t for t in (flatten(content), answered(content)) if t)
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

## Output Format

```
## Recovered Evidence

### <category>: <one-line claim>
- **Quote**: "<verbatim user words>"
- **Context**: <what prompted it>
- **When**: <timestamp>
```

Order the entries by the category order above. When nothing durable survives, say so in one line.
