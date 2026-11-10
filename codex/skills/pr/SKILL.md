---
name: pr
description: "Create or update the current branch's GitHub pull request with a drafted title and description. Use when the user asks to \"create a PR\", \"open a PR\", \"update the PR\", or \"update PR description\"."
---

# Pull Request

Create the branch's pull request, or bring an existing one's title and description up to date with the branch.

## Route to Create or Update

Both routes draft by the rules in [references/body-elements.md](references/body-elements.md). Read it alongside the route's reference, before the first phase.

When this request gives a PR number, read [references/update.md](references/update.md) and follow its phases for that PR.

Otherwise, look up the current branch's PR. A base branch given with the request is the base of a new PR, never a lookup key.

```bash
gh pr view --json number,state
```

When the lookup fails for any reason other than finding no PR, report the error and stop.

- **The branch has an open PR** — read [references/update.md](references/update.md) and follow its phases for that PR's number.
- **The branch has no PR, or only a closed or merged one** — read [references/create.md](references/create.md) and follow its phases.
