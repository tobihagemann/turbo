import type { Register } from 'claude-code'
import { answerContextLevel, CONTEXT_TOOL, registerContextTool } from './context-tool'
import { composeRules, shareRulesWithAgent } from './rules'
import { runStartupChecks } from './startup-checks'
import { clearStatusAfterCompact, clearStatusOnSwap, refreshStatus, renderDialogStatus, renderStatus } from './status'

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await registerContextTool($)
    await runStartupChecks($)

    return next(e)
  })

  on('tool.call', { tool: CONTEXT_TOOL }, answerContextLevel)
  on('prompt.compose', composeRules)
  on('agent.spawn', shareRulesWithAgent)
  on('turn.complete', refreshStatus)
  on('session.compact', clearStatusAfterCompact)
  on('session.end', clearStatusOnSwap)
  on('ui.render', { component: 'PromptHint' }, renderStatus)
  on('ui.render', { component: 'AskUserQuestion' }, renderDialogStatus)
}
