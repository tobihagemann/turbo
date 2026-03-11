---
name: review-feature-branch
description: This skill should be used when the user asks to "review feature branch", "review branch against main", "run full review", "check my branch before merging", "review everything on this branch", or wants a comprehensive feature branch review that combines AI code review (peer review), PR comment analysis, findings evaluation, and optional implementation finishing.
---

# Reviewing Feature Branch

Orchestrate a comprehensive feature branch review by running AI code review, fetching PR comments, evaluating all findings, and optionally finishing implementation.

## Task Tracking

At the start, use `TaskCreate` to create a task for each phase:

1. Peer review
2. Review PR comments
3. Evaluate findings
4. Confirm implementation
5. Finish implementation

## Phase 1: Peer Review

Run `/peer-review` skill to review the feature branch against the base branch. Capture the full output for evaluation in Phase 3.

If the branch should be compared against a different base, the user will specify it. Default to the repository's default branch (detect via `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`).

## Phase 2: Review PR Comments

Check whether a PR exists for the current branch:

```bash
gh pr view --json number,title,url 2>/dev/null
```

- **PR exists**: Run the `/review-pr-comments` skill to fetch and display unresolved review threads. Retain the output for evaluation in Phase 3.
- **No PR exists**: Note that no PR was found and proceed to Phase 3 with only the codex review output.

## Phase 3: Evaluate Findings

Run the `/evaluate-findings` skill on the combined output from Phases 1 and 2.

If both phases produced zero actionable findings, report that the branch looks clean and skip to the end.

## Phase 4: Confirm Implementation

After the evaluate-findings summary, use `AskUserQuestion` to ask whether to proceed with finishing the implementation:

- **Proceed** -- continue to Phase 5
- **Skip** -- stop here, leave changes as-is for manual review

## Phase 5: Finalize Implementation

Run the `/finalize` skill.

## Rules

- If the peer review tool is not available or returns malformed output, report the error and stop.
- If any phase fails, run the `/investigate` skill to diagnose the failure, apply the suggested fix, and retry. If investigation cannot identify a root cause, stop and report with investigation findings. Do not skip ahead.
- Process findings in file order to minimize context switching.
