import type { Args, On } from 'claude-code'
import { type Engine, expect, test } from 'claude-code/testing'

const TOOL = 'mcp__turbo__context-level'
const HOME = '/home/user'
const CONFIG = `${HOME}/.turbo/config.json`
const RULES = '# Turbo Rules\n\n## Skill Loading\n\n- Always use the Skill tool.\n'

const usedPercent = (percent?: number) => ({
  value: { startedAt: 0, context: { window: 200000, percent }, rateLimits: [] },
})

type Machine = {
  env?: Record<string, string>
  config?: string | Error
}

const machine = (on: On, { env = { HOME, CLAUDE_CODE_ENABLE_TODO_TOOLS: '1' }, config }: Machine = {}) => {
  const statuses: (string | undefined)[] = []
  const tools: string[] = []

  on('env.get', (_, e) => ({ value: env[e.name] }))
  on('fs.read', (_, e) => {
    if (e.path.endsWith('/ADDITIONS.md')) {
      return { value: RULES }
    }

    if (e.path === CONFIG && typeof config === 'string') {
      return { value: config }
    }

    throw config instanceof Error ? config : new Error(`ENOENT: ${e.path}`)
  })
  on('tool.register', (_, e) => {
    const tool = `mcp__turbo__${e.name}`
    tools.push(tool)

    return { value: { tool } }
  })
  on('ui.status', (_, e) => {
    statuses.push(e.text)

    return { value: undefined }
  })
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('prompt.compose', () => ({ sections: [{ id: 'intro', text: 'engine', scope: 'shared' }] }))
  on('turn.complete', (_, e) => ({ text: e.answer }))
  on('ui.render', { component: 'PromptHint' }, ($, e) => {
    const { Text } = $.ui.resolve(e)

    return <Text>{e.props.tail === undefined ? e.props.hint : `${e.props.hint} ${e.props.tail}`}</Text>
  })

  return { statuses, tools }
}

const promptHint = async ($: Engine) => {
  const ui = await $.ui.mount({
    plugin: 'turbo',
    surface: 'terminal',
    component: 'PromptHint',
    props: { isDraft: false, isWorking: false, hint: '? for shortcuts' },
  })
  const line = await ui.find({ type: 'Text' })
  await ui.unmount()

  return line?.text
}

const start = ($: Engine) =>
  $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })

const compose = async ($: Engine) => {
  const { sections } = await $.prompt.compose({
    model: 'claude-opus-5-5',
    promptModel: 'claude-opus-5-5',
    surfaces: ['terminal'],
    tools: [],
    outputStyle: null,
    traits: [],
  })

  return sections.find(section => section.id === 'turbo:rules')
}

const complete = ($: Engine, agentId?: string) =>
  $.turn.complete({ answer: 'done', durationMs: 1, isAborted: false, turnId: 't1', agentId, reason: 'answer' })

test('registers the context tool at session start', async ($, on) => {
  const { tools } = machine(on)
  await start($)

  expect(tools).toEqual([TOOL])
})

test('reports the remaining percentage', async ($, on) => {
  machine(on)
  on('session.usage', () => usedPercent(79))

  const { result } = await $.tool.call({ tool: TOOL })

  expect(result).toBe('21% of the context window remains.')
})

test('says so when the window has no reading yet', async ($, on) => {
  machine(on)
  on('session.usage', () => usedPercent())

  const { result } = await $.tool.call({ tool: TOOL })

  expect(result).toBe('No reading yet for the current context window.')
})

test('gives a subagent no reading', async ($, on) => {
  machine(on)
  on('session.usage', () => usedPercent(90))

  const { result } = await $.tool.call({ tool: TOOL, agentId: 'a1' })

  expect(result).toBe(
    "No reading for a subagent: this tool reads the main session's context window.",
  )
})

test('appends the Turbo rules as a session section', async ($, on) => {
  machine(on)
  await start($)

  const section = await compose($)

  expect(section?.scope).toBe('session')
  expect(section?.text).toBe(RULES)
})

const spawnedPrompt = async ($: Engine, on: On, spawn: Partial<Args<'agent.spawn'>> = {}) => {
  let prompt: string | undefined

  on('agent.spawn', (_, e) => {
    prompt = e.prompt

    return { model: 'claude-opus-5-5' }
  })
  await $.agent.spawn({ prompt: 'Review the diff.', ...spawn })

  return prompt
}

test('hands the Turbo rules to a spawned subagent', async ($, on) => {
  machine(on)

  expect(await spawnedPrompt($, on)).toBe(`Review the diff.\n\n${RULES}`)
})

const spawnsLeftUnchanged: [string, Partial<Args<'agent.spawn'>>][] = [
  ['a fork', { fork: true }],
  ['a teammate', { isTeammate: true }],
  ['a workflow agent', { workflow: { runId: 'wf_1', agentIndex: 1 } }],
]

for (const [agent, spawn] of spawnsLeftUnchanged) {
  test(`leaves the prompt of ${agent} unchanged`, async ($, on) => {
    machine(on)

    expect(await spawnedPrompt($, on, spawn)).toBe('Review the diff.')
  })
}

test('names the missing task tools setting', async ($, on) => {
  const { statuses } = machine(on, { env: { HOME } })
  await start($)

  expect(statuses).toEqual(['set CLAUDE_CODE_ENABLE_TODO_TOOLS=1 in settings env (see SETUP.md)'])
  expect((await compose($))?.text).toContain('`CLAUDE_CODE_ENABLE_TODO_TOOLS` is not set')
})

test('stays silent when the task tools setting is present', async ($, on) => {
  const { statuses } = machine(on)
  await start($)

  expect(statuses).toEqual([undefined])
  expect((await compose($))?.text).toBe(RULES)
})

test('stays silent when the Turbo config cannot be read', async ($, on) => {
  const { statuses } = machine(on, { config: new Error('EACCES') })
  await start($)

  expect(statuses).toEqual([undefined])
})

test('stays silent when the Turbo config holds no copy install', async ($, on) => {
  const { statuses } = machine(on, { config: JSON.stringify({ oracle: { chatgptUrl: 'https://chatgpt.com/' } }) })
  await start($)

  expect(statuses).toEqual([undefined])
})

test('asks for the migration when the config records a copy install', async ($, on) => {
  const { statuses } = machine(on, { config: JSON.stringify({ claude: { lastUpdateHead: 'abc' } }) })
  await start($)

  expect(statuses).toEqual(['run /update-turbo once to migrate to the plugin'])
  expect((await compose($))?.text).toContain('run `/update-turbo` once')
})

test('asks for the migration when a pre-split config records a copy install', async ($, on) => {
  const { statuses } = machine(on, { config: JSON.stringify({ lastUpdateHead: 'abc' }) })
  await start($)

  expect(statuses).toEqual(['run /update-turbo once to migrate to the plugin'])
})

test('joins every setup problem into one status and one notice section', async ($, on) => {
  const { statuses } = machine(on, { env: { HOME }, config: JSON.stringify({ claude: { lastUpdateHead: 'abc' } }) })
  await start($)

  expect(statuses).toEqual([
    'set CLAUDE_CODE_ENABLE_TODO_TOOLS=1 in settings env (see SETUP.md)' +
      ' · run /update-turbo once to migrate to the plugin',
  ])

  const text = (await compose($))?.text

  expect(text).toContain(`${RULES}\n## Setup Notices\n\n- \`CLAUDE_CODE_ENABLE_TODO_TOOLS\` is not set`)
  expect(text).toContain('\n- An earlier Turbo copy install is still present')
})

test('leaves the prompt hint alone before any reading', async ($, on) => {
  machine(on)

  expect(await promptHint($)).toBe('? for shortcuts')
})

test('shows the context left in the prompt hint after a main-loop turn', async ($, on) => {
  machine(on)
  on('session.usage', () => usedPercent(8))

  await complete($)

  expect(await promptHint($)).toBe('? for shortcuts 92% context left')
})

test('leaves the prompt hint alone after a subagent turn', async ($, on) => {
  machine(on)
  on('session.usage', () => usedPercent(8))

  await complete($, 'a1')

  expect(await promptHint($)).toBe('? for shortcuts')
})

test('leaves the prompt hint alone when the window has no reading', async ($, on) => {
  machine(on)
  on('session.usage', () => usedPercent())

  await complete($)

  expect(await promptHint($)).toBe('? for shortcuts')
})

const SUMMARY = [{ role: 'user' as const, text: 'Summary.', toolUses: [] }]

const showReading = async ($: Engine, on: On, compacted: Awaited<ReturnType<Engine['session']['compact']>> = { messages: SUMMARY }) => {
  machine(on)
  on('session.usage', () => usedPercent(8))
  on('session.compact', () => compacted)
  on('session.end', (_, e) => ({ sessionId: e.sessionId }))

  await complete($)
}

for (const trigger of ['manual', 'auto', 'plugin'] as const) {
  test(`drops the reading once the main conversation compacts (${trigger})`, async ($, on) => {
    await showReading($, on)

    await $.session.compact({ trigger, messages: SUMMARY })

    expect(await promptHint($)).toBe('? for shortcuts')
  })
}

const compactionsThatKeepTheWindow: [string, Args<'session.compact'>][] = [
  ['a subagent compacts', { trigger: 'manual', messages: SUMMARY, agentId: 'a1' }],
  ['a compaction is only precomputed', { trigger: 'precompute', messages: SUMMARY }],
]

for (const [compaction, input] of compactionsThatKeepTheWindow) {
  test(`keeps the reading when ${compaction}`, async ($, on) => {
    await showReading($, on)

    await $.session.compact(input)

    expect(await promptHint($)).toBe('? for shortcuts 92% context left')
  })
}

test('keeps the reading when a compaction is skipped', async ($, on) => {
  await showReading($, on, { skip: 'kept' })

  await $.session.compact({ trigger: 'auto', messages: SUMMARY })

  expect(await promptHint($)).toBe('? for shortcuts 92% context left')
})

for (const reason of ['clear', 'resume'] as const) {
  test(`drops the reading when the conversation is swapped (${reason})`, async ($, on) => {
    await showReading($, on)

    await $.session.end({ reason, sessionId: 's1', resume: { id: 's1' } })

    expect(await promptHint($)).toBe('? for shortcuts')
  })
}

test('keeps the reading when the session ends another way', async ($, on) => {
  await showReading($, on)

  await $.session.end({ reason: 'other', sessionId: 's1', resume: { id: 's1' } })

  expect(await promptHint($)).toBe('? for shortcuts 92% context left')
})
