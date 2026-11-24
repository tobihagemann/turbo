---
name: peer-review
description: "Run an independent peer review via Claude. Use when the user asks to \"peer review\", \"peer review my code\", \"peer review my plan\", \"get a second opinion\", or \"independent review\"."
---

# Peer Review

Independent peer review via Claude. Translates a natural-language review request into a Claude-specific prompt so invocations stay implementation-agnostic.

## Step 1: Determine Review Request

Extract from the current context:

- **Material** — code diff, files, plan, feedback, or other artifact to review
- **Review dimensions** — correctness, security, API usage, consistency, simplicity, coverage, plan readiness, feedback interpretation, or explicit user criteria
- **Criteria** — reference file paths Claude should read directly, inline criteria text, or the material's own domain conventions
- **Prior adjudications** — findings already judged, one line each with its verdict and the recorded reason; optional
- **Output format** — findings schema, verdict labels, priority scale, and any required metadata fields

If no reviewable material is available, stop and state that material is required.

## Step 2: Build the Claude Prompt

Assemble a prompt for Claude:

- State that Claude is acting as an independent peer reviewer for Codex.
- Identify the exact material and scope. Pass text you did not author as file paths and diff commands rather than pasted content.
- When the review revisits material an earlier round already covered, rebuild the review subject from the material's current content and state that any earlier version of it is superseded.
- Instruct Claude to read referenced criteria files directly.
- When prior adjudications were identified in Step 1, state them inline in the prompt, labeled as decisions already reached on proposed changes rather than as established properties of the material, and state that a listed finding is raised again only on evidence its recorded reason does not already account for.
- Bound Claude's reads to the material under review, the sources needed to verify claims about it, and the criteria identified in Step 1. Exclude documents unrelated to those three. Instruct Claude to search the repository with a tool that skips gitignored files, such as `git grep --untracked`, and to open or search a gitignored path only when this prompt, the material, or the criteria name it, or when a dependency's installed source is needed to verify a claim, never one holding local configuration or credentials.
- Preserve independent dimensions. If multiple dimensions are requested and Codex sub-agent fan-out is unavailable, ask Claude to review each dimension in a separately labeled section. When the request instead asks explicitly for a single-pass review covering all dimensions, keep it to one pass with each dimension in its own labeled section rather than fanning out, stating an explicit outcome for every dimension, including one with no qualifying findings.
- Require the exact output format expected by the calling skill.
- Require evidence for every actionable finding.
- Tell Claude not to modify files.
- When the material is code, state that the run is limited to reading files and a fixed set of read-only git commands. Instruct Claude to name any check it could not run, such as a test suite or a mutation check, and to mark a verdict that rests on reading alone as such.
- Tell Claude to perform the review itself rather than delegating to another peer review skill or back to Codex. The prompt has already crossed the tool boundary; further forwarding would loop.

## Step 3: Run `$claude-print` Skill

Run the `$claude-print` skill in read-only mode with the assembled prompt.

## Step 4: Validate Output

Compare Claude's output against the reviewed material and the dimensions and structure requested in Step 2, then classify it into one of three branches:

- **Claude returned the requested findings** — output them verbatim.
- **Incomplete output** — preserve the findings received verbatim and identify the missing dimensions, items, or truncated findings.
- **No usable output** — report the cause, including a blocked launch, denied approval, or off-topic response. Omit off-topic content.

### Missing peer coverage

For either incomplete or missing output, a sub-agent returns the cause, any usable findings, and the outstanding decision. For a denied transfer, include the material requested, its destination, and the stated reason for denial.

The main conversation owns this decision, including when running peer review directly. Use `request_user_input` to ask whether to retry the peer review or continue this review with the available findings. When the peer refused on a content-safety block, recommend retrying with the prompt unchanged. If approval blocked the review, name the material, its destination, and the stated reason. When policy permits a retry with explicit authorization, ask whether the user authorizes sending that material to that destination for this review. If no retry is available, offer to leave the review pending or continue without the missing peer input.

While awaiting an answer, or if the user chooses to leave the review pending, stop here with the review step open. On an authorized retry, rerun the peer review and validate the new output here. On an explicit choice to continue, report the missing peer coverage alongside the available results. Only the peer can supply its findings and verdict. Complete the step only with a full peer review or the user’s explicit choice to proceed with missing coverage.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

## Rules

- `$peer-review` is the stable abstraction. Pipeline skills should not call `$claude-print` directly unless they need raw Claude print-mode behavior.
- Do not apply Claude findings directly. Evaluation and application belong to downstream skills.
