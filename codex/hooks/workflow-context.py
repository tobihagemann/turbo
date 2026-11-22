import json
import re
import sys
from pathlib import Path


def initial_directory(event):
    transcript = event.get("transcript_path")
    if transcript:
        try:
            with Path(transcript).open(encoding="utf-8") as stream:
                record = json.loads(stream.readline())
            meta = record["payload"]
            if record["type"] == "session_meta" and meta["id"] == event["session_id"]:
                directory = Path(meta["cwd"])
                if directory.is_absolute():
                    return directory
        except (OSError, ValueError, KeyError, TypeError):
            pass
    return Path.cwd()


def main():
    try:
        event = json.load(sys.stdin)
    except ValueError:
        return
    if not isinstance(event, dict):
        return
    thread = event.get("session_id")
    if not isinstance(thread, str) or not re.fullmatch(r"[A-Za-z0-9_-]+", thread):
        return
    checkpoint = initial_directory(event) / ".turbo" / "workflows" / f"{thread}.md"
    if event.get("source") in ("compact", "resume") and checkpoint.is_file():
        print(
            f"\nBefore continuing this workflow, read {json.dumps(str(checkpoint))}. "
            "Reopen its skill files, active references, governing plan and loop ledgers. "
            "Follow the Workflow Recovery rules above to reconcile and mirror the full checklist before continuing."
        )
    else:
        print(f"\nFor a tracked checklist or workflow checkpoint in this chat, use {json.dumps(str(checkpoint))}.")


if __name__ == "__main__":
    main()
