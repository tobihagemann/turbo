---
name: oracle
description: This skill should be used when stuck on a very hard problem, when standard approaches have failed, when multiple debugging attempts haven't worked, when the user says "ask the oracle", "consult oracle", "run the oracle", "I'm completely stuck", "I've tried everything", or "nothing is working".
---

# Oracle

Consult GPT-5.4 Pro via ChatGPT browser automation for problems that resist standard approaches.

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

## Steps

### 1. Refresh cookies

Before running the oracle, refresh ChatGPT cookies from Chrome. Requires timeout of 60000ms. A macOS Keychain password prompt will appear for the user.

```bash
python3 scripts/refresh_cookies.py
```

If the script reports session validation failure, the user needs to log into ChatGPT in Chrome first.

### 2. Identify key files

Find the 2-5 files most relevant to the problem.

### 3. Formulate the question

Write a clear, specific problem description. Include what has already been tried and why it failed. Open with a short project briefing (stack, services, build steps). The more context, the better the response.

### 4. Run the oracle

Use a generous timeout (60 minutes / 3600000ms). The script loads `chatgptUrl` from `~/.turbo/config.json` automatically.

```bash
python3 scripts/run_oracle.py --prompt "<problem description>" --file <relevant files...>
```

### 5. Evaluate the response

Run the `/evaluate-findings` skill on the oracle's response. Apply only findings that survive evaluation. Oracle suggestions are starting points — cross-reference with official docs and peer open-source implementations before accepting.
