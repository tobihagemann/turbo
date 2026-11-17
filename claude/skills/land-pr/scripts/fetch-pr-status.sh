#!/usr/bin/env bash
# Fetch a GitHub PR's merge state, pending review requests, recent reviews, unresolved
# review threads, recent conversation comments, and head-commit checks in one GraphQL
# call. Emits a single JSON document on stdout:
#   {
#     "meta":              { isDraft, author, viewer, headRefOid, headCommittedDate,
#                            mergeable, mergeStateStatus, reviewDecision },  # viewer: the authenticated login
#     "reviewRequests":    [ { reviewer, type } ],      # type: Bot, User, Team, Mannequin, or
#                                                       # Unknown for a reviewer the token cannot read
#     "reviews":           [ { author, authorType, submittedAt, hasBody } ],  # the 100 latest submitted
#     "unresolvedThreads": [ { author, lastAuthor, path } ],  # among the 100 latest threads;
#                                                             # author and path of the first comment
#     "issueComments":     [ { author, createdAt } ],   # the 100 latest
#     "checks":            [ { name, app, state, title } ]
#   }
#
# Each check's "state" is "failing", "pending", or "passing". Skipped check runs are
# left out.
#
# Fetched values go to jq on stdin, since a long PR overflows an argument.
#
# Usage: fetch-pr-status.sh <owner> <repo> <pr_number>

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
      isDraft author { login } headRefOid mergeable mergeStateStatus reviewDecision
      reviewRequests(first: 100) {
        nodes {
          requestedReviewer {
            __typename
            ... on User { login }
            ... on Bot { login }
            ... on Mannequin { login }
            ... on Team { slug }
          }
        }
      }
      reviews(last: 100) { nodes { author { __typename login } state submittedAt body } }
      reviewThreads(last: 100) {
        nodes {
          isResolved
          first: comments(first: 1) { nodes { author { login } path } }
          last: comments(last: 1) { nodes { author { login } } }
        }
      }
      comments(last: 100) { nodes { author { login } createdAt } }
      commits(last: 1) {
        nodes {
          commit {
            committedDate
            checkSuites(first: 100) {
              nodes {
                app { slug }
                checkRuns(first: 100, filterBy: { checkType: LATEST }) {
                  nodes { name status conclusion title }
                }
              }
            }
            status { contexts { context state description } }
          }
        }
      }
    }
  }
}
GRAPHQL
)

gh api graphql -f query="$query" -f owner="$owner" -f repo="$repo" -F pr="$pr" --jq '.data' \
  | jq '
      .viewer.login as $viewer
      | .repository.pullRequest as $pr
      | $pr.commits.nodes[0].commit as $head
      | {
          meta: { isDraft: $pr.isDraft, author: $pr.author.login, viewer: $viewer,
                  headRefOid: $pr.headRefOid, headCommittedDate: $head.committedDate,
                  mergeable: $pr.mergeable, mergeStateStatus: $pr.mergeStateStatus,
                  reviewDecision: $pr.reviewDecision },
          reviewRequests: [ $pr.reviewRequests.nodes[].requestedReviewer
                            | if . == null then { reviewer: null, type: "Unknown" }
                              else { reviewer: (.login // .slug), type: .__typename } end ],
          reviews: [ $pr.reviews.nodes[] | select(.state != "PENDING")
                     | { author: .author.login, authorType: .author.__typename, submittedAt,
                         hasBody: ((.body // "") | test("\\S")) } ],
          unresolvedThreads: [ $pr.reviewThreads.nodes[] | select(.isResolved | not)
                               | { author: .first.nodes[0].author.login,
                                   lastAuthor: .last.nodes[0].author.login,
                                   path: .first.nodes[0].path } ],
          issueComments: [ $pr.comments.nodes[] | { author: .author.login, createdAt } ],
          # A cancelled or stale run never produced a result, so it counts as failing.
          # A required commit status that has not reported yet arrives as EXPECTED.
          checks: (
            [ $head.checkSuites.nodes[] | .app.slug as $app | .checkRuns.nodes[]
              | select(.conclusion != "SKIPPED")
              | { name, app: $app, title,
                  state: (if .status != "COMPLETED" then "pending"
                          elif (.conclusion | IN("SUCCESS", "NEUTRAL")) then "passing"
                          else "failing" end) } ]
            + [ ($head.status.contexts // [])[]
                | { name: .context, app: null, title: .description,
                    state: (if (.state | IN("PENDING", "EXPECTED")) then "pending"
                            elif .state == "SUCCESS" then "passing"
                            else "failing" end) } ]
          )
        }'
