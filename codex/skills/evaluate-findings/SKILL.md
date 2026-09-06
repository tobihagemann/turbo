---
name: evaluate-findings
description: "Critically assess external feedback (code reviews, AI reviewers, PR comments) and decide which suggestions to apply using adversarial verification. Use when the user asks to \"evaluate findings\", \"assess review comments\", \"triage review feedback\", \"evaluate review output\", or \"filter false positives\"."
---

# Evaluate Findings

Assess external feedback (code reviews, AI suggestions, PR comments) with adversarial verification. Triage findings into actionable verdicts. Do not apply fixes.

## Step 1: Assess Each Finding

If you already assessed a finding earlier in this session and recorded a verdict of Skip or Escalate — for example when an iterating loop re-runs review and the same finding resurfaces — do not re-adjudicate it from scratch. When a loop ledger path (`.turbo/loops/<slug>.md`) is in context, read it and treat its recorded verdicts the same way. When the re-reported finding matches one you already judged (same location and substance) and presents no new evidence beyond what your recorded reason already accounts for, keep that verdict and reason without re-reading the code, re-verifying, or routing it to the Devil's Advocate in Step 2. Assess fresh only when the finding raises materially new evidence, or when you have not judged it before in this session.

When several findings rest on a shared premise — for example a source-of-truth choice — verify that premise once before adjudicating them individually. Findings whose premise holds proceed through normal per-finding verification; when it fails, they are all Skip, citing the refuted premise.

When a plan governs the work, re-read the decisions it records before adjudicating. Having read it earlier in the session does not count: once it falls out of context, a recorded decision is indistinguishable from no decision at all.

For each finding:

1. **Read the referenced code** at the mentioned location — include the full function or logical block, not just the flagged line
2. **Check whether the code has diverged** — if the finding references code that no longer exists or has since changed, skip it and note the divergence.
3. **Determine scope** — clarify whether the issue was introduced by the PR/changeset or is pre-existing.
   - Pre-existing issues in earlier commits on the same feature branch are in-scope by default — the entire branch is one coherent unit of work. Judge these on their merits like any in-scope finding.
   - Findings genuinely outside the branch's work are the user's call to include. Assign Escalate so the user decides whether to widen the changeset. Reserve Skip for changes whose cost wildly dwarfs the benefit.
4. **Verify the claim** against the actual code — does the issue genuinely exist?
   - When the finding offers a concrete example as evidence — a claimed mishandled input, a claimed wrong output — verify that example independently: a finding can hold in substance while its example does not. Keep the finding and record the correction beside it; drop it only when the claim rests on that example alone.
   - When the finding asserts a compatibility property, establish two things before assigning Apply: what the existing check actually enforces, and what real counterparts produce today. A claim stronger than the check enforces is a premise error rather than a defect — Skip, citing what the check enforces, or narrow the finding to the property it does enforce and record the narrowing beside it. When neither can be established from the code, the artifacts, or authoritative documentation, keep the finding Escalate.
   - When the finding cites a rule or convention, read the cited text, then look for a place that already applied it before this changeset — the same file, or the nearest files the rule also governs. Where the text alone leaves the reading open, read the rule the way that application reads it; where no such application exists, judge on the text alone.
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

An affirmation that something is correct is not a finding and carries no evidentiary weight; agreement among reviewers, or a reviewer's authority, does not settle whether a problem exists, nor whether a remedy the reviewers converged on works. When reviewers disagree on whether something is a problem at all — including one asserting it is fine while another flags it — treat the question as unresolved and verify it against the code, without letting the affirmation substitute for verification.

A reviewer's report that it could not verify something is a claim to check, not a fact to accept. Attempt the check independently, especially when the reported inability is what justifies skipping a verification step.

**Verdict guidance:**

- A verdict records whether the finding is real: genuine defect, in scope, at what severity. A finding can hold while the remedy proposed for it does not, so a verdict never certifies the remedy. Judge the remedy's cost and scope where the bullets below call for that, and leave whether it works to be checked when it is applied. Where naming the likely direction helps the user, put it in the Issue cell flagged as unverified.
- Never auto-dismiss findings about security defaults, permission escalation, or fail-open vs fail-closed behavior. Always surface these even if the behavior appears intentional.
- Readability and clarity improvements that genuinely make code cleaner are valid. Do not auto-classify cosmetic changes as subjective.
- Removing a comment that adds no information beyond the code is a valid Apply, not a subjective preference. Keep only comments that capture a constraint the code cannot express.
- Be skeptical of "defensive coding" suggestions that wrap natural code in verbose guards without evidence of real-world failures. Apply a hardening finding only when it names a failure scenario reachable in this deployment, whatever severity the reviewer attached; when the plan's Context bounds the system (a single operator, no concurrent writers, a handful of invited users), a scenario that bound rules out is a Skip, citing the bound.
- Machinery is scope. A finding whose fix adds a lease, lock, queue, versioning scheme, state machine, or new persistent entity expands the project even when the requirement count stays flat. Assign Escalate regardless of confidence; "making states explicit" or "staying within the approved plan" does not make the machinery proportionate. When a stated bound rules the machinery's failure scenario out entirely, Skip instead, citing the bound.
- A finding that would reverse a decision the user made earlier — in discussion or recorded in the artifact — is Escalate, naming the original decision and the new evidence beside it. Judge by the outcome rather than the wording of the option the user chose: a reversal leaves the user with something materially different from what they chose. A finding that refutes only the factual premise the user's choice rested on, leaving the chosen outcome intact, is a premise correction: confirm the refutation against whichever of the code, the governing artifact, or authoritative documentation the premise turns on, and when none settles it, keep the finding Escalate. Otherwise assign Apply unless another bullet independently calls for Escalate, and add a callout below the table naming both the corrected premise and the chosen outcome it leaves standing.
- In an iterating loop, a structural Apply triggers another full iteration; count that iteration in the change's cost when applying the Skip cost test. A finding that targets code or text introduced by an earlier iteration's accepted finding, and names no defect in it, is churn: Skip.
- When a comment at the code in question records why a behavior is unobservable through every reachable path, verify that record against the code before honoring it. A coverage finding re-reporting the gap, naming no newly reachable path that would observe the behavior, is Skip, citing the record.
- Weight reviewer authority. Feedback from trusted reviewers (repository maintainers or admins) should be treated with higher credibility even when phrased softly.
- Plan deviation is not a verdict. Do not reject a finding on the grounds that it departs from a plan's prescribed shape. When the plan records a load-bearing reason for that shape, assign Escalate so the user can weigh the trade-off. When the plan is silent on why, or the recorded reason reads like "path of least deviation" or "minimal change", treat the shape as a default and judge the finding on its own merits.

## Step 2: Devil's Advocate

After the initial assessment, challenge uncertain findings from a different angle.

Spawn when any finding has **Medium** or **Low** confidence. Send only those findings to the sub-agent. High-confidence findings pass through unchallenged. Skip this step entirely if all findings are High confidence.

Capture `git status --short`, `git diff HEAD | git hash-object --stdin`, and `git symbolic-ref --short -q HEAD` before spawning.

Launch a single sub-agent (inherited model defaults). Provide the Medium/Low-confidence findings with their file locations, claims, and initial verdicts. Instruct the sub-agent to challenge each finding: try to prove it wrong, or confirm it with evidence.

**Evidence standards:** A refutation counts only when it rests on a defense, guarantee, or documented behavior the sub-agent located and read, or on behavior it observed by running the code; an expectation that a framework, caller, or type already handles the case returns Inconclusive and leaves the initial verdict standing. Confirmed applies to the claim the finding stands or falls on. Establishing the premise beneath that claim leaves it open: that code reads a value settles nothing about whether a test can control that value. When the sub-agent has established only the premise, it returns Inconclusive. Evidence that a test fails when its subject is changed settles only that the test pins the behavior; whether the pinned behavior is the required one stays open. Where the test was written alongside its implementation, their agreement is guaranteed by construction and carries no evidence about the requirement. A finding resting on that evidence is Confirmed only when the requirement itself has been checked against the code's production consumer, or against the governing plan; when neither is reachable, the sub-agent returns Inconclusive.

**Protect the shared tree:** The sub-agent's prompt must direct it to treat the shared working tree and its git index as read-only; an experiment that needs a scratch project runs in a temp directory outside the repo, or in an isolated `git worktree` created there and discarded afterward. HEAD stays where it is: read other refs with `git show <ref>:<path>` rather than `git checkout` or `git switch`. Give that worktree its own dependency install rather than reaching the shared tree's install by any route: removing a worktree deletes through symlinks, and a redirected suite writes into the shared install. When its own install is not possible, the check is left unrun and reported as such. Afterward the sub-agent verifies that `git worktree list` no longer shows the worktree, that `git status --short` is clean, that HEAD is still on the branch it started on, and that the shared tree's dependency directory still resolves (a destroyed install leaves `git status` clean, since it is gitignored). Damage the sub-agent cannot repair is reported with the exact repair command in place of findings.

**Verify the tree:** re-run all three commands when the sub-agent returns, including when it terminates early or reports incomplete results. Delete what the sub-agent created, revert what it modified or staged, and return HEAD to the captured branch, leaving everything the pre-spawn capture already showed untouched.

The sub-agent picks research tools based on claim type:

| Claim Type | Tool |
|------------|------|
| API deprecated/removed/changed | Documentation MCP tools or web search |
| Method doesn't exist / wrong signature | Documentation MCP tools, web search fallback |
| Code causes specific bug or behavior | Shell (isolated read-only test snippet) |
| Best practice or ecosystem claim | Web search |
| Migration or changelog lookup | Web search → web fetch |

Use whatever documentation tools are available. The specific tools vary by project setup.

**Budget:** max 2 research actions per finding. If the first action is conclusive, skip the second.

### Sub-agent Verdicts

The sub-agent returns per finding:

- **Confirmed** — found evidence supporting the claim (with source)
- **Disputed** — found counter-evidence (with source and explanation)
- **Inconclusive** — no definitive evidence either way

## Step 3: Reconciliation

Merge sub-agent results with the initial assessment:

- **Confirmed**: verdict and severity stand. Note the evidence source.
- **Disputed**: if originally Apply, downgrade to Skip or Escalate. Re-assess severity if the evidence changes the impact picture. Show both perspectives.
- **Inconclusive**: verdict and severity stand, note the uncertainty.

Findings not investigated by the sub-agent keep their original verdict.

For Apply findings, document the issue and location. For Escalate findings, note what information would resolve the ambiguity. For Skip findings, document why.

## Step 4: Format Output

Summarize the evaluated findings in a table:

| File | Issue | Source | Severity | Verdict |
|------|-------|--------|----------|---------|

When Step 2 ran (any finding was investigated by the Devil's Advocate sub-agent), add an Investigated column:

| File | Issue | Source | Severity | Verdict | Investigated |
|------|-------|--------|----------|---------|--------------|

Where Investigated shows:
- *(empty)* — not investigated by sub-agent
- **Confirmed** (source) — sub-agent found supporting evidence
- **Disputed: [reason]** — sub-agent found counter-evidence

For findings whose severity was re-assessed from the upstream level, append the change in the Severity cell (e.g., "High (was Medium)").

Carry each verdict into the Verdict column exactly as assessed, Escalate included.

For disputed findings, add a callout below the table showing both perspectives. For each finding, indicate scope in the Issue column (e.g., "Pre-existing:" prefix).

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.
