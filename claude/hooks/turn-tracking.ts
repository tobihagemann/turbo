import { atom, read, update } from 'claude-code'
import type { Args, EngineInterface, Frozen, StreamNext } from 'claude-code'
import type { TurnReading } from '../types'

const MINUTE = 60_000
const HOUR = 60 * MINUTE

const turnReading = atom({ plugin: 'turbo', key: 'turnReading' } as const, null)
const cacheTtl = atom({ plugin: 'turbo', key: 'cacheTtl' } as const, HOUR)

const MODEL_ID = /^claude-([a-z]+)-(\d+)-(\d{1,2})(?=$|[-[])/

const modelLabel = (model: string) => {
  const match = MODEL_ID.exec(model)

  if (match === null) {
    return model
  }

  const [, family = '', major, minor] = match

  return `${family.charAt(0).toUpperCase()}${family.slice(1)} ${major}.${minor}`
}

const cacheText = (sentAt: number, ttl: number, now: number) => {
  const left = sentAt + ttl - now

  return left <= 0 ? 'cache expired' : `cache expires in ${Math.ceil(left / MINUTE)} min`
}

export async function turnParts($: EngineInterface, isWorking: boolean) {
  const turn = await read($, turnReading)

  if (turn === null) {
    return []
  }

  const model = modelLabel(turn.model)
  const label = turn.effort === undefined ? model : `${model} (${turn.effort})`

  if (isWorking) {
    return [label]
  }

  return [cacheText(turn.sentAt, await read($, cacheTtl), await $.clock.now()), label]
}

export async function clearTurnReading($: EngineInterface) {
  await update($, turnReading, () => null)
}

const learnedTtl = (previous: TurnReading | null, step: TurnReading, cacheRead: number) => {
  if (previous === null || step.model !== previous.model || step.effort !== previous.effort) {
    return undefined
  }

  const gap = step.sentAt - previous.sentAt

  if (gap <= 6 * MINUTE || gap >= 55 * MINUTE) {
    return undefined
  }

  return cacheRead < 0.9 * previous.cacheTotal ? 5 * MINUTE : HOUR
}

export async function* trackTurnStep($: EngineInterface, e: Frozen<Args<'turn.step'>>, next: StreamNext<'turn.step'>) {
  const sentAt = await $.clock.now()
  const result = yield* next(e)
  const { usage } = result

  if (usage !== null) {
    const step: TurnReading = {
      sentAt,
      model: usage.model,
      effort: e.effort,
      cacheTotal: usage.cache_read_input_tokens + usage.cache_creation_input_tokens,
    }
    const ttl = e.index === 0 ? learnedTtl(await read($, turnReading), step, usage.cache_read_input_tokens) : undefined

    if (ttl !== undefined) {
      await update($, cacheTtl, () => ttl)
    }

    await update($, turnReading, () => step)
  }

  return result
}
