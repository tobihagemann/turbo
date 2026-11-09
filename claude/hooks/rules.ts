import type { Args, EngineInterface, Frozen, Next } from 'claude-code'
import { OPEN_ITEMS_RULE } from './open-items'
import { startupNotices } from './startup-checks'

let rules: string | undefined

const showsOpenItems = (e: Frozen<Args<'prompt.compose'>>) =>
  !e.traits.includes('teammate') && e.surfaces.some(surface => surface === 'terminal' || surface === 'desktop')

export async function composeRules(
  $: EngineInterface,
  e: Frozen<Args<'prompt.compose'>>,
  next: Next<'prompt.compose'>,
) {
  const { sections } = await next(e)

  rules ??= await $.fs.read(`${$.plugin.root}/ADDITIONS.md`)

  const session = showsOpenItems(e) ? `${rules}${OPEN_ITEMS_RULE}` : rules
  const notices = startupNotices()
  const text = notices.length === 0 ? session : `${session}\n## Setup Notices\n\n${notices.join('\n')}\n`

  return { sections: [...sections, { id: 'turbo:rules', text, scope: 'session' as const }] }
}

export async function shareRulesWithAgent(
  $: EngineInterface,
  e: Frozen<Args<'agent.spawn'>>,
  next: Next<'agent.spawn'>,
) {
  if (e.fork || e.isTeammate || e.resume !== undefined || e.workflow !== undefined) {
    return next(e)
  }

  rules ??= await $.fs.read(`${$.plugin.root}/ADDITIONS.md`)

  return next({ ...e, prompt: `${e.prompt}\n\n${rules}` })
}
