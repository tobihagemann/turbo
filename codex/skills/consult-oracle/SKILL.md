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
    "chromeProfile": "Default"
  }
}
```

| Key | Purpose | Default |
|---|---|---|
| `chatgptUrl` | ChatGPT URL (e.g., a custom GPT project URL) | `https://chatgpt.com/` |
| `chromeProfile` | Chrome profile directory name | `Default` |

## Step 1: Identify Key Files

Find the 2-5 files most relevant to the problem.

## Step 2: Formulate the Question

Write a clear, specific problem description. Include what has already been tried and why it failed. Open with a short project briefing (stack, services, build steps). The more context, the better the response.

## Step 3: Run the Oracle

Use a generous timeout (60 minutes / 3600000ms). The script loads `chatgptUrl` and `chromeProfile` from `~/.turbo/config.json` automatically and reuses the signed-in ChatGPT session from that Chrome profile. Generate a random tag and persist the response:

```bash
ORACLE_TAG=$(head -c 4 /dev/urandom | xxd -p) && mkdir -p .turbo/oracle
python3 scripts/run_oracle.py --prompt "<problem description>" --file <relevant files...> --write-output ".turbo/oracle/$ORACLE_TAG.txt"
```

## Step 4: Synthesize

Read the response from `.turbo/oracle/$ORACLE_TAG.txt`. Summarize the key insights from the consultation. Cross-reference suggestions with official docs and peer open-source implementations before applying. Oracle suggestions are starting points, not guaranteed solutions.
