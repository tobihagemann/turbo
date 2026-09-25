#!/bin/bash
# PostToolUse: tells the main agent once when remaining context drops to 20%.
# Reads the value context-statusline.sh records.
# Re-arms once context recovers, e.g. after /compact.
sid=$(jq -r 'select((.agent_id // "") == "") | .session_id // empty')
[ -n "$sid" ] || exit 0
dir="${TMPDIR:-/tmp}/turbo-context-$UID"
{ read -r pct < "$dir/$sid"; } 2>/dev/null || exit 0
case "$pct" in ''|*[!0-9]*) exit 0 ;; esac
marker="$dir/$sid.warned"
if [ "$pct" -gt 20 ]; then
  [ -e "$marker" ] && rm -f "$marker"
  exit 0
fi
set -C
{ : > "$marker"; } 2>/dev/null || exit 0
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"Context is low: %s%% of the context window remains."}}\n' "$pct"
