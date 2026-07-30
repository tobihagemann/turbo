---
name: evaluate-findings
description: "Critically assess external feedback (code reviews, AI reviewers, PR comments) and decide which suggestions to apply using adversarial verification. Use when the user asks to \"evaluate findings\", \"assess review comments\", \"triage review feedback\", \"evaluate review output\", or \"filter false positives\"."
---

# Evaluate Findings

Assess external feedback (code reviews, AI suggestions, PR comments) with adversarial verification. Triage findings into actionable verdicts. Do not apply fixes.

## Step 1: Assess Each Finding

If you already assessed a finding earlier in this session and recorded a verdict of Skip or Escalate — for example when an iterating loop re-runs review and the same finding resurfaces — do not re-adjudicate it from scratch. When the re-reported finding matches one you already judged (same location and substance) and presents no new evidence beyond what your recorded reason already accounts for, keep that verdict and reason without re-reading the code, re-verifying, or routing it to the Devil's Advocate in Step 2. Assess fresh only when the finding raises materially new evidence, or when you have not judged it before in this session.

For each finding:

1. **Read the referenced code** at the mentioned location — include the full function or logical block, not just the flagged line
2. **Check whether the code has diverged** — if the finding references code that no longer exists or has since changed, skip it and note the divergence.
3. **Determine scope** — clarify whether the issue was introduced by the PR/changeset or is pre-existing.
   - Pre-existing issues in earlier commits on the same feature branch are in-scope by default — the entire branch is one coherent unit of work. Judge these on their merits like any in-scope finding.
   - Findings genuinely outside the branch's work are the user's call to include. Assign Escalate so the user decides whether to widen the changeset. Reserve Skip for changes whose cost wildly dwarfs the benefit.
4. **Verify the claim** against the actual code — does the issue genuinely exist?
5. **Assess severity:**

   | Severity | Meaning |
   |----------|---------|
   | **Critical** | Drop everything. Blocking release or operations. |
   | **High** | Urgent. Should be addressed in the next cycle. |
   | **Medium** | Normal. To be fixed eventually. |
   | **Low** | Nice to have. Minor improvement. |

   If the upstream reviewer already assigned a priority (P0-P3), map it: P0→Critical, P1→High, P2→Medium, P3→Low. Then re-assess based on what the actual code reveals. The upstream level is a starting point, not a binding constraint. When the re-assessed severity differs from the upstream level, note the change and the reason.

   If the finding has no upstream priority, assess severity from scratch.

6. **Assign a verdict and confidence:**

| Verdict | Criteria |
|---------|----------|
| **Apply** | The finding is real and in scope: clear bug, missing check, genuine improvement, style violation matching project conventions |
| **Skip** | False positive, subjective preference, reviewer is wrong, or the change's cost wildly dwarfs its benefit |
| **Escalate** | Needs the user's judgment: behavior might be intentional, involves product intent, requires domain knowledge the agent lacks, the finding is out of scope, or two findings present a genuine trade-off |

Also assign an internal confidence level — **High**, **Medium**, or **Low** — reflecting how certain you are about the verdict. Confidence is used solely to route findings to the Devil's Advocate in Step 2. It does not appear in the output.

**Escalate guidance:** When a finding questions whether behavior is intentional and neither docs, specs, nor code comments clarify the intent, assign Escalate. Do not autonomously accept or reject findings that hinge on product intent. If a counterpart implementation exists elsewhere, suggest checking it for consistency.

**Conflict guidance:** When two findings contradict each other (they suggest opposite changes to the same code), treat the conflict as input, not a reason to skip. Verify each against the code and judge each on its merits as usual. If both are defensible and the choice is a genuine trade-off, assign Escalate to both, naming the opposing options so the user can decide.

An affirmation that something is correct is not a finding and carries no evidentiary weight; agreement among reviewers, or a reviewer's authority, does not settle whether a problem exists. When reviewers disagree on whether something is a problem at all — including one asserting it is fine while another flags it — treat the question as unresolved and verify it against the code, without letting the affirmation substitute for verification.

**Verdict guidance:**

- Never auto-dismiss findings about security defaults, permission escalation, or fail-open vs fail-closed behavior. Always surface these even if the behavior appears intentional.
- Readability and clarity improvements that genuinely make code cleaner are valid. Do not auto-classify cosmetic changes as subjective.
- Removing a comment that adds no information beyond the code is a valid Apply, not a subjective preference. Keep only comments that capture a constraint the code cannot express.
- Be skeptical of "defensive coding" suggestions that wrap natural code in verbose guards without evidence of real-world failures. Apply a hardening finding only when it names a failure scenario reachable in this deployment, whatever severity the reviewer attached; when the governing spec or plan bounds the system (a single operator, no concurrent writers, a handful of invited users), a scenario that bound rules out is a Skip, citing the bound.
- Machinery is scope. A finding whose fix adds a lease, lock, queue, versioning scheme, state machine, or new persistent entity expands the project even when the requirement count stays flat. Assign Escalate regardless of confidence; "making states explicit" or "staying within the approved spec" does not make the machinery proportionate. When a stated bound rules the machinery's failure scenario out entirely, Skip instead, citing the bound.
- A finding that would reverse a decision the user made earlier — in discussion or recorded in the artifact — is Escalate, naming the original decision and the new evidence beside it.
- In an iterating loop, a structural Apply triggers another full iteration; count that iteration in the change's cost when applying the Skip cost test. A finding that targets code or text introduced by an earlier iteration's accepted finding, and names no defect in it, is churn: Skip.
- When a comment at the code in question records why a behavior is unobservable through every reachable path, verify that record against the code before honoring it. A coverage finding re-reporting the gap, naming no newly reachable path that would observe the behavior, is Skip, citing the record.
- Weight reviewer authority. Feedback from trusted reviewers (repository maintainers or admins) should be treated with higher credibility even when phrased softly.
- Plan deviation is not a verdict. Do not reject a finding on the grounds that it departs from a plan's prescribed shape. When the plan records a load-bearing reason for that shape, assign Escalate so the user can weigh the trade-off. When the plan is silent on why, or the recorded reason reads like "path of least deviation" or "minimal change", treat the shape as a default and judge the finding on its own merits.

## Step 2: Devil's Advocate

After the initial assessment, challenge uncertain findings from a different angle.

Spawn when any finding has **Medium** or **Low** confidence. Send only those findings to the subagent. High-confidence findings pass through unchallenged. Skip this step entirely if all findings are High confidence.

Capture `git status --short` and `git diff HEAD | git hash-object --stdin` before spawning.

Launch a single subagent in the foreground (`model: "opus"`, no `name`). Provide the Medium/Low-confidence findings with their file locations, claims, and initial verdicts. Instruct the subagent to challenge each finding: try to prove it wrong, or confirm it with evidence. A refutation counts only when it rests on a defense, guarantee, or documented behavior the subagent located and read, or on behavior it observed by running the code; an expectation that a framework, caller, or type already handles the case returns Inconclusive and leaves the initial verdict standing. Evidence that a test fails when its subject is changed settles only that the test pins the behavior; whether the pinned behavior is the required one stays open. Where the test was written alongside its implementation, their agreement is guaranteed by construction and carries no evidence about the requirement. A finding resting on that evidence is Confirmed only when the requirement itself has been checked against the code's production consumer, or against the governing spec or plan; when neither is reachable, the subagent returns Inconclusive. The subagent's prompt must direct it to treat the shared working tree and its git index as read-only; an experiment that needs a scratch project runs in a temp directory outside the repo, or in an isolated `git worktree` created there and discarded afterward. Give that worktree its own dependency install rather than reaching the shared tree's install by any route: removing a worktree deletes through symlinks, and a redirected suite writes into the shared install. When its own install is not possible, the check is left unrun and reported as such. Afterward the subagent verifies that `git worktree list` no longer shows the worktree, that `git status --short` is clean, and that the shared tree's dependency directory still resolves (a destroyed install leaves `git status` clean, since it is gitignored). Damage the subagent cannot repair is reported with the exact repair command in place of findings.

**Verify the tree:** re-run both commands when the subagent returns, including when it terminates early or reports incomplete results. Delete what the subagent created and revert what it modified or staged, leaving everything the pre-spawn capture already showed untouched.

The subagent picks research tools based on claim type:

| Claim Type | Tool |
|------------|------|
| API deprecated/removed/changed | Documentation MCP tools or WebSearch |
| Method doesn't exist / wrong signature | Documentation MCP tools, WebSearch fallback |
| Code causes specific bug or behavior | Bash (isolated read-only test snippet) |
| Best practice or ecosystem claim | WebSearch |
| Migration or changelog lookup | WebSearch → WebFetch |

Use whatever documentation tools are available. The specific tools vary by project setup.

**Budget:** max 2 research actions per finding. If the first action is conclusive, skip the second.

### Subagent Verdicts

The subagent returns per finding:

- **Confirmed** — found evidence supporting the claim (with source)
- **Disputed** — found counter-evidence (with source and explanation)
- **Inconclusive** — no definitive evidence either way

## Step 3: Reconciliation

Merge subagent results with the initial assessment:

- **Confirmed**: verdict and severity stand. Note the evidence source.
- **Disputed**: if originally Apply, downgrade to Skip or Escalate. Re-assess severity if the evidence changes the impact picture. Show both perspectives.
- **Inconclusive**: verdict and severity stand, note the uncertainty.

Findings not investigated by the subagent keep their original verdict.

For Apply findings, document the issue and location. For Escalate findings, note what information would resolve the ambiguity. For Skip findings, document why.

## Step 4: Format Output

Summarize the evaluated findings in a table:

| File | Issue | Source | Severity | Verdict |
|------|-------|--------|----------|---------|

When Step 2 ran (any finding was investigated by the Devil's Advocate subagent), add an Investigated column:

| File | Issue | Source | Severity | Verdict | Investigated |
|------|-------|--------|----------|---------|--------------|

Where Investigated shows:
- *(empty)* — not investigated by subagent
- **Confirmed** (source) — subagent found supporting evidence
- **Disputed: [reason]** — subagent found counter-evidence

For findings whose severity was re-assessed from the upstream level, append the change in the Severity cell (e.g., "High (was Medium)").

For disputed findings, add a callout below the table showing both perspectives. For each finding, indicate scope in the Issue column (e.g., "Pre-existing:" prefix).

Then use the TaskList tool and proceed to any remaining task. The next pending skill — `/resolve-findings` or `/apply-findings` — reads the findings table directly, including Escalate verdicts, which `/apply-findings` surfaces to the user via AskUserQuestion.
