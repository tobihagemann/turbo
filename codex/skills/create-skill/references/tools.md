# Tool Usage in Skills

How to phrase tool invocations so the executing agent uses the right mechanism with the right parameters.

## Contents

- Dispatching Sub-Agent Calls
  - Phrase Multi-Agent Parallel Dispatch Imperatively
  - Hoist Conditional Opt-Out Checks Above Dispatch Logic
  - Skill Mentions Don't Fan Out on Their Own
  - Keep Parallel Review/Analysis Sub-Agents Read-Only on the Shared Tree
  - Keep Contended Test Tiers Out of the Fan-Out
- Using request_user_input
  - Output Content as Text Before request_user_input
  - Gate Genuine Blockers; Leave the Agent's Own Judgment to the Agent
  - request_user_input Is Gated to Interactive Modes and the Main Conversation
- Referencing MCP Tools

## Dispatching Sub-Agent Calls

When a skill spawns sub-agents, use `spawn_agent` to launch each branch and `wait_agent` to join. Sub-agents inherit the parent model unless the user has explicitly requested otherwise — do not hardcode model names. Vague phrasing like "launch concurrently" or "in parallel" causes flaky behavior because the agent has to guess which tool to use.

`spawn_agent` issues each sub-agent in its own call; the calls in a batch run concurrently up to `agents.max_threads` (default 6). Sub-agents cannot themselves call `spawn_agent` under the default `agents.max_depth` of 1, so a sub-agent must complete its work without further fan-out.

- ✗ **Avoid**: "Launch all four agents concurrently."
- ✗ **Avoid**: "Spawn a sub-agent to review the output."
- ✓ **Good**: "Issue four `spawn_agent` calls (one per role described below), then join with `wait_agent`."

### Phrase Multi-Agent Parallel Dispatch Imperatively

To fan out N sub-agents in parallel, issue N `spawn_agent` calls in one batch and then join them with `wait_agent`.

Write the dispatch step as one imperative sentence followed by uniform bulleted sub-agent roles:

> Issue all <N> `spawn_agent` calls below in one batch so they run concurrently, then collect their results with `wait_agent`. Each sub-agent inherits the parent model.

State the total call count as a number, even when a single bullet expands to multiple calls (e.g., "one sub-agent per active type, expect <N> total"). The number anchors the fan-out so the full set goes out in one batch.

When the items being parallelized are themselves skills, each parallel item is a `spawn_agent` call whose prompt instructs the sub-agent to read and follow the target `$skill-name`. The `spawn_agent` fan-out parallelizes; the skill load is the work each sub-agent does.

### Hoist Conditional Opt-Out Checks Above Dispatch Logic

When a step has a conditional opt-out (e.g., "skip peer review" reduces N+1 to N sub-agents), put the check at the top of the step before describing the dispatch. If the opt-out subsection appears after the per-role subsections, a reader plans the full dispatch and only learns about the opt-out after — easy to ignore at execution time.

- ✗ **Avoid**: Describe sub-agent A, sub-agent B, sub-agent C — then add a final "Skipping C" subsection.
- ✓ **Good**: Open the step with "Determine whether to skip C: if the run was asked to skip, set the dispatch to A+B; otherwise A+B+C." Then describe each sub-agent.

### Skill Mentions Don't Fan Out on Their Own

Mentioning `$skill-name` injects the skill's SKILL.md as a contextual fragment for the current turn; it does not spawn a sub-agent. The actual work happens afterward, in the same conversation. To run several skills' work in parallel, wrap each branch in a `spawn_agent` call whose prompt tells the sub-agent to read and follow the target skill.

- ✗ **Avoid**: Mentioning `$skill-A` and `$skill-B` in the same step expecting the mentions themselves to spawn sub-agents.
- ✓ **Good**: Issuing two `spawn_agent` calls, each instructing its sub-agent to read and follow its respective skill.

### Keep Parallel Review/Analysis Sub-Agents Read-Only on the Shared Tree

When a skill fans out parallel sub-agents that read the same working tree (reviewers, analyzers, mappers), direct each sub-agent's prompt to treat the shared working tree and its git index as read-only. Concurrent sub-agents editing files or running git state-changing commands (`add`, `commit`, `checkout`, `restore`, `stash`, `reset`) on the tree they all share race each other and the orchestrator, and a botched restore can corrupt uncommitted work or poison the index.

Give a sanctioned outlet rather than banning empirical work: a sub-agent that needs to verify a finding (such as a mutation experiment to confirm a test is non-vacuous) creates an isolated `git worktree` under the hygiene rules below, experiments there, and discards it. Default to reading and reasoning; reach for a worktree only when empirical proof materially raises confidence.

Spell out that hygiene in the same instruction, because a sub-agent cannot repair what it breaks: the reinstall needs permissions it does not have. Removing a worktree deletes through symlinks, so a sub-agent that reaches the shared tree's dependency directory from inside its worktree destroys the shared install when it cleans up. Note also that `git status` never lists gitignored paths, so a destroyed install reads as a clean tree; a verification step that checks only git state will miss the damage entirely.

Pair that with a damage-reporting rule. A sub-agent that breaks shared state it cannot repair reports the damage and the exact repair command in place of findings, so the orchestrator repairs before dispatching more work. Without it, siblings keep running against the broken state and return failures that look like defects in the code under review.

Put the constraint in the per-sub-agent dispatch instruction, the text that reaches the sub-agent, not only in the orchestrator's Rules section. An orchestrator-level "does not modify" line governs the orchestrator, not the sub-agents it launches.

- ✗ **Avoid**: A Rules line "Analysis-only: does not modify source code" with no read-only constraint in the sub-agent prompts.
- ✗ **Avoid**: "…any empirical check runs in an isolated `git worktree` it discards afterward." This sanctions the worktree without its hygiene, and reads as license to make the worktree runnable by any means.
- ✓ **Good**: "Each sub-agent's prompt directs it to treat the shared working tree and its git index as read-only — any empirical check runs in an isolated `git worktree` created under `$TMPDIR` and discarded afterward. Give that worktree its own dependency install rather than reaching the shared tree's install by any route: removing a worktree deletes through symlinks, and a redirected suite writes into the shared install. When its own install is not possible, the check is left unrun and reported as such. Afterward the sub-agent verifies that `git worktree list` no longer shows the worktree, that `git status --short` is clean, and that the shared tree's dependency directory still resolves (a destroyed install leaves `git status` clean, since it is gitignored). Damage the sub-agent cannot repair is reported with the exact repair command in place of findings."

### Keep Contended Test Tiers Out of the Fan-Out

Parallel sub-agents that each run the project's test suite collide whenever a tier depends on a resource outside the tree (a shared database, a fixed port, a cache). Tiers that reset that resource between tests have no cross-process interlock, so concurrent runs wipe each other's state and produce failures that read exactly like defects in the code under review. Contention is a property of the fan-out rather than of any one sub-agent: a sub-agent running the tier cannot see that its siblings are running it too, so a per-sub-agent rule cannot prevent the collision.

Resolve it in the orchestrator step, above the dispatch: have it read the project's test configuration and CI workflow, identify any tier that resets a shared external resource, and name that tier to every sub-agent as off-limits. Name the artifacts to consult, since an orchestrator that has only a file list cannot recognize a contended tier.

Leave the tier unrun rather than having the orchestrator run it after the branches join. A skill invoked as a child (a review skill running inside an audit, for example) would run it once per invocation, recreating the contention one level down, and an analysis-only skill has no step or output slot for the result.

- ✗ **Avoid**: "Each sub-agent runs the test suite to confirm its findings."
- ✗ **Avoid**: "Name it to every sub-agent as off-limits, and run it once after the fan-out returns." The trailing run fires again in every nested invocation.
- ✓ **Good**: "Before dispatching, read the project's test configuration and CI workflow to identify any test tier that resets a shared external resource between tests, such as a database, a fixed port, or a cache. Such tiers have no cross-process interlock, so sub-agents running them concurrently wipe each other's state and return failures indistinguishable from defects in the change. Name any such tier to every sub-agent as off-limits."

## Using request_user_input

When a skill needs structured user input, reference the tool by name (`request_user_input`) instead of vague phrasing like "ask the user" or "wait for user confirmation." Naming the tool directly avoids ambiguity about how the question should be surfaced.

- ✗ **Avoid**: "Ask the user which option they prefer."
- ✓ **Good**: "Use `request_user_input` to determine which option the user prefers."

### Output Content as Text Before request_user_input

When a skill presents structured content (tables, plans, reports) before asking for approval, output the content as text first. `request_user_input` has limited UI space and should only carry the approval prompt, not the content being reviewed.

- ✗ **Avoid**: "Present the test plan to the user with `request_user_input` before executing."
- ✗ **Avoid**: "Show the drafted context to the user via `request_user_input` for approval."
- ✓ **Good**: "Output the plan as text. Then use `request_user_input` to ask for approval."

### Gate Genuine Blockers; Leave the Agent's Own Judgment to the Agent

Reserve `request_user_input` for decisions that genuinely need the user. When the agent can make the call itself, let it act and state its reasoning rather than gating.

- **Blocker gate**: When a step is blocked by a missing dependency, unclear requirement, or environmental issue that needs user input to resolve, use `request_user_input` to surface the blocker and let the user choose how to proceed. Phrasing like "halt and report" or "stop" leaves no recovery path; a `request_user_input` gate keeps the workflow live.
- **Skip decision**: When the agent judges a re-run unnecessary (changes were made but re-running would surface nothing new), let it stop on its own judgment. Require it to output what changed and its reasoning for stopping so the decision stays auditable, but do not gate on the user.

```markdown
**If changes were made**, run the `$this-skill` skill again.

**If changes were made but you judge a re-run unnecessary**, output a summary of what changed and your reasoning for stopping, then stop instead of re-running.
```

Self-looping skills terminate on their own convergence signal (a run that makes no changes, or a round of only cosmetic edits). Rely on that rather than an iteration cap. Judge the signal by the trend across rounds: once rounds stop surfacing defects and keep surfacing improvements of kinds earlier rounds already applied, the loop has converged even when the edits were structural. Give the loop a durable anchor: record iteration number and applied/rejected verdicts in a ledger under `.turbo/loops/`, and anchor uncapped loops with a goal whose objective names the ledger path, so compaction cannot erase the loop's memory of its own decisions.

### request_user_input Is Gated to Interactive Modes and the Main Conversation

`request_user_input` only reaches the user from interactive sessions. Two limits apply:

- **Mode gating** — the tool is available in Plan mode by default. Default mode requires the `default_mode_request_user_input` feature flag (currently off). Non-interactive sessions (e.g., `codex exec`) drop the tool entirely.
- **Sub-agent gating** — when a skill runs inside a `spawn_agent` sub-agent, `request_user_input` cannot reach the user. The parent agent owns the conversation; the sub-agent's questions either error or get dropped silently.

Skills that commonly run as sub-agents (invoked by workflow skills that fan out via `spawn_agent`) or that may run under `codex exec` need deterministic fallbacks instead of interactive questions.

- **Missing input** — stop and state what could not be resolved. The parent agent reads the sub-agent's output and can relay or act on it.
- **Disambiguation** — pick a deterministic default (e.g., most recently modified file) rather than asking which option to use.
- **Main-context-only fallbacks** — a skill could in principle branch on whether `request_user_input` is currently available, but the cost of that branching is usually worse than just removing the question entirely.

## Referencing MCP Tools

Codex exposes MCP (Model Context Protocol) tools through `tool_search`. Callable names use the namespaced form `mcp__<server>__<tool>` (double underscores). When a skill must reference a *specific known* MCP tool, write the fully qualified callable name so the agent doesn't need to disambiguate.

**Format**: `mcp__<server>__<tool>`

Without the namespace prefix, the agent may fail to locate the tool, especially when multiple MCP servers are available.

When a skill needs a *category* of tool rather than a specific one (e.g., documentation lookup), reference the category generically. Different projects have different MCP servers installed.

- ✗ **Avoid**: "Use the context7 MCP to look up library docs."
- ✓ **Good**: "Use a documentation MCP tool or web search to look up library docs."
