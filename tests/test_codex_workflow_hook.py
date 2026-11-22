import json
import subprocess
import tempfile
import unittest
from pathlib import Path


PLUGIN = Path(__file__).resolve().parents[1] / "codex"


class WorkflowHookTest(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.cwd = Path(temp.name).resolve()
        self.thread = "test-chat"
        self.checkpoint = self.cwd / ".turbo" / "workflows" / f"{self.thread}.md"
        self.checkpoint.parent.mkdir(parents=True)
        self.checkpoint.write_text("private workflow contents")

    def run_hook(self, source, thread=None, cwd=None, transcript=None):
        event = {"session_id": thread or self.thread, "source": source}
        if transcript:
            event["transcript_path"] = str(transcript)
        output = subprocess.check_output(
            ["sh", PLUGIN / "hooks/session-start.sh"],
            cwd=cwd or self.cwd, input=json.dumps(event), text=True,
        )
        self.assertIn("# Turbo Rules", output)
        self.assertNotIn("private workflow contents", output)
        return output

    def test_recovers_only_this_chat_on_compact_or_resume(self):
        for source in ("compact", "resume"):
            recovery = self.run_hook(source).partition("Before continuing this workflow")[2]
            self.assertIn(f"read {json.dumps(str(self.checkpoint))}", recovery)
            self.assertIn("mirror the full checklist", recovery)
        for source, thread in (("fork", "forked"), ("clear", self.thread),
                               ("startup", self.thread), ("compact", "other"), ("compact", "../test-chat")):
            with self.subTest(source=source, thread=thread):
                self.assertNotIn("Before continuing this workflow", self.run_hook(source, thread))

    def test_finds_initial_directory_after_cwd_changes(self):
        other = self.cwd / "changed directory"
        other.mkdir()
        transcript = self.cwd / "rollout.jsonl"
        meta = {"type": "session_meta", "payload": {"id": self.thread, "cwd": str(self.cwd)}}
        transcript.write_text(json.dumps(meta) + "\n")
        output = self.run_hook("compact", cwd=other, transcript=transcript)
        self.assertIn(f"read {json.dumps(str(self.checkpoint))}", output)
        fork = self.run_hook("resume", "forked", cwd=other, transcript=transcript)
        self.assertNotIn(str(self.checkpoint), fork)


if __name__ == "__main__":
    unittest.main()
