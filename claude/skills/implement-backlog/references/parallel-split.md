# Implement Backlog: Parallel Split

Hand each parallel set the user confirmed in SKILL.md Step 3 to an extra session.

## Task Tracking

Use `TaskCreate` to create a task for each phase:

1. Get the extra sessions
2. Brief each extra session

## Phase 1: Get the Extra Sessions

### Inside tmux

When `$TMUX` is set, open the extra sessions yourself in panes beside this one. Run each tmux command via the Bash tool (`dangerouslyDisableSandbox: true`), with `<root>` the repo root SKILL.md Step 1 resolved. Open the first session beside this pane:

```bash
tmux split-window -h -d -t "$TMUX_PANE" -c "<root>" -P -F '#{pane_id}' claude
```

Open each further one below the pane opened before it, with `-v` in place of `-h` and that pane's id in place of `"$TMUX_PANE"`. When tmux refuses a split for lack of space, open that session in a window of its own with `tmux new-window -d -c "<root>" -P -F '#{pane_id}' claude`. When `$CLAUDE_CONFIG_DIR` is set, add `-e "CLAUDE_CONFIG_DIR=$CLAUDE_CONFIG_DIR"` to each of these commands. Note each pane id they print.

Then use the ListAgents tool. The extra sessions are the ones whose tmux location ends in a noted pane id. While a noted pane id appears in no session's location, read what that pane displays with `tmux capture-pane -p -t <pane id>`, then list again, up to five listings in all.

When a tmux command fails or is refused, or a noted pane id still appears in no session's location after the fifth listing, report what each such pane displays and follow Outside tmux for the sessions still missing. Otherwise, continue with Phase 2.

### Outside tmux

Output how many extra sessions the split still needs, and ask the user to open that many Claude Code sessions in this directory. Then use `AskUserQuestion` to confirm, with two options: the sessions are open, or run without the missing sessions.

When the user chose to run without the missing sessions and no extra session was found, the parallel sets stay in the backlog. Mark Phase 2 completed, then use the TaskList tool and proceed to any remaining task.

Otherwise, use the ListAgents tool. The extra sessions are the local sessions in this directory that the SKILL.md Step 3 listing did not show. When fewer appeared than the split needs, hand out the parallel sets in the order Step 3 named them and leave the rest in the backlog. When more appeared, use `AskUserQuestion` to ask which ones to brief.

## Phase 2: Brief Each Extra Session

Send each extra session one message with the SendMessage tool, using this template:

```
[Opening for the set's lane]

Main checkout: [absolute path of the repo root SKILL.md Step 1 resolved]. Once in a worktree, copy from the main checkout each file the worktree lacks that the work needs, such as gitignored local configuration or untracked project instructions, and leave each copied file out of every commit.

The entries were validated against the code in the session that sent this.

Lane: [direct, investigate, or plan]

Working set:
- [summary] — [Where] — [what the validation established is still to do]

Sets other sessions are working at the same time:
- [session name]: [the files its set touches]

When your work turns out to need one of those files, message that session before editing it.
```

Fill the opening by lane:

- **Direct or investigate** — "Enter a git worktree of your own with the EnterWorktree tool. Then invoke `/implement-backlog` via the Skill tool with the working set and lane below."
- **Plan** — "Stay in this checkout and change no file outside `.turbo/`. Invoke `/implement-backlog` via the Skill tool with the working set and lane below. When `/plan` routes the work to a direct change, enter a git worktree of your own with the EnterWorktree tool before editing. When `/plan` writes a plan, implement it in a git worktree of your own."

List every other set in each brief, the recommended working set under this session's own name included.

Continue with the recommended working set without waiting for the briefed sessions. Leave each briefed session's gates to the user.

Then use the TaskList tool and proceed to any remaining task.
