import { atom, read, update } from 'claude-code'
import type { Args, EngineInterface, Frozen, Next, RenderInput } from 'claude-code'

const contextLeft = atom({ plugin: 'turbo', key: 'contextLeft' } as const, null)

const statusText = (percent: number | undefined) =>
  percent === undefined ? undefined : `${100 - percent}% context left`

export async function refreshStatus(
  $: EngineInterface,
  e: Frozen<Args<'turn.complete'>>,
  next: Next<'turn.complete'>,
) {
  const result = await next(e)

  if (e.agentId === undefined) {
    const text = statusText((await $.session.usage()).context.percent) ?? null
    await update($, contextLeft, () => text)
  }

  return result
}

export async function clearStatusAfterCompact(
  $: EngineInterface,
  e: Frozen<Args<'session.compact'>>,
  next: Next<'session.compact'>,
) {
  const result = await next(e)

  if (e.agentId === undefined && e.trigger !== 'precompute' && result.skip === undefined) {
    await update($, contextLeft, () => null)
  }

  return result
}

export async function clearStatusOnSwap(
  $: EngineInterface,
  e: Frozen<Args<'session.end'>>,
  next: Next<'session.end'>,
) {
  if (e.reason === 'clear' || e.reason === 'resume') {
    await update($, contextLeft, () => null)
  }

  return next(e)
}

export async function renderStatus(
  $: EngineInterface,
  e: Frozen<RenderInput<'PromptHint'>>,
  next: Next<'ui.render'>,
) {
  const text = await read($, contextLeft)

  return text === null ? next(e) : next({ ...e, props: { ...e.props, tail: text } })
}

export async function renderDialogStatus(
  $: EngineInterface,
  e: Frozen<RenderInput<'AskUserQuestion'>>,
  next: Next<'ui.render'>,
) {
  const text = statusText((await $.session.usage()).context.percent)
  const dialog = await next(e)

  if (text === undefined) {
    return dialog
  }

  const { Box, Text } = $.ui.resolve(e)

  return (
    <Box flexDirection="column">
      <Text dimColor>{text}</Text>
      {dialog}
    </Box>
  )
}
