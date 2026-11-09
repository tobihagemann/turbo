import { atom, read, update } from 'claude-code'
import type { Args, EngineInterface, Frozen, Next, RenderInput } from 'claude-code'
import type { OpenItem } from '../types'
import { ONE_LINE, TOAST } from './compact-tool'

export const OPEN_ITEMS_TOOL = 'mcp__turbo__open-items'
export const RESOLVED_SHOW_MS = 3_000

export const OPEN_ITEMS_RULE = `
## Open Items

- Before ending a turn that leaves something only the user can decide or do, record each item with \`${OPEN_ITEMS_TOOL}\` (\`add\`). Give it a self-contained line as \`text\`. As \`detail\`, give a decision's choices with the recommendation first, or say that only the user can take the action. Still state the items in the reply.
- Do not add an item that is already recorded and still open. Its id is in this conversation's earlier tool results. After a compaction, the \`openItems\` context block holds a snapshot from that compaction. When unsure, \`list\` gives the current set.
- Do not record optional offers ("I could also…") or questions the user settled within the turn. Record a question asked through \`AskUserQuestion\` that is still open after its answer, such as one answered with "later" or with a request for clarification.
- When a user message settles an item, or makes it moot, \`resolve\` it while acting on it. When \`resolve\` refuses the id, call \`list\` and resolve the item it shows for that question, if any. When a \`resolve\` reply names an item other than the one meant, \`add\` the named item back, then look for the meant one in \`list\`.
`

const MAX_TEXT = 200
const MAX_DETAIL = 1_000
const ID_SPACE = 36 ** 4
const RESOLVE_COMMAND = 'turbo:resolve-open-items'

const openItems = atom({ plugin: 'turbo', key: 'openItems' } as const, [])

const isOpen = (item: OpenItem) => item.resolvedAt === undefined

const isExpired = (item: OpenItem, now: number) =>
  item.resolvedAt !== undefined && item.resolvedAt + RESOLVED_SHOW_MS <= now

const unexpired = (items: readonly OpenItem[], now: number) => items.filter(item => !isExpired(item, now))

const drawId = () => Math.floor(Math.random() * ID_SPACE).toString(36).padStart(4, '0')

const freshId = (items: readonly OpenItem[]) => {
  let id = drawId()

  while (items.some(item => item.id === id)) {
    id = drawId()
  }

  return id
}

const listText = (items: readonly OpenItem[]) =>
  items
    .filter(isOpen)
    .map(item => (item.detail === undefined ? `#${item.id} ${item.text}` : `#${item.id} ${item.text}\n  ${item.detail}`))
    .join('\n')

export async function registerOpenItemsTool($: EngineInterface) {
  await $.tool.register({
    name: 'open-items',
    description:
      'Records things only the user can decide or do, for the band above the prompt and for /resolve-open-items. ' +
      '`add` records one, `resolve` settles one by id, `list` shows the open ones.',
    inputSchema: {
      type: 'object',
      properties: {
        action: { type: 'string', enum: ['add', 'resolve', 'list'] },
        text: { type: 'string', description: 'For `add`: the one-line, self-contained question or action.' },
        detail: {
          type: 'string',
          description:
            'For `add`, optional, one line. For a decision, the choices with the recommendation first. ' +
            'For an action, that only the user can do it. Add any context.',
        },
        id: { type: 'string', description: "For `resolve`: the item's id, as `add` or `list` gave it." },
      },
      required: ['action'],
    },
  })
}

export async function answerOpenItems($: EngineInterface, e: Frozen<Args<'tool.call'>>) {
  if (e.agentId !== undefined) {
    return { result: 'No open items for a subagent: the main session records them.' }
  }

  const { action, text, detail, id } = e as { action?: unknown; text?: unknown; detail?: unknown; id?: unknown }

  if (action !== 'add' && action !== 'resolve' && action !== 'list') {
    return { result: 'Nothing done: pass `action` as `add`, `resolve`, or `list`.' }
  }

  if (action === 'list') {
    return { result: listText(await read($, openItems)) || 'No open items.' }
  }

  const now = await $.clock.now()

  if (action === 'add') {
    if (typeof text !== 'string' || text.trim() === '' || !ONE_LINE.test(text) || text.length > MAX_TEXT) {
      return { result: `Nothing recorded: pass \`text\` as one line of at most ${MAX_TEXT} characters.` }
    }

    if (detail !== undefined && (typeof detail !== 'string' || !ONE_LINE.test(detail) || detail.length > MAX_DETAIL)) {
      return { result: `Nothing recorded: pass \`detail\` as one line of at most ${MAX_DETAIL} characters, or leave it out.` }
    }

    let answer = ''

    await update($, openItems, items => {
      const kept = unexpired(items, now)
      const recorded = kept.find(item => isOpen(item) && item.text === text)

      if (recorded !== undefined) {
        answer = `Already recorded as open item #${recorded.id}: ${text}`

        return kept
      }

      const fresh = freshId(kept)
      answer = `Recorded open item #${fresh}: ${text}`

      return [...kept, { id: fresh, text, ...(detail === undefined ? {} : { detail }) }]
    })

    return { result: answer }
  }

  if (typeof id !== 'string') {
    return { result: "Nothing resolved: pass the item's id as `id`." }
  }

  const wanted = id.replace(/^#/, '')
  let resolved: OpenItem | undefined

  await update($, openItems, items => {
    const kept = unexpired(items, now)
    resolved = kept.find(item => item.id === wanted && isOpen(item))

    return kept.map(item => (item === resolved ? { ...item, resolvedAt: now } : item))
  })

  if (resolved === undefined) {
    return { result: `Nothing resolved: #${wanted} is not an open item. \`list\` gives the open ones.` }
  }

  $.clock.after(RESOLVED_SHOW_MS, () => $.ui.invalidate('ui.render'))

  return { result: `Resolved #${resolved.id}: ${resolved.text}` }
}

export async function clearOpenItems($: EngineInterface) {
  await update($, openItems, () => [])
}

export async function addOpenItemsContext(
  $: EngineInterface,
  e: Frozen<Args<'prompt.context'>>,
  next: Next<'prompt.context'>,
) {
  const result = await next(e)
  const list = listText(await read($, openItems))

  if (list === '') {
    return result
  }

  const text =
    'These items waited on the user in the main session as of the last compaction. ' +
    `Only the main session resolves them, through the \`${OPEN_ITEMS_TOOL}\` tool. Its \`list\` action gives the current set.\n\n` +
    list.replaceAll('<', '‹')

  return { ...result, blocks: [...result.blocks, { name: 'openItems', text }] }
}

export async function renderOpenItems(
  $: EngineInterface,
  e: Frozen<RenderInput<'AbovePrompt'>>,
  next: Next<'ui.render'>,
) {
  if (e.props.hasSurvey) {
    return next(e)
  }

  const items = unexpired(await read($, openItems), await $.clock.now())

  if (items.length === 0) {
    return next(e)
  }

  const { Box, Button, Text } = $.ui.resolve(e)

  return (
    <Box flexDirection="column">
      <Box>
        <Text bold>Open items </Text>
        {e.props.isWorking || !items.some(isOpen) ? null : (
          <Button key="resolve" label="Resolve" hotkey="r" onPress={() => runResolve($)} />
        )}
      </Box>
      {items.map(item =>
        isOpen(item) ? (
          <Text key={item.id} wrap="truncate-end">{`☐ ${item.text}`}</Text>
        ) : (
          <Text key={item.id} wrap="truncate-end" dimColor strikethrough>{`✓ ${item.text}`}</Text>
        ),
      )}
    </Box>
  )
}

async function runResolve($: EngineInterface) {
  try {
    await $.command.run({ command: RESOLVE_COMMAND })
  } catch {
    $.ui.toast(`/${RESOLVE_COMMAND} did not start. Run it yourself.`, TOAST)
  }
}
