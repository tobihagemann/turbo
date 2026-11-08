#!/bin/sh
root=$(cd "$(dirname "$0")/.." && pwd)

cat "$root/ADDITIONS.md"

config="$HOME/.turbo/config.json"

if [ -f "$config" ] && python3 -I -c 'import json, sys; sys.exit(0 if "lastUpdateHead" in json.load(open(sys.argv[1])).get("codex", {}) else 1)' "$config" 2>/dev/null; then
  printf '\n## Setup Notices\n\n- An earlier Turbo copy install is still present on this machine. Tell the user to run `$update-turbo` once to migrate to the plugin, or, when that skill is gone, to have you follow https://github.com/tobihagemann/turbo/blob/main/codex/UPDATE.md; until then, copied skills in `~/.agents/skills` shadow the plugin skills of the same name.\n'
fi
