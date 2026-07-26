# Transcript Miner Guidelines

Recover session evidence that context compaction dropped, from the rollout file Codex persists on disk. Read and report; change nothing.

## Mining Process

### 1. Locate the Rollout File

Codex writes every session to `~/.codex/sessions/<yyyy>/<mm>/<dd>/rollout-<timestamp>-<session-id>.jsonl`. The path carries no working directory, and sub-agent threads write their own rollout files under the same directories, carrying a copy of the parent's turns from the fork point. Match on the first record of each file, which is `session_meta`: keep the files whose payload `cwd` is the project root or a directory beneath it, and which have no `parent_thread_id`.

```bash
python3 - "<project root>" <<'PY'
import glob, json, os, sys

hits = []
for path in glob.glob(os.path.expanduser("~/.codex/sessions/*/*/*/rollout-*.jsonl")):
    try:
        with open(path, encoding="utf-8") as fh:
            meta = json.loads(fh.readline()).get("payload", {})
    except Exception:
        continue
    cwd = meta.get("cwd") or ""
    root = sys.argv[1].rstrip("/")
    if (cwd == root or cwd.startswith(root + "/")) and not meta.get("parent_thread_id"):
        hits.append(path)
for path in sorted(hits, key=os.path.getmtime, reverse=True)[:5]:
    print(path)
PY
```

The current session is the most recently modified match. Confirm it by grepping for the distinctive phrase you were given, using a short fragment that sits on one line and contains no quote characters: the stored text is JSON-escaped. When the phrase is absent, try the next file down.

If no matching rollout file can be found, report that in one line and stop.

### 2. Extract the User Side

Each line is a record with `type` and `payload`. Submitted user turns are `event_msg` records whose payload has `type: "user_message"` and the text in `payload.message`. The model-facing copies live in `response_item` records, wrapped in harness blocks that read like user speech, so extract from `event_msg` instead. The `compacted` record type marks where a compaction cut the thread; anything before it is what this run needs to recover.

A submitted turn can open with a harness-injected block, such as an attachment manifest or captured browser context, followed by the user's own text in the same record. Strip the block and keep the remainder.

Print the real user turns:

```bash
python3 - "<rollout path>" <<'PY'
import json, sys

WRAPPERS = ("# Files mentioned by the user:", "# In app browser:",
            "# Context from my IDE setup:")


def strip_wrapper(text):
    """Drop a leading harness block, keeping whatever the user typed after it."""
    if not text.startswith(WRAPPERS):
        return text
    lines = text.splitlines()
    while lines and (not lines[0].strip() or lines[0].startswith("#")):
        lines.pop(0)
    return "\n".join(lines).strip()


def elide(text):
    """Keep the opening and the operative ending of an unusually long turn."""
    if len(text) <= 6000:
        return text
    return text[:4000] + "\n[...]\n" + text[-2000:]


seen = ()
for line in open(sys.argv[1], encoding="utf-8"):
    try:
        rec = json.loads(line)
    except ValueError:
        continue
    if rec.get("type") != "event_msg":
        continue
    payload = rec.get("payload", {})
    if payload.get("type") != "user_message":
        continue
    text = strip_wrapper((payload.get("message") or "").strip())
    stamp = rec.get("timestamp", "")
    if not text or (stamp, text) == seen:
        continue
    seen = (stamp, text)
    print(f"--- {stamp}\n{elide(text)}\n")
PY
```

A session driven entirely by skill pipelines can yield no typed user turns at all. Then the evidence lives on the assistant side: extract `response_item` records whose payload has `type: "message"` and `role: "assistant"`, joining the `text` of their content parts.

### 3. Identify Evidence

Read the extracted turns in order and collect:

- **Corrections** — the user interrupted, said no, redirected, or fixed something by hand
- **Repeated guidance** — the same instruction given more than once
- **Preferences** — formatting, naming, style, or tool choices the user expressed
- **Failure modes** — an approach that failed, with what replaced it
- **Other** — anything else that stays true beyond this session

A correction is ambiguous without the thing it corrected. For each one, locate its record with `grep -n "<timestamp>" "<rollout path>"` and read the preceding records with a line-range slice such as `sed -n '<start>,<end>p'` to see what prompted it, then state that in one line.

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
