#!/usr/bin/env bash
# Fetch what a SonarCloud analysis reports for a branch or pull request: the quality
# gate's failed conditions and the open issues. Emits one JSON document on stdout:
#   {
#     "qualityGate":      "OK" | "ERROR" | ...,
#     "failedConditions": [ { metric, actual, threshold, comparator } ],
#     "issues":           [ { rule, path, line, message, severity, type } ]
#   }
#
# Takes the details URL of the SonarCloud check run, which carries the project key and
# the analysed branch or pull request. Exits 1 when SonarCloud does not let this
# analysis be read (a private project, an analysis that no longer exists, or a failed
# request), and 2 when the URL is not a SonarCloud details URL.
#
# Usage: fetch-sonarcloud-findings.sh <details_url>

set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <details_url>" >&2
  exit 2
fi

url="$1"
api="https://sonarcloud.io/api"

case "$url" in
  https://sonarcloud.io/*\?*) ;;
  *) echo "Not a SonarCloud details URL: $url" >&2; exit 2 ;;
esac

# Query values stay URL-encoded, as the details URL carries them.
project=""
scope=""
query="${url#*\?}"
IFS='&' read -r -a params <<<"$query"
for param in "${params[@]}"; do
  case "$param" in
    id=*) project="${param#id=}" ;;
    branch=*) scope="branch=${param#branch=}" ;;
    pullRequest=*) scope="pullRequest=${param#pullRequest=}" ;;
  esac
done

if [ -z "$project" ]; then
  echo "No project key in details URL: $url" >&2
  exit 2
fi

# An unreadable project answers the issue search with an empty list, so the quality
# gate request is what tells "no issues" from "not readable".
if ! gate=$(curl -fsS --max-time 30 "$api/qualitygates/project_status?projectKey=$project${scope:+&$scope}"); then
  echo "SonarCloud analysis not readable: $project${scope:+ ($scope)}" >&2
  exit 1
fi

# A branch analysis also lists issues in code the branch did not touch; a pull
# request analysis holds new code only.
new_code=""
case "$scope" in
  branch=*) new_code="&sinceLeakPeriod=true" ;;
esac

# The issue search serves at most 500 issues per page and 10,000 in total.
# Pages go to jq on stdin, since a long issue list overflows an argument.
pages=""
fetched=0
page=1
while :; do
  if ! result=$(curl -fsS --max-time 30 \
    "$api/issues/search?componentKeys=$project${scope:+&$scope}&issueStatuses=OPEN,CONFIRMED$new_code&ps=500&p=$page"); then
    echo "SonarCloud issues not readable: $project${scope:+ ($scope)}, page $page" >&2
    exit 1
  fi
  pages+="$result"$'\n'
  on_page=$(jq '.issues | length' <<<"$result")
  fetched=$((fetched + on_page))
  total=$(jq -r '.paging.total' <<<"$result")
  if [ "$on_page" -eq 0 ] || [ "$fetched" -ge "$total" ] || [ "$page" -ge 20 ]; then
    break
  fi
  page=$((page + 1))
done

printf '%s' "$pages" | jq -s --argjson gate "$gate" '{
  qualityGate: $gate.projectStatus.status,
  failedConditions: [ $gate.projectStatus.conditions[]? | select(.status == "ERROR")
    | { metric: .metricKey, actual: .actualValue, threshold: .errorThreshold, comparator } ],
  issues: [ .[].issues[]
    | { rule, path: (.project as $key | .component | ltrimstr($key + ":")), line, message, severity, type } ]
}'
