#!/usr/bin/env python3
"""Run the oracle CLI with configuration from ~/.turbo/config.json.

Configuration:
  oracle.chatgptUrl  ChatGPT URL (default: https://chatgpt.com/)
  oracle.model       Model to target (default: gpt-5.6-sol)

Usage: python3 scripts/run_oracle.py --prompt "<question>" --file <files...>

All arguments are forwarded to the oracle CLI. --engine, --browser-manual-login,
--chatgpt-url, and --model are set automatically and should not be passed manually.
"""

import json, os, sys, subprocess

# Targeting a Pro model aborts the run: ChatGPT sets thinking effort with a slider
# the oracle CLI cannot select, and a Pro request refuses to submit without confirming
# it. A non-Pro target submits at whatever level the slider holds, and that level
# survives the model switch, so Pro effort still applies.
DEFAULT_MODEL = 'gpt-5.6-sol'


def load_config():
    """Load ~/.turbo/config.json and return the oracle section."""
    config_path = os.path.expanduser('~/.turbo/config.json')
    if not os.path.isfile(config_path):
        return {}
    with open(config_path) as f:
        return json.load(f).get('oracle', {})


config = load_config()

chatgpt_url = config.get('chatgptUrl', 'https://chatgpt.com/')
model = config.get('model', DEFAULT_MODEL)

cmd = [
    'npx', '-y', '@steipete/oracle@latest',
    '--engine', 'browser',
    '--browser-manual-login',
    '--chatgpt-url', chatgpt_url,
    '--model', model,
    *sys.argv[1:],
]

sys.exit(subprocess.call(cmd))
