# Transcript Miner Guidelines

Recover session evidence that context compaction dropped, from the rollout file Codex persists on disk. Read and report; change nothing.

## Mining Process

### 1. Locate the Rollout File

Codex writes every session to `~/.codex/sessions/<yyyy>/<mm>/<dd>/rollout-<timestamp>-<session-id>.jsonl`. The path carries no working directory, and sub-agent threads write their own rollout files under the same directories, carrying a copy of the parent's turns from the fork point. Match on the first record of each file, which is `session_meta`: keep the files whose payload `cwd` is the project root or a directory beneath it, and which carry no parent link. The parent link takes three shapes, and a file carrying any of them is a copy: `parent_thread_id`, `forked_from_id`, and a `source` object holding a `subagent` key.

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
    if not (cwd == root or cwd.startswith(root + "/")):
        continue
    if meta.get("parent_thread_id") or meta.get("forked_from_id"):
        continue
    src = meta.get("source")
    if isinstance(src, dict) and "subagent" in src:
        continue
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

An answer to a `request_user_input` gate produces no `user_message` event. It arrives as a `response_item` whose payload is a `function_call_output`, holding a JSON string in `payload.output` shaped `{"answers": {"<question id>": {"answers": ["<answer>"]}}}`. The question text sits in the preceding `function_call` record carrying the same `call_id`, whose `arguments` is a JSON string listing `questions` by `id`. Pair the two so each recovered turn carries the question it answers. Each entry holds the user's own words: the option label they selected, or the text they supplied.

Print the real user turns:

```bash
python3 - "<rollout path>" <<'PY'
import json, sys

WRAPPERS = ("# Files mentioned by the user:", "# In app browser:",
            "# Context from my IDE setup:")
GATE = "request_user_input"


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


def questions(arguments):
    """Map question id to question text for one request_user_input call."""
    try:
        asked = json.loads(arguments or "{}")
    except ValueError:
        return {}
    return {q.get("id"): q.get("question", "") for q in asked.get("questions") or []
            if isinstance(q, dict)}


def answers(output, asked):
    """Render the answers of a request_user_input call as one user turn."""
    try:
        given = json.loads(output or "{}")
    except ValueError:
        return ""
    pairs = []
    for qid, val in (given.get("answers") or {}).items():
        for answer in (val or {}).get("answers") or []:
            pairs.append(f'"{asked.get(qid) or qid}"="{answer}"')
    if not pairs:
        return ""
    return "The user answered: " + ", ".join(pairs)


asked = {}
seen = ()
for line in open(sys.argv[1], encoding="utf-8"):
    try:
        rec = json.loads(line)
    except ValueError:
        continue
    payload = rec.get("payload") or {}
    kind = payload.get("type")
    if rec.get("type") == "event_msg" and kind == "user_message":
        text = strip_wrapper((payload.get("message") or "").strip())
    elif kind == "function_call" and payload.get("name") == GATE:
        asked[payload.get("call_id")] = questions(payload.get("arguments"))
        continue
    elif kind == "function_call_output" and payload.get("call_id") in asked:
        text = answers(payload.get("output"), asked.pop(payload.get("call_id")))
    else:
        continue
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

## Sweep Process

Follow this instead of the Mining Process when mining the project's whole history rather than one session.

### 1. List Every Rollout File

Keep every Mining Process filter except the distinctive-phrase match. Take every match for the project, oldest first, applying the cutoff you were given:

```bash
python3 - "<project root>" "<cutoff ISO-8601, or empty>" <<'PY'
import datetime, glob, json, os, sys

root = sys.argv[1].rstrip("/")
cutoff = 0.0
if len(sys.argv) > 2 and sys.argv[2]:
    cutoff = datetime.datetime.fromisoformat(sys.argv[2]).timestamp()

hits = []
for path in glob.glob(os.path.expanduser("~/.codex/sessions/*/*/*/rollout-*.jsonl")):
    try:
        with open(path, encoding="utf-8") as fh:
            meta = json.loads(fh.readline()).get("payload", {})
    except Exception:
        continue
    cwd = meta.get("cwd") or ""
    if not (cwd == root or cwd.startswith(root + "/")):
        continue
    if meta.get("parent_thread_id") or meta.get("forked_from_id"):
        continue
    src = meta.get("source")
    if isinstance(src, dict) and "subagent" in src:
        continue
    if os.path.getmtime(path) < cutoff:
        continue
    hits.append(path)
for path in sorted(hits, key=os.path.getmtime):
    print(path)
PY
```

Drop the most recently modified match: that is the live session, already covered by the scan that dispatched you. When no file matches, or none remains after that drop, report it in one line and stop.

Drop what a previous run already distilled: the records preceding the last `$self-improve` invocation in any file that holds one. Codex injects a loaded skill as a `<skill><name>…</name>` block inside a `response_item`, which the extraction below skips in favor of `event_msg`, so find it in the raw file and slice from there, resolving each rollout file to the path the next step reads:

```bash
LINE=$(grep -n '<name>self-improve</name>' "<rollout path>" | tail -1 | cut -d: -f1)
INPUT="<rollout path>"
if [ -n "$LINE" ]; then
  INPUT="<scratch>/<session-id>.jsonl"
  sed -n "$((LINE + 1)),\$p" "<rollout path>" > "$INPUT"
fi
```

Match that block rather than the bare string `$self-improve`, which also matches file reads, diffs, and prose that merely names the skill.

### 2. Extract Each One

Run the Mining Process extraction script unchanged over each resolved input path rather than writing a fresh one. Its `event_msg` targeting is what keeps the output readable, since the `response_item` copies are wrapped in plugin and skill-injection blocks that bury the typed turns, and its `request_user_input` pairing recovers answers that produce no `user_message` at all.

Loop over those paths in a single command, printing each rollout file's own path as a header before its extraction and appending both to one scratch file outside the repo. Read that file rather than the extraction output, in oldest-first slices when it is large, carrying the candidate items from each slice forward into the next.

### 3. Identify Evidence Across Sessions

Collect per the Mining Process categories, tracing the context of a correction only for items that survive as candidates. Note where the same guidance appears in more than one session: repetition across sessions is the signal that separates a documentation gap from one-off steering.

Report per the Output Format below, adding a `**Sessions**` line to each entry naming the rollout files it came from.

## Output Format

```
## Recovered Evidence

### <category>: <one-line claim>
- **Quote**: "<verbatim user words>"
- **Context**: <what prompted it>
- **When**: <timestamp>
- **Sessions**: <rollout paths — sweep only>
```

Order the entries by the category order above. When nothing durable survives, say so in one line.
