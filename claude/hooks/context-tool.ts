import type { Args, EngineInterface, Frozen } from 'claude-code'

export const CONTEXT_TOOL = 'mcp__turbo__context-level'

export async function registerContextTool($: EngineInterface) {
  await $.tool.register({
    name: 'context-level',
    description: "Reads how much of this session's context window remains.",
  })
}

export async function answerContextLevel($: EngineInterface, e: Frozen<Args<'tool.call'>>) {
  if (e.agentId !== undefined) {
    return {
      result: "No reading for a subagent: this tool reads the main session's context window.",
    }
  }

  const { context } = await $.session.usage()

  if (context.percent === undefined) {
    return { result: 'No reading yet for the current context window.' }
  }

  return { result: `${100 - context.percent}% of the context window remains.` }
}
