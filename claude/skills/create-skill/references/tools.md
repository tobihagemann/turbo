# Tool Usage in Skills

How to phrase tool invocations so the executing agent uses the right mechanism with the right parameters.

## Contents

- Dispatching Agent Tool Calls
  - Never Name a Spawned Agent
  - Phrase Multi-Agent Parallel Dispatch Imperatively
  - Hoist Conditional Opt-Out Checks Above Dispatch Logic
  - Skill Tool Calls Don't Parallelize with Agent Calls
  - Keep Parallel Review/Analysis Subagents Read-Only on the Shared Tree
  - Keep Contended Test Tiers From Colliding in the Fan-Out
- Dispatching Bash Tool Calls
- Using AskUserQuestion
  - Output Content as Text Before AskUserQuestion
  - Ask in the Reader's Vocabulary
  - Prefer AskUserQuestion Gates over Anti-Skip Prose Rules
  - AskUserQuestion Doesn't Work in Sub-Agents
- Referencing MCP Tools

## Dispatching Agent Tool Calls

Subagents run in the background and report as they finish. Constrain the message and the wait: emit the calls together, then wait for every agent to report. Keep the parenthetical to parameter values (`model`, and `no name` per Never Name a Spawned Agent below).

A spawn returns immediately, so Agent calls emitted later in the same turn still overlap. One message keeps the fan-out whole.

- ✗ **Avoid**: "Launch all four agents concurrently in a single message."
- ✗ **Avoid**: "Spawn a subagent to review the output."
- ✗ **Avoid**: "Run them in the foreground so all results return in this turn." The Agent schema carries no `run_in_background` in an interactive session, so foreground cannot be requested.
- ✓ **Good**: "Emit all four Agent tool calls in one assistant message. Each Agent call uses `model: "opus"` and no `name`. Wait for every agent to report before continuing. Do not begin the next step on a partial set, and do not relaunch an agent that has not yet reported."

### Never Name a Spawned Agent

Direct every dispatch instruction to omit the `name` parameter. Named and unnamed agents alike return a spawn receipt and report out of band; what naming changes is the payload. An unnamed agent's completion carries its full report. A named agent becomes an addressable teammate, and its completion arrives as an `idle_notification` wrapped in a `<teammate-message>` carrying a truncated summary and status in place of the report.

Because the rule prevents the teammate channel from being used at all, dispatch instructions need no paired recovery text for it. Should a named agent ever idle, read what its summary carries and continue; answering with `SendMessage` only makes a finished agent re-idle without emitting text and invites a nudge loop. Keep that knowledge here rather than repeating it in every skill that spawns.

Do not add file-based delivery fallbacks (having each agent `Write` its report to an agreed path) to work around this. Writing to disk masks the misread channel rather than fixing it, and the spawning agent still burns turns waiting on a report that already arrived.

- ✗ **Avoid**: `Agent(name: "internal-reviewer", ...)` then nudging it when it idles.
- ✓ **Good** (fan-out): "Each Agent call uses `model: "opus"` and no `name`."
- ✓ **Good** (single agent): "Spawn a single subagent (`model: "opus"`, no `name`). Wait for it to report before continuing; do not relaunch it if it has not yet reported."

### Phrase Multi-Agent Parallel Dispatch Imperatively

To fan out N Agents, emit one assistant message containing N Agent tool calls.

Write the dispatch step as one imperative sentence followed by uniform bulleted Agent roles:

> Emit all <N> Agent tool calls below in one assistant message. Each Agent call uses `model: "opus"` and no `name`. Wait for every agent to report before continuing. Do not begin the next step on a partial set, and do not relaunch an agent that has not yet reported.

Constrain the message rather than naming the outcome. "So they run concurrently" states a goal the agent can believe it is meeting while dispatching one call per turn; "emit all <N> Agent tool calls below in one assistant message" names the count and the container, which is checkable against what the message actually contains.

State the total call count as a number, even when a single bullet expands to multiple calls (e.g., "one Agent per active type, expect <N> total"). The number anchors the fan-out so the full set goes out in one batch.

When the items being parallelized are themselves skills, each parallel item is an Agent tool call whose prompt invokes the target skill via the Skill tool. The Agent fan-out parallelizes; the Skill load is the work each Agent does.

### Hoist Conditional Opt-Out Checks Above Dispatch Logic

When a step has a conditional opt-out (e.g., "skip peer review" reduces N+1 to N Agents), put the check at the top of the step before describing the dispatch. If the opt-out subsection appears after the per-Agent subsections, a reader plans the full dispatch and only learns about the opt-out after — easy to ignore at execution time.

- ✗ **Avoid**: Describe Agent A, Agent B, Agent C — then add a final "Skipping C" subsection.
- ✓ **Good**: Open the step with "Determine whether to skip C: if the run was asked to skip, set the dispatch to A+B; otherwise A+B+C." Then describe each Agent.

### Skill Tool Calls Don't Parallelize with Agent Calls

The Skill tool loads instructions and returns immediately — the actual work (Bash calls, agent spawns, etc.) happens in subsequent turns. To truly parallelize a skill's work with other agents, wrap it in an Agent that loads and executes the skill internally.

- ✗ **Avoid**: Launching Agent + Agent + Skill in one message expecting all three to do work concurrently.
- ✓ **Good**: Launching three Agents in one message, each running its respective skill.

### Keep Parallel Review/Analysis Subagents Read-Only on the Shared Tree

When a skill fans out parallel subagents that read the same working tree (reviewers, analyzers, mappers), direct each subagent's prompt to treat the shared working tree and its git index as read-only. Concurrent agents editing files or running git state-changing commands (`add`, `commit`, `checkout`, `restore`, `stash`, `reset`) on the tree they all share race each other and the orchestrator, and a botched restore can corrupt uncommitted work or poison the index.

Name the HEAD constraint in the shipped prompt rather than relying on "read-only" to imply it. A subagent that runs `git checkout` or `git switch` to inspect another ref leaves the working tree and index clean, so a verification checking only `git status` and a diff hash passes while the orchestrator sits on the wrong branch. Direct subagents to read other refs with `git show <ref>:<path>`, and have the orchestrator capture the branch before spawning and re-check it afterward.

Give a sanctioned outlet rather than banning empirical work: a subagent that needs to verify a finding (such as a mutation experiment to confirm a test is non-vacuous) creates an isolated `git worktree` under the hygiene rules below, experiments there, and discards it. Default to reading and reasoning; reach for a worktree only when empirical proof materially raises confidence.

Spell out that hygiene in the same instruction, because a subagent cannot repair what it breaks: the reinstall needs permissions it does not have. Removing a worktree deletes through symlinks, so a subagent that reaches the shared tree's dependency directory from inside its worktree destroys the shared install when it cleans up. Note also that `git status` never lists gitignored paths, so a destroyed install reads as a clean tree; a verification step that checks only git state will miss the damage entirely.

Pair that with a damage-reporting rule. A subagent that breaks shared state it cannot repair reports the damage and the exact repair command in place of findings, so the orchestrator repairs before dispatching more work. Without it, siblings keep running against the broken state and return failures that look like defects in the code under review.

Put the constraint in the per-subagent dispatch instruction, the text that reaches the subagent, not only in the orchestrator's Rules section. An orchestrator-level "does not modify" line governs the orchestrator, not the subagents it launches.

- ✗ **Avoid**: A Rules line "Analysis-only: does not modify source code" with no read-only constraint in the subagent prompts.
- ✗ **Avoid**: "…any empirical check runs in an isolated `git worktree` it discards afterward." This sanctions the worktree without its hygiene, and reads as license to make the worktree runnable by any means.
- ✓ **Good**: "Every agent's prompt directs it to treat the shared working tree and its git index as read-only — any empirical check runs in an isolated `git worktree` created under `$TMPDIR` and discarded afterward. HEAD stays where it is: read other refs with `git show <ref>:<path>` rather than `git checkout` or `git switch`. Give that worktree its own dependency install rather than reaching the shared tree's install by any route: removing a worktree deletes through symlinks, and a redirected suite writes into the shared install. When its own install is not possible, the check is left unrun and reported as such. Afterward the agent verifies that `git worktree list` no longer shows the worktree, that `git status --short` is clean, that HEAD is still on the branch it started on, and that the shared tree's dependency directory still resolves (a destroyed install leaves `git status` clean, since it is gitignored). Damage the agent cannot repair is reported with the exact repair command in place of findings."

### Keep Contended Test Tiers From Colliding in the Fan-Out

Parallel subagents that each run the project's test suite collide whenever a tier depends on a resource outside the tree (a shared database, a fixed port, a cache). Tiers that reset that resource between tests have no cross-process interlock, so concurrent runs wipe each other's state and produce failures that read exactly like defects in the code under review. Contention is a property of the fan-out rather than of any one subagent: a subagent running the tier cannot see that its siblings are running it too, so a per-subagent rule cannot prevent the collision.

Resolve it in the orchestrator step, above the dispatch: have it read the project's test configuration and CI workflow, identify any tier that resets a shared external resource, and name that tier to every subagent as off-limits. Name the artifacts to consult, since an orchestrator that has only a file list cannot recognize a contended tier.

Off-limits works only while the subagents can do their job without the tier. When the scope under examination is what that tier exists to exercise, so that judging it at all requires running the tier, have the orchestrator direct each subagent to provision its own isolated instance of the resource, prepare it through the project's own setup path, run against it, and tear it down afterward. One shared instance carrying an instruction to run a single subagent at a time is not sufficient, for the same reason a per-subagent rule cannot prevent the collision: nothing enforces the ordering across subagents. Give that branch the same terminator as the read-only rules above: when a subagent's own instance cannot be provisioned, the tier is left unrun and reported as such.

Leave the tier unrun rather than having the orchestrator run it after the fan-out. A skill invoked as a child (a review skill running inside an audit, for example) would run it once per invocation, recreating the contention one level down, and an analysis-only skill has no step or output slot for the result.

Where subagents run such a tier, have the orchestrator direct them to redirect the runner's output to a file under `$TMPDIR` and read the file. Piping a runner to `head`, `tail`, or another command that closes the stream early returns while the runner is still going, so a subagent that believes its run finished leaves one live to overlap the next. `$TMPDIR` keeps that file out of the shared tree, which the read-only rules above require the subagent to leave clean.

- ✗ **Avoid**: "Each agent runs the test suite to confirm its findings."
- ✗ **Avoid**: "Name it to every agent as off-limits, and run it once after the fan-out returns." The trailing run fires again in every nested invocation.
- ✗ **Avoid**: "Agents may run the shared tier, one at a time." Nothing carries that ordering across subagents.
- ✓ **Good** (tier not needed): "Before dispatching, read the project's test configuration and CI workflow to identify any test tier that resets a shared external resource between tests, such as a database, a fixed port, or a cache. Such tiers have no cross-process interlock, so agents running them concurrently wipe each other's state and return failures indistinguishable from defects in the change. Name any such tier to every agent as off-limits when the review does not depend on running it."
- ✓ **Good** (fan-out judges that tier): "When the change under review is what that tier exists to exercise, so that judging it at all requires running the tier, direct each agent instead to provision its own isolated instance of the resource, prepare it through the project's own setup path, run against it, and tear it down afterward. One shared instance carrying an instruction to run a single agent at a time is not sufficient, since nothing enforces that across agents. When an agent's own instance cannot be provisioned, the tier is left unrun and reported as such."
- ✓ **Good** (agents run the tier): "Direct every agent that runs a test suite to redirect the runner's output to a file under `$TMPDIR` and read the file."

## Dispatching Bash Tool Calls

When a skill's Bash invocation needs non-default parameters (`timeout`, `dangerouslyDisableSandbox`), specify them in a parenthetical the same way as for Agent calls. Vague phrasing like "use a generous timeout" leaves Claude to guess which timeout (Bash tool parameter vs. shell `timeout` command) and what value.

- ✗ **Avoid**: "Use a generous timeout."
- ✗ **Avoid**: "Wrap the command in a shell `timeout` of 1 hour: `timeout 3600 X`."
- ✓ **Good**: "Run X via the Bash tool (`timeout: 600000`, do not set `run_in_background`)."

The parenthetical names parameters and values directly, parallel to (`model: "opus"`) for Agent calls. The Bash tool stays foreground when `run_in_background` is omitted, so "do not set `run_in_background`" is the correct foreground phrasing for Bash calls (unlike the Agent tool, whose subagents always run in the background — see Dispatching Agent Tool Calls above). The Bash `timeout` maximum (600000 ms) is enforced: a larger value is not honored — the harness backgrounds the call immediately and hard-kills it at 600s, truncating output. Cap at `timeout: 600000`. A command that overruns that window is normally force-backgrounded: the result carries a task ID, and the command runs to completion recoverable from its output file. A skill whose command can overrun should say how to recover it. Rarely the command is hard-killed instead, giving an error exit reading `Command timed out after <duration>` with no task ID and no output file; that signature is a timeout, so never route it into a retry-on-crash rule that would re-run the work from scratch. Reach for a shell wrapper like GNU `timeout` only when the Bash tool's parameter cannot achieve the goal.

## Using AskUserQuestion

When a skill needs user input, reference the tool by name (`AskUserQuestion`) instead of vague phrasing like "ask the user" or "wait for user confirmation." Naming the tool directly ensures the executing Claude instance uses the right mechanism.

- ✗ **Avoid**: "Ask the user which option they prefer."
- ✓ **Good**: "Use `AskUserQuestion` to determine which option the user prefers."

### Output Content as Text Before AskUserQuestion

When a skill presents structured content (tables, plans, reports) before asking for approval, output the content as text first. `AskUserQuestion` has limited UI space and should only carry the approval prompt, not the content being reviewed.

- ✗ **Avoid**: "Present the test plan to the user with `AskUserQuestion` before executing."
- ✗ **Avoid**: "Show the drafted context to the user via `AskUserQuestion` for approval."
- ✓ **Good**: "Output the plan as text. Then use `AskUserQuestion` to ask for approval."

### Ask in the Reader's Vocabulary

A gate question has to be answerable by someone who has not read the skill. Terms the skill defines for its own use — role names, artifact shorthand, phase labels, criteria names — arrive at the gate as jargon, and options whose wording has to be decoded first cannot be weighed against each other.

State the concrete problem in plain language as text before the gate, naming what goes wrong if nothing changes. Then write each option's label and description as an observable effect: what is different afterward, and what that costs.

- ✗ **Avoid**: Options named for the internal criterion or artifact they act on.
- ✓ **Good**: Options named for what is different afterward when the user picks them.

When the user answers with a question instead of picking an option, answer it, then re-ask. Treat the question as evidence about the gate: one asking what a term or an option means says the wording was unreadable, so restate the problem plainly before re-asking. One asking something substantive the options left open says the restatement needs that information too.

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
