import type { Register } from 'claude-code'

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.tool.register({
      name: 'read',
      description: "Reads how much of this session's context window remains.",
    })

    return next(e)
  })

  on('tool.call', { tool: 'mcp__context-level__read' }, async ($, e) => {
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
  })
}
