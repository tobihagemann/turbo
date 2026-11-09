import type { Register } from 'claude-code'
import { compactAfterTurn, COMPACT_TOOL, queueCompaction, registerCompactTool } from './compact-tool'
import { answerContextLevel, CONTEXT_TOOL, registerContextTool } from './context-tool'
import { addOpenItemsContext, answerOpenItems, OPEN_ITEMS_TOOL, registerOpenItemsTool, renderOpenItems } from './open-items'
import { composeRules, shareRulesWithAgent } from './rules'
import { runStartupChecks } from './startup-checks'
import {
  clearStatusAfterCompact,
  clearStatusOnSwap,
  refreshStatus,
  renderDialogStatus,
  renderStatus,
  startCountdownTicker,
} from './status'
import { trackTurnStep } from './turn-tracking'

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await registerContextTool($)
    await registerCompactTool($)
    await registerOpenItemsTool($)
    await runStartupChecks($)
    startCountdownTicker($)

    return next(e)
  })

  on('tool.call', { tool: CONTEXT_TOOL }, answerContextLevel)
  on('tool.call', { tool: COMPACT_TOOL }, queueCompaction)
  on('tool.call', { tool: OPEN_ITEMS_TOOL }, answerOpenItems)
  on('prompt.compose', composeRules)
  on('prompt.context', addOpenItemsContext)
  on('agent.spawn', shareRulesWithAgent)
  on('turn.step', async function* ($, e, next) {
    if (e.agentId !== undefined) {
      return yield* next(e)
    }

    const result = yield* trackTurnStep($, e, next)
    await refreshStatus($)

    return result
  })
  on('turn.complete', async ($, e, next) => {
    const result = await next(e)

    if (e.agentId === undefined) {
      await refreshStatus($)
      await compactAfterTurn($, e.reason)
    }

    return result
  })
  on('session.compact', clearStatusAfterCompact)
  on('session.end', clearStatusOnSwap)
  on('ui.render', { component: 'PromptHint' }, renderStatus)
  on('ui.render', { component: 'AskUserQuestion' }, renderDialogStatus)
  on('ui.render', { component: 'AbovePrompt' }, renderOpenItems)
}
