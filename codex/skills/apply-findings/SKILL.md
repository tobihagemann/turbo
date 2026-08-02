---
name: apply-findings
description: "Apply findings by making the suggested code changes. Applies accepted verdicts, escalates ambiguous findings to the user, and offers to note genuine improvements for later. Use when the user asks to \"apply findings\", \"apply fixes\", \"apply suggestions\", \"apply accepted findings\", \"fix the findings\", or \"apply the review results\"."
---

# Apply Findings

Apply evaluated findings from the conversation context. Findings must have been through `$evaluate-findings` first.

## Step 1: Identify Findings

Collect all findings from the conversation context. Findings should have Verdict columns (Apply, Skip, Escalate) from `$evaluate-findings`.

If findings are unevaluated (raw output without verdicts), stop and say to run `$evaluate-findings` first.

## Step 2: Apply in File Order

Group Apply findings by file path and apply in file order to minimize context switching. For each finding:

1. Read the full function or logical block at the referenced location
2. Verify the finding still applies to the current code
3. When the finding carries a suggested fix, treat the fix as a separate claim from the finding and verify it independently before applying it — trace it against the failure modes the finding names. If the fix does not hold up, treat the finding as Escalate (surface it in Step 3) and record why the remedy fails, rather than applying an unsound fix on the finding's authority.
4. When the fix would reverse a decision the user made earlier — in discussion or recorded in the artifact — treat the finding as Escalate (surface it in Step 3) and name the original decision.
5. Check what the fix you are about to make changes about the inputs the code accepts. When the change in accepted inputs is exactly the defect the finding names, apply it normally. When it turns away or newly admits anything beyond that defect — a value or path a legitimate caller could send — that is a behavior change: treat the finding as Escalate (surface it in Step 3) and name the input class that changes.
6. Make the fix
7. If the finding renames an identifier, search the file for all occurrences of the old name before marking the fix complete. The cited location is often only one of several references.

If a finding references code that has changed since it was generated (e.g., by a prior fix in this same run), re-assess whether it still applies. Skip if the code has diverged.

When an escalated finding's outcome would change what the other fixes should look like, settle it in Step 3 before applying them.

## Step 3: Handle Escalated Findings

For findings with Escalate verdict, use `request_user_input` to let the user decide. Output the finding's technical detail as text first, then state the question as the decision the user owns. When the finding is a disagreement between two artifacts, ask which behavior is wanted; reconciling the artifacts follows from that answer.

Recommend the genuinely best option: place it first and append `(Recommended)` to its label, judging "best" on technical merit alone (the soundest engineering outcome), independent of how closely the option conforms to the task's original scope. When the choice hinges on product intent or domain knowledge you lack and merit cannot settle it, say so instead of forcing a pick. Give each option a plain-language description that carries the trade-off: its concrete effect and what it costs. When the recommended option also widens the changeset's scope, name both its merit and that scope cost so the user can weigh them. When the choice is architectural rather than a matter of preference, offer the consultation option in place of whichever alternative fits the finding least, keeping the question at three options.

- **Apply** — make the change
- **Skip** — leave as-is
- **Note for later** — run the `$note-improvement` skill to capture it
- **Consult** — run the `$consult-claude` skill for a second opinion on the choice, or the `$consult-oracle` skill when standard approaches have already failed. Then apply, skip, or note the finding with that answer in hand

## Step 4: Format Output

Report the outcome as a table, one row per finding, keeping every cell to a single line:

| File | Finding | Outcome |
|------|---------|---------|

Where Outcome is one of:

- **Applied** — the fix was made
- **Escalated** — name the resolution the user chose: applied, skipped, or noted for later
- **Skipped** — name the reason

Keep the report to the table. Add prose only where an escalation's resolution changed what the other fixes look like.

Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

## Rules

- Only edit files. Do not stage, build, or test.
