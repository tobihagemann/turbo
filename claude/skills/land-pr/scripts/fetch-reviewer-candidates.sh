#!/usr/bin/env bash
# List reviewer candidates for a GitHub PR: GitHub's suggested reviewers first, in
# GitHub's order, then the user accounts that reviewed the repository's 30 most recently
# updated merged pull requests, most such pull requests first. The PR's author and the
# authenticated user are left out. Emits a JSON array on stdout:
#   [ { login, source, prs } ]   # source: suggested or recent; prs: recent PRs they reviewed
#
# Usage: fetch-reviewer-candidates.sh <owner> <repo> <pr_number>

set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <owner> <repo> <pr_number>" >&2
  exit 2
fi

owner="$1"
repo="$2"
pr="$3"

query=$(cat <<'GRAPHQL'
query($owner: String!, $repo: String!, $pr: Int!) {
  viewer { login }
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      author { login }
      suggestedReviewers { reviewer { login } }
    }
    pullRequests(last: 30, states: MERGED, orderBy: { field: UPDATED_AT, direction: ASC }) {
      nodes { latestReviews(first: 50) { nodes { author { __typename login } } } }
    }
  }
}
GRAPHQL
)

gh api graphql -f query="$query" -f owner="$owner" -f repo="$repo" -F pr="$pr" --jq '.data' \
  | jq '
      [.viewer.login, .repository.pullRequest.author.login] as $excluded
      | [.repository.pullRequest.suggestedReviewers[].reviewer.login] as $suggested
      | [.repository.pullRequests.nodes[]
         | [.latestReviews.nodes[].author | select(. != null and .__typename == "User") | .login]
         | unique[]] as $recent
      | ([ $suggested[] | { login: ., source: "suggested" } ]
         + [ $recent | group_by(.) | map({ login: .[0], source: "recent", n: length })
             | sort_by(-.n)[] | { login, source } ])
      | reduce .[] as $c ([]; if any(.[]; .login == $c.login) then . else . + [$c] end)
      | map(select(.login | IN($excluded[]) | not)
            | . as $c | . + { prs: ([$recent[] | select(. == $c.login)] | length) })'
