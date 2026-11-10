import { atom, read, update } from 'claude-code'
import type { Args, EngineInterface, Frozen, Next, RenderInput } from 'claude-code'
import { clearOpenItems } from './open-items'
import { clearTurnReading, turnParts } from './turn-tracking'

const contextLeft = atom({ plugin: 'turbo', key: 'contextLeft' } as const, null)

const contextText = (percent: number | undefined) =>
  percent === undefined ? undefined : `${100 - percent}% context left`

async function statusText($: EngineInterface, context: string | undefined, isWorking: boolean) {
  const parts = [...(context === undefined ? [] : [context]), ...(await turnParts($, isWorking))]

  return parts.length === 0 ? undefined : parts.join(' · ')
}

export function startCountdownTicker($: EngineInterface) {
  $.clock.every(15_000, () => $.ui.invalidate('ui.render'))
}

export async function refreshStatus($: EngineInterface) {
  const text = contextText((await $.session.usage()).context.percent) ?? null
  await update($, contextLeft, () => text)
}

export async function clearStatusAfterCompact(
  $: EngineInterface,
  e: Frozen<Args<'session.compact'>>,
  next: Next<'session.compact'>,
) {
  const result = await next(e)

  if (e.agentId === undefined && e.trigger !== 'precompute' && result.skip === undefined) {
    await update($, contextLeft, () => null)
    await clearTurnReading($)
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
    await clearTurnReading($)
    await clearOpenItems($)
  }

  return next(e)
}

export async function renderStatus(
  $: EngineInterface,
  e: Frozen<RenderInput<'PromptHint'>>,
  next: Next<'ui.render', RenderInput<'PromptHint'>>,
) {
  const text = await statusText($, (await read($, contextLeft)) ?? undefined, e.props.isWorking)

  return text === undefined ? next(e) : next({ ...e, props: { ...e.props, tail: text } })
}

export async function renderDialogStatus(
  $: EngineInterface,
  e: Frozen<RenderInput<'AskUserQuestion'>>,
  next: Next<'ui.render', RenderInput<'AskUserQuestion'>>,
) {
  const text = await statusText($, contextText((await $.session.usage()).context.percent), false)
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
