import type { Args, EngineInterface, Frozen, TurnCompleteReason } from 'claude-code'
import { handoffPrompt, messageOf, ONE_LINE, submitOrToast, TOAST } from './shared'

export const COMPACT_TOOL = 'mcp__turbo__compact-and-continue'

let pendingHandoff: string | undefined

export async function registerCompactTool($: EngineInterface) {
  await $.tool.register({
    name: 'compact-and-continue',
    description:
      'Compacts the main conversation once this turn ends, then continues from the handoff file. ' +
      'Call it only right before ending a turn at a handoff-then-compact gate.',
    inputSchema: {
      type: 'object',
      properties: { handoff: { type: 'string', description: "The handoff file's path." } },
      required: ['handoff'],
    },
  })
}

export async function queueCompaction(_: EngineInterface, e: Frozen<Args<'tool.call'>>) {
  if (e.agentId !== undefined) {
    return { result: 'No compaction for a subagent: this tool compacts the main session.' }
  }

  const { handoff } = e as { handoff?: unknown }

  if (typeof handoff !== 'string' || !ONE_LINE.test(handoff)) {
    return { result: 'No compaction queued: pass the path of the handoff file you wrote as `handoff`.' }
  }

  pendingHandoff = handoff

  return { result: 'The session compacts and continues from the handoff once this turn ends. End the turn now.' }
}

export async function compactAfterTurn($: EngineInterface, reason: TurnCompleteReason) {
  const handoff = pendingHandoff
  pendingHandoff = undefined

  if (handoff === undefined || reason !== 'answer') {
    return
  }

  try {
    const compacted = await $.session.compact({
      instructions: `Keep the handoff file's path, ${handoff}: the session continues from it after this compaction.`,
    })

    if (compacted.skip !== undefined) {
      $.ui.toast(`${compacted.skip}: compaction skipped. Run /compact, then reply "continue".`, TOAST)

      return
    }
  } catch (error) {
    $.ui.toast(`${messageOf(error)}: compaction failed. Run /compact, then reply "continue".`, TOAST)

    return
  }

  $.clock.after(
    0,
    () =>
      void submitOrToast(
        $,
        handoffPrompt(handoff, 'compacted'),
        `${handoff}: compacted, but the continue prompt was not sent. Reply "continue".`,
      ),
  )
}
