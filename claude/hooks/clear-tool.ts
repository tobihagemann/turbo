import type { Args, EngineInterface, Frozen, TurnCompleteReason } from 'claude-code'
import { TOAST } from './compact-tool'

export const CLEAR_TOOL = 'mcp__turbo__clear-and-implement'

const IMPLEMENT_COMMAND = 'turbo:implement-plan'

const SLUG = /^[A-Za-z0-9][A-Za-z0-9._-]*$/

type PendingImplementation = { slug: string; worktree: boolean }

let pendingImplementation: PendingImplementation | undefined

export async function registerClearTool($: EngineInterface) {
  await $.tool.register({
    name: 'clear-and-implement',
    description:
      `Clears the main conversation once this turn ends, then runs /${IMPLEMENT_COMMAND} on the plan. ` +
      'Call it only after the user chose to clear the conversation and implement a ready plan.',
    inputSchema: {
      type: 'object',
      properties: {
        plan: { type: 'string', description: "The plan's slug: its file name under .turbo/plans/, without .md." },
        worktree: { type: 'boolean', description: 'Implement the plan in a git worktree of its own.' },
      },
      required: ['plan'],
    },
  })
}

export async function queueImplementation($: EngineInterface, e: Frozen<Args<'tool.call'>>) {
  if (e.agentId !== undefined) {
    return { result: 'No clear for a subagent: this tool clears the main session.' }
  }

  const { plan, worktree } = e as { plan?: unknown; worktree?: unknown }
  const refused = { result: 'Nothing queued: pass the slug of a plan under .turbo/plans/ as `plan`.' }

  if (typeof plan !== 'string' || !SLUG.test(plan)) {
    return refused
  }

  if (!(await $.fs.exists(`.turbo/plans/${plan}.md`))) {
    return refused
  }

  pendingImplementation = { slug: plan, worktree: worktree === true }

  return {
    result:
      `The session clears and runs /${IMPLEMENT_COMMAND} on the plan once this turn ends. ` +
      'Finish any remaining task, then end the turn.',
  }
}

export async function implementAfterTurn($: EngineInterface, reason: TurnCompleteReason) {
  const implementation = pendingImplementation
  pendingImplementation = undefined

  if (implementation === undefined || reason !== 'answer') {
    return
  }

  $.clock.after(0, () => void clearThenImplement($, implementation))
}

async function clearThenImplement($: EngineInterface, { slug, worktree }: PendingImplementation) {
  const args = worktree ? `${slug} in a worktree` : slug
  const typed = `/${IMPLEMENT_COMMAND} ${args}`

  try {
    await $.command.run({ command: 'clear' })
  } catch (error) {
    $.ui.toast(`${messageOf(error)}: clear failed. Run /clear, then ${typed}`, TOAST)

    return
  }

  try {
    await $.command.run({ command: IMPLEMENT_COMMAND, args })
  } catch (error) {
    $.ui.toast(`${messageOf(error)}: cleared, but the plan did not start. Run ${typed}`, TOAST)
  }
}

function messageOf(error: unknown) {
  return error instanceof Error ? error.message : String(error)
}
