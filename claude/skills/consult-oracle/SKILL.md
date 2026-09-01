---
name: consult-oracle
description: "Consult ChatGPT Pro via ChatGPT browser automation for problems that resist standard approaches. Use when stuck on a very hard problem, when standard approaches have failed, when multiple debugging attempts haven't worked, or when the user says \"ask the oracle\", \"consult oracle\", \"consult chatgpt\", \"I'm completely stuck\", \"I've tried everything\", or \"nothing is working\"."
---

# Consult Oracle

Consult ChatGPT Pro via ChatGPT browser automation for problems that resist standard approaches.

## Configuration

The oracle reads from `~/.turbo/config.json`:

```json
{
  "oracle": {
    "chatgptUrl": "https://chatgpt.com/",
    "model": "gpt-5.6-sol"
  }
}
```

| Key | Purpose | Default |
|---|---|---|
| `chatgptUrl` | ChatGPT URL (e.g., a custom GPT project URL) | `https://chatgpt.com/` |
| `model` | Model to target; use a non-Pro model, since a Pro target aborts before submitting | `gpt-5.6-sol` |

## Step 1: Confirm the Thinking Effort

The oracle consults through its own signed-in ChatGPT profile, created during setup and separate from the user's everyday browser. That profile's composer sets thinking effort with a slider the oracle can neither read nor change, so a consultation runs at whatever level the slider holds and the response never reports which one it used.

State this, then use `AskUserQuestion` to confirm the slider is set to Pro. Offer "Pro is selected" and "Not sure, consult anyway". Both proceed to Step 2; on the second, note in the Step 6 summary that the thinking effort was unconfirmed.

## Step 2: Identify Key Files

Find the 2-5 files most relevant to the problem.

## Step 3: Formulate the Question

Write a clear, specific problem description. Include what has already been tried and why it failed. Open with a short project briefing (stack, services, build steps). The more context, the better the response.

## Step 4: Run the Oracle

Run via the Bash tool (`timeout: 600000`, do not set `run_in_background`). The script loads `chatgptUrl` and `model` from `~/.turbo/config.json` automatically and consults through the oracle's own signed-in ChatGPT profile. Generate a random tag and persist the response:

```bash
ORACLE_TAG=$(head -c 4 /dev/urandom | xxd -p) && mkdir -p "$PWD/.turbo/oracle" && echo "$PWD/.turbo/oracle/$ORACLE_TAG.txt"
```

Substitute the printed value for `<printed-path>` in the command below and on every follow-up turn. Shell variables do not survive between Bash tool calls, and an earlier `cd` in a compound command leaves the session in a different directory, so a relative path resolves against that directory instead.

```bash
python3 scripts/run_oracle.py --prompt "<problem description>" --file <relevant files...> --write-output "<printed-path>"
```

Keep backticks and `$` out of `--prompt` even in text you wrote, since both stay live inside the quotes. Text you did not author — a diff, file contents, an error trace, command output — goes in a file passed with `--file`, written with the Write tool. This holds on follow-up turns too.

If the run fails, retry the command once — same prompt, attachments, and timeout — when the failure looks transient, such as a browser challenge or automation error while the signed-in session is otherwise healthy. Report an authentication, browser-challenge, or permission blocker only after the retry reproduces it, and cite the failing output. Do not broaden permissions when the current context already has the access the run needs.

## Step 5: Follow Up

Resume the same ChatGPT conversation with `--followup` and the session slug. The prior turn's attached files and context persist, so re-attaching the full diff each turn is unnecessary. Run via the Bash tool with the same settings as Step 4 (`timeout: 600000`, do not set `run_in_background`):

```bash
python3 scripts/run_oracle.py --followup "<session-slug>" --prompt "<follow-up>" --write-output "<printed-path>"
```

Find the slug with `python3 scripts/run_oracle.py status` (the Slug column; follow-ups nest under their parent session) or from the directory names under `~/.oracle/sessions/`.

Reuse the chat for a multi-turn review of the same code; start a fresh session (Step 4) for an unrelated question. Cap at 5 turns to prevent runaway conversations.

When the reviewed code changed since the prior turn, re-attach the changed files (`--file <paths>`) or a fresh diff, or state what changed. Otherwise the model reasons from the earlier attachments and flags already-fixed issues as live contradictions.

## Step 6: Synthesize

Read the response from `<printed-path>`. Summarize the key insights from the consultation. Cross-reference suggestions with official docs and peer open-source implementations before applying. Oracle suggestions are starting points, not guaranteed solutions.

Then use the TaskList tool and proceed to any remaining task.
