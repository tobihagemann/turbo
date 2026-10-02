import { expect, test } from 'claude-code/testing'

const TOOL = 'mcp__context-level__read'

const usedPercent = (percent?: number) => ({
  value: { startedAt: 0, context: { window: 200000, percent }, rateLimits: [] },
})

test('reports the remaining percentage', async ($, on) => {
  on('session.usage', () => usedPercent(79))

  const { result } = await $.tool.call({ tool: TOOL })

  expect(result).toBe('21% of the context window remains.')
})

test('says so when the window has no reading yet', async ($, on) => {
  on('session.usage', () => usedPercent())

  const { result } = await $.tool.call({ tool: TOOL })

  expect(result).toBe('No reading yet for the current context window.')
})

test('gives a subagent no reading', async ($, on) => {
  on('session.usage', () => usedPercent(90))

  const { result } = await $.tool.call({ tool: TOOL, agentId: 'a1' })

  expect(result).toBe(
    "No reading for a subagent: this tool reads the main session's context window.",
  )
})
