# Tool Usage in Skills

How to phrase tool invocations so the executing agent uses the right mechanism with the right parameters.

## Contents

- Dispatching Agent Tool Calls
  - Phrase Multi-Agent Parallel Dispatch Imperatively
  - Hoist Conditional Opt-Out Checks Above Dispatch Logic
  - Skill Tool Calls Don't Parallelize with Agent Calls
  - Keep Parallel Review/Analysis Subagents Read-Only on the Shared Tree
- Dispatching Bash Tool Calls
- Using AskUserQuestion
  - Output Content as Text Before AskUserQuestion
  - Prefer AskUserQuestion Gates over Anti-Skip Prose Rules
  - AskUserQuestion Doesn't Work in Sub-Agents
- Referencing MCP Tools

## Dispatching Agent Tool Calls

When a skill spawns subagents, make foreground execution a salient, standalone instruction in plain words — e.g. "Run them in the foreground so all results return in this turn." Subagents background by default: the harness auto-decides and leans background, especially when the spawning agent does not strictly need the results inline. Do not rely on the `run_in_background: false` parameter — the executing model treats `false` as the redundant schema default and silently drops it, and burying the intent in a parenthetical alongside `model`/`run_in_background` loses salience under context load (the observed real-world failure mode). State the foreground intent as its own sentence and keep only `model` in the parenthetical. Vague phrasing like "launch concurrently" or "in parallel" lets the agents background.

Multiple Agent tool calls in a single message run in parallel. Prefer foreground agents over background agents:

- **Foreground parallel** (recommended): Multiple Agent calls in one message run concurrently and return all results in the same turn. A standalone "run them in the foreground" directive is what reliably keeps them foreground; tying it to needing the results inline ("so all results return in this turn") reinforces it.
- **Background**: The parent is notified as each subagent finishes and collects results then, across turns. Only use background agents when the main thread has genuinely independent work and does not need the agents' output to proceed.

- ✗ **Avoid**: "Launch all four agents concurrently in a single message."
- ✗ **Avoid**: "Spawn a subagent to review the output."
- ✓ **Good**: "Launch all four agents in a single message. Run them in the foreground so all results return in this turn (`model: "opus"`)."

### Phrase Multi-Agent Parallel Dispatch Imperatively

Tool calls within a single assistant message run concurrently. Tool calls across separate messages run sequentially. To fan out N Agents in parallel, emit one assistant message containing N Agent tool calls.

Write the dispatch step as one imperative sentence followed by uniform bulleted Agent roles:

> Use the Agent tool to launch all <N> agents below in a single assistant message so they run concurrently. Run them in the foreground so all their results return in this turn. Each Agent call uses `model: "opus"`.

State the total call count as a number, even when a single bullet expands to multiple calls (e.g., "one Agent per active type, expect <N> total"). The number anchors the fan-out so the full set goes out in one batch.

When the items being parallelized are themselves skills, each parallel item is an Agent tool call whose prompt invokes the target skill via the Skill tool. The Agent fan-out parallelizes; the Skill load is the work each Agent does.

### Hoist Conditional Opt-Out Checks Above Dispatch Logic

When a step has a conditional opt-out (e.g., "skip peer review" reduces N+1 to N Agents), put the check at the top of the step before describing the dispatch. If the opt-out subsection appears after the per-Agent subsections, a reader plans the full dispatch and only learns about the opt-out after — easy to ignore at execution time.

- ✗ **Avoid**: Describe Agent A, Agent B, Agent C — then add a final "Skipping C" subsection.
- ✓ **Good**: Open the step with "Determine whether to skip C: if the run was asked to skip, set the dispatch to A+B; otherwise A+B+C." Then describe each Agent.

### Skill Tool Calls Don't Parallelize with Agent Calls

The Skill tool loads instructions and returns immediately — the actual work (Bash calls, agent spawns, etc.) happens in subsequent turns, after any parallel Agent calls have already completed. To truly parallelize a skill's work with other agents, wrap it in an Agent that loads and executes the skill internally.

- ✗ **Avoid**: Launching Agent + Agent + Skill in one message expecting all three to do work concurrently.
- ✓ **Good**: Launching three Agents in one message, each running its respective skill.

### Keep Parallel Review/Analysis Subagents Read-Only on the Shared Tree

When a skill fans out parallel subagents that read the same working tree (reviewers, analyzers, mappers), direct each subagent's prompt to treat the shared working tree and its git index as read-only. Concurrent agents editing files or running git state-changing commands (`add`, `commit`, `checkout`, `restore`, `stash`, `reset`) on the tree they all share race each other and the orchestrator, and a botched restore can corrupt uncommitted work or poison the index.

Give a sanctioned outlet rather than banning empirical work: a subagent that needs to verify a finding (such as a mutation experiment to confirm a test is non-vacuous) creates an isolated `git worktree`, experiments there, and discards it. Default to reading and reasoning; reach for a worktree only when empirical proof materially raises confidence.

Put the constraint in the per-subagent dispatch instruction — the text that reaches the subagent — not only in the orchestrator's Rules section. An orchestrator-level "does not modify" line governs the orchestrator, not the subagents it launches.

- ✗ **Avoid**: A Rules line "Analysis-only: does not modify source code" with no read-only constraint in the subagent prompts.
- ✓ **Good**: "Every agent's prompt directs it to treat the shared working tree and its git index as read-only; any empirical check runs in an isolated `git worktree` it discards afterward."

## Dispatching Bash Tool Calls

When a skill's Bash invocation needs non-default parameters (`timeout`, `dangerouslyDisableSandbox`), specify them in a parenthetical the same way as for Agent calls. Vague phrasing like "use a generous timeout" leaves Claude to guess which timeout (Bash tool parameter vs. shell `timeout` command) and what value.

- ✗ **Avoid**: "Use a generous timeout."
- ✗ **Avoid**: "Wrap the command in a shell `timeout` of 1 hour: `timeout 3600 X`."
- ✓ **Good**: "Run X via the Bash tool (`timeout: 600000`, do not set `run_in_background`)."

The parenthetical names parameters and values directly, parallel to (`model: "opus"`) for Agent calls. The Bash tool stays foreground when `run_in_background` is omitted, so "do not set `run_in_background`" is the correct foreground phrasing for Bash calls (unlike the Agent tool, whose subagents background by default — see Dispatching Agent Tool Calls above). The Bash `timeout` maximum (600000 ms) is enforced: a larger value is not honored — the harness backgrounds the call immediately and hard-kills it at 600s, truncating output. Cap at `timeout: 600000`; if the command overruns that window, the harness force-backgrounds it and it runs to completion, recoverable by reading its output file. Reach for a shell wrapper like GNU `timeout` only when the Bash tool's parameter cannot achieve the goal.

## Using AskUserQuestion

When a skill needs user input, reference the tool by name (`AskUserQuestion`) instead of vague phrasing like "ask the user" or "wait for user confirmation." Naming the tool directly ensures the executing Claude instance uses the right mechanism.

- ✗ **Avoid**: "Ask the user which option they prefer."
- ✓ **Good**: "Use `AskUserQuestion` to determine which option the user prefers."

### Output Content as Text Before AskUserQuestion

When a skill presents structured content (tables, plans, reports) before asking for approval, output the content as text first. `AskUserQuestion` has limited UI space and should only carry the approval prompt, not the content being reviewed.

- ✗ **Avoid**: "Present the test plan to the user with `AskUserQuestion` before executing."
- ✗ **Avoid**: "Show the drafted context to the user via `AskUserQuestion` for approval."
- ✓ **Good**: "Output the plan as text. Then use `AskUserQuestion` to ask for approval."

### Prefer AskUserQuestion Gates over Anti-Skip Prose Rules

Workflow skills often need to prevent the agent from skipping steps ("don't rationalize away the re-run") or stopping early at iteration caps. Verbose "Do NOT" blocks and anti-rationalization prose are unreliable: the agent reads the rule and still finds ways to rationalize around it. Convert soft rules into hard gates using `AskUserQuestion`.

- **Skip gate**: When the agent might want to skip a re-run that should happen (e.g., changes were made but the agent judges re-running unnecessary), require it to use `AskUserQuestion` to request skip permission. This converts "don't skip silently" into "can't skip silently."
- **Exhaustion gate**: When a loop reaches its iteration cap but hasn't stabilized, use `AskUserQuestion` to ask whether to continue for another iteration or escalate to a different approach. This replaces the hard stop with a human-in-the-loop decision.
- **Blocker gate**: When a step is blocked by a missing dependency, unclear requirement, or environmental issue that needs user input to resolve, use `AskUserQuestion` to surface the blocker and let the user choose how to proceed. Phrasing like "halt and report" or "stop" leaves no recovery path; an `AskUserQuestion` gate keeps the workflow live.

```markdown
**If changes were made**, run `/this-skill` again using the Skill tool.

**If changes were made but you believe re-running is unnecessary**, use `AskUserQuestion` to ask for skip permission. Do not skip silently.

**If this is iteration 3 and changes were still made**, the hard cap is reached. Use `AskUserQuestion` to tell the user that 3 iterations were not enough to stabilize, summarize what is still changing, and offer two options: continue for another iteration, or escalate to a different approach for the remaining issues.
```

Removing verbose "Do NOT" blocks and "Rules" sections that restate the anti-skip rule often wins alongside adding the gates: the prose was unreliable anyway, and the gates replace it with enforceable behavior.

### AskUserQuestion Doesn't Work in Sub-Agents

`AskUserQuestion` only reaches the user when the skill runs in the main conversation. When a skill runs inside an `Agent` tool call, the question cannot be surfaced — the sub-agent either errors or drops the call silently. Skills that commonly run as sub-agents (invoked by workflow skills that fan out via the Agent tool) need deterministic fallbacks instead of interactive questions.

- **Missing input** — stop and state what could not be resolved. The parent agent reads the sub-agent's output and can relay or act on it.
- **Disambiguation** — pick a deterministic default (e.g., most recently modified file) rather than asking which option to use.
- **Main-context-only fallbacks** — a sub-agent can in principle self-detect via system-prompt phrasing and branch on whether to call `AskUserQuestion`, but the cost of that branching is usually worse than just removing the question entirely.

## Referencing MCP Tools

When referencing a *specific known* MCP (Model Context Protocol) tool, always use fully qualified tool names to avoid "tool not found" errors.

**Format**: `ServerName:tool_name`

Where `ServerName` is the MCP server name and `tool_name` is the tool within that server. Without the server prefix, Claude may fail to locate the tool, especially when multiple MCP servers are available.

When a skill needs a *category* of tool rather than a specific one (e.g., documentation lookup), reference the category generically. Different projects have different MCP servers installed.

- ✗ **Avoid**: "Use the context7 MCP to look up library docs."
- ✓ **Good**: "Use documentation MCP tools or WebSearch to look up library docs."
