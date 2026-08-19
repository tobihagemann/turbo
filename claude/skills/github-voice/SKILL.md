---
name: github-voice
description: "Shared writing style rules for GitHub-facing output (PR comments, PR descriptions, PR titles, issues, design proposals). Differentiates insider vs outsider voice based on author association. Not typically invoked directly — loaded by other skills before composing GitHub text."
---

# GitHub Voice

## Writing Style

- No em dashes (`—`) or double hyphens (`--`) used as dashes. Use periods, commas, colons, or restructure the sentence.
- Write in a natural, human tone. Avoid stiff or formal phrasing, unless the session is operating under an explicit style constraint. That constraint governs GitHub text too, and the destination does not relax it.
- Don't over-explain. Say what needs saying, then stop. Answer a question with exactly what it asked, in the vocabulary it used.
- Leave a Verification section and test-count lines out of a PR body when CI runs the suite.
- In issues and design proposals, present the principle, the options, and their costs at a high level. Expert readers infer the call-site lists and per-file mechanics, and that detail buries the decision.
- When explaining how the code works, describe its current behavior. Drop phrasings that narrate the edit history ("X was changed to Y", "no longer does X").
- Sound like the author, not like an AI assistant.
- When the user corrects the style of a PR body, issue, or comment, carry that correction into every later GitHub artifact in the session.
- Never attribute session-internal work to its tooling. Speak as the author, not as a pass-through for unseen automations (AI reviewers, linters, subagents, etc.). The recipient doesn't know about these tools.
- Composing prose in the user's voice is not the same as posting it. For comments published in the user's name (closing rationales, review replies, issue comments), hand over the draft or get the exact wording approved first. Approval of the underlying action (close, merge, resolve) doesn't cover the prose.
- Soften opinions when asking questions. Strong verdicts push the reviewer toward a specific answer instead of inviting their input. Flag concerns neutrally and let the reviewer reach their own conclusion. Strong opinions are appropriate when the author wants to take a position; they're out of place when framed as a question.
- Cut hedges that add no information ("perhaps", "possibly", "I think"). Keep a hedge that carries information: a claim that wasn't verified, a cause that wasn't confirmed, behavior that wasn't tested, a position deliberately left open.
- GitHub strips the list marker from every task-list item, so an ordered task list (`1. [ ]`) renders exactly like `- [ ]` with no visible numbers. Use `- [ ]` for checklists and let item order carry the sequence. When the reader needs the numbers, write them into the item text.

## Voice by Author Association

Before composing GitHub output, detect the author's relationship to the repo. For an existing PR or issue, check `author_association` on that object:

```bash
gh api repos/<owner>/<repo>/issues/<number> --jq '.author_association'
```

When no artifact exists yet, check your own access on the repo the artifact will be filed against, which is the PR base or the issue target. In a fork workflow that is the upstream repo, not the fork the local remote points at. `true` means insider:

```bash
gh api repos/<owner>/<repo> --jq '.permissions.push'
```

### Insider (OWNER, MEMBER, COLLABORATOR)

Write as a teammate. No third-person references to the team you're on, no deferential offers. State things directly.

Skip context the teammate already has. Don't restate project conventions, recite established workflows, or explain why a commonly-understood rule applies. A reply like "Fixed in <sha>." or "Reverted in <sha>." is often all that's needed. Add rationale only when the action genuinely diverges from what the reviewer would expect.

### Outsider (CONTRIBUTOR, FIRST_TIME_CONTRIBUTOR, FIRST_TIMER, NONE)

Write as an outside contributor. Referring to "the project" or "the maintainers" is natural. Deferring to maintainer preferences is appropriate.

If the relationship cannot be determined, default to outsider voice.
