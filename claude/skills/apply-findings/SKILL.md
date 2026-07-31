---
name: apply-findings
description: "Apply findings by making the suggested code changes. Applies accepted verdicts, escalates ambiguous findings to the user, and offers to note genuine improvements for later. Use when the user asks to \"apply findings\", \"apply fixes\", \"apply suggestions\", \"apply accepted findings\", \"fix the findings\", or \"apply the review results\"."
---

# Apply Findings

Apply evaluated findings from the conversation context. Findings must have been through `/evaluate-findings` first.

## Step 1: Identify Findings

Collect all findings from the conversation context. Findings should have Verdict columns (Apply, Skip, Escalate) from `/evaluate-findings`.

If findings are unevaluated (raw output without verdicts), stop and say to run `/evaluate-findings` first.

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

## Step 3: Handle Escalated Findings

For findings with Escalate verdict, use `AskUserQuestion` to let the user decide. Recommend the genuinely best option: place it first and append `(Recommended)` to its label, judging "best" on technical merit alone (the soundest engineering outcome), independent of how closely the option conforms to the task's original scope. When the choice hinges on product intent or domain knowledge you lack and merit cannot settle it, say so instead of forcing a pick. Give each option a plain-language description that carries the trade-off: its concrete effect and what it costs. When the recommended option also widens the changeset's scope, name both its merit and that scope cost so the user can weigh them. When the choice is architectural rather than a matter of preference, include the consultation option alongside the concrete alternatives.

- **Apply** — make the change
- **Skip** — leave as-is
- **Note for later** — run the `/note-improvement` skill to capture it
- **Consult** — run the `/consult-codex` skill for a second opinion on the choice, or the `/consult-oracle` skill when standard approaches have already failed. Then apply, skip, or note the finding with that answer in hand

## Step 4: Report Results

Summarize what was applied, what was escalated, and what was skipped.

Then use the TaskList tool and proceed to any remaining task.

## Rules

- Only edit files. Do not stage, build, or test.
- If two Apply findings conflict (suggest opposite changes to the same code), surface the conflict with `AskUserQuestion`, recommend the genuinely best option on technical merit, and let the user choose, rather than applying either.
