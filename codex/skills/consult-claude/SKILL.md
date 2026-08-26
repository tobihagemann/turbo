---
name: consult-claude
description: "Consult Claude Code for second opinions, brainstorming, or difficult debugging from Codex. Use when the user asks to \"consult claude\", \"ask claude\", \"get claude's opinion\", \"brainstorm with claude\", or \"discuss with claude\"."
---

# Consult Claude

Use Claude Code as an external collaborator from Codex. Unlike `$peer-review`, this skill is conversational and exploratory.

## Step 1: Define the Question

State:

- What problem needs input
- What has already been tried
- What constraints the answer must respect
- What files, commands, plans, or error messages matter
- What kind of answer is useful: hypotheses, tradeoffs, concrete fix, or review

When a recommendation is wanted, bar answers that appeal to scope: state that "out of scope" or "leave it alone" is not an acceptable argument on its own, and that recommending no change must be justified on technical merit. Demand one pick per decision, the reasoning, and the strongest counterargument to that pick, with hedging across options ruled out.

When the consultation is a prose rewrite bound by a house style, name the shapes that style forbids in the first prompt, so they do not have to be corrected across follow-up turns. Common ones: prefixing a summary with a grammatical subject the convention omits, expanding a pronoun to its full noun phrase at every occurrence, and splitting a sentence so a condition is restated in both halves.

## Step 2: Run `$claude-print` Skill

Run the `$claude-print` skill with the assembled question. Default to read-only permissions.

For follow-up questions, include Claude's previous answer and the new evidence gathered since then.

When the recommendation would violate a documented constraint, follow up rather than discarding or adopting it. Quote the constraint back and ask Claude to argue it out: whether the constraint is sound or was set without the problem Claude identified in view, whether that problem is reachable given code Claude may not have accounted for, and what the best fix that respects the constraint is. Ask it to quantify the exposure rather than assert it, and say that reversing its prior recommendation is acceptable.

## Step 3: Synthesize

Summarize the useful parts of Claude's response. Cross-reference suggestions with the repository before acting.

When the consultation rewrote prose rather than answering a question, check the rewrite against the source yourself before adopting it. Treat its own report that the rewrite is faithful as a claim awaiting verification. Verify the source's own factual claims against what they describe, since a rewrite can be faithful to a source that was itself wrong. Read for these drift shapes in the rewrite:

- a tense change that promotes a capability into an event
- a compression that promotes a hedge into a fact, or flattens out the reasoning that made a sentence worth keeping
- a rule promoted into an enforcement claim
- a narrowing that recasts an absence of information as a limitation of what it describes
- an inverted direction in a described mapping
- a term renamed in prose, drifting from the identifier it documents
- a precise word swapped for a vaguer one, or a dropped modifier that carried the argument
- dropped markup or function words, articles included
- a split that separates clauses whose relationship is the point
- a split that strands a pronoun on the wrong noun

Take the plainer sentences and keep the load-bearing why.

When the consultation was opened from a pending question, resolve that question with the answer in hand, re-asking the user when the choice stays theirs. Then call `update_plan` to mark this step completed and continue with the next step of the active workflow.

## Rules

- Claude's answer is advisory.
- Do not apply a suggestion until it has been checked against the actual codebase.
- Keep each Claude turn focused on one question.
