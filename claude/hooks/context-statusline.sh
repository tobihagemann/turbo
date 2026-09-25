#!/bin/bash
# Status line. Also records remaining context per session for context-warn.sh, which reads the same directory.
out=$(jq -r '(.context_window.remaining_percentage | if . == null then "" else floor | tostring end) + "/" + (.session_id // "")')
pct=${out%%/*}
sid=${out#*/}
[ -n "$pct" ] || exit 0
echo "${pct}% context left"
if [ -n "$sid" ]; then
  dir="${TMPDIR:-/tmp}/turbo-context-$UID"
  [ -d "$dir" ] || mkdir -p "$dir"
  printf '%s\n' "$pct" > "$dir/$sid"
fi
