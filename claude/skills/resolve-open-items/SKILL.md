---
name: resolve-open-items
description: "Walk the open items listed above the prompt and settle each through AskUserQuestion. Use when the user asks to \"resolve open items\", \"walk the open items\", or \"what's waiting on me\"."
---

# Resolve Open Items

Settle each open item with one question per item, acting on every answer before the next round.

## Step 1: List the Open Items

Call the `mcp__turbo__open-items` tool with `action` set to `list`. When it answers that there are no open items, present "No open items." Then use the TaskList tool and proceed to any remaining task.

## Step 2: Settle Each Item

Use `AskUserQuestion`, one question per item in the order `list` returns them, filling each call to its four-question limit:

- **Header** — `#<id>`
- **Question** — the item's line, plus whatever its detail adds that the answer depends on
- **Options** — at most four, by the kind of item. Give each option a description saying what choosing it does and what it gives up.
  - **Decision**, where the detail names choices. Fill the four options in this order and leave out whatever does not fit:
    1. The choice the detail recommends, with "(Recommended)" appended and the reason in its description. When no choice earns it with conviction, the most likely choice, unlabeled.
    2. **Get a second opinion**, when the decision is costly to reverse (it establishes a pattern others will follow, defines an interface, commits to a data shape, or imports a pattern the codebase has not used) or no choice earns "(Recommended)" with conviction. Leave it out when asking about an item again after a consultation.
    3. The other choices, most likely first.
    4. **Not yet**, then **Note for later**.

    End the question by naming each choice or deferral left out as available under "Other".
  - **Action**, where only the user can do it: **Done**, **Not yet**, and **Note for later**.
  - **Open question**, an item with no listed choices: the answers the conversation supports, then **Not yet** and **Note for later**, leaving out whatever does not fit and naming it in the question as available under "Other". When the conversation supports no answer, invite it under "Other".

After each call, act on its answers before the next call. An answer given under "Other" that names a choice, "not yet", or "note for later" takes that option's branch.

- **A choice** — carry it out, then call the tool with `action` set to `resolve` and the item's `id`.
- **Done** — the user already did it. Acknowledge it and resolve the item without repeating the action.
- **Note for later** — run the `/backlog` skill with the item. Resolve the item only when that skill wrote the entry. When it could only print the entry, leave the item open and say so.
- **Not yet** — leave the item open.
- **Get a second opinion** — run the `/consult-codex` skill. On a technical choice, ask for the soundest choice on technical merit alone, independent of how closely it conforms to the original scope, and carry any scope cost back with the answer. On a question of product intent, ask what each choice commits to, what reversing it costs, and what the prevailing convention is. Then ask about that item again with the answer in hand.
- **An instruction or a question** — act on it. When that settles the item or makes it moot, resolve it. Ask about it again only while it stays open.

Before the next call, resolve any unasked item that earlier answers settled or made moot, and leave it out of the call. Repeat until no item remains to ask. Then call the tool with `list` again, and settle any item it shows that this walk has not asked about.

## Step 3: Report

Output, by `#<id>`, what was settled and what stays open. Then use the TaskList tool and proceed to any remaining task.
