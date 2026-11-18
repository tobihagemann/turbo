import type { Args, EngineInterface, Frozen, TurnCompleteReason } from 'claude-code'
import { handoffPrompt, messageOf, ONE_LINE, submitOrToast, TOAST } from './shared'

export const CLEAR_TOOL = 'mcp__turbo__clear-and-continue'

const IMPLEMENT_COMMAND = 'turbo:implement-plan'

const SLUG = /^[A-Za-z0-9][A-Za-z0-9._-]*$/

type PlanContinuation = { plan: string; worktree: boolean }

type PendingContinuation = PlanContinuation | { handoff: string }

type ContinuationInput = { plan?: unknown; worktree?: unknown; handoff?: unknown }

let pendingContinuation: PendingContinuation | undefined

export async function registerClearTool($: EngineInterface) {
  await $.tool.register({
    name: 'clear-and-continue',
    description:
      'Clears the main conversation once this turn ends, then continues from a ready plan or a handoff file. ' +
      `For a plan, it runs /${IMPLEMENT_COMMAND} on it. ` +
      'For a handoff, it submits a prompt to read the file and continue. ' +
      'Call it only after the user chose to clear the conversation and continue.',
    inputSchema: {
      type: 'object',
      properties: {
        plan: { type: 'string', description: "The plan's slug: its file name under .turbo/plans/, without .md." },
        worktree: { type: 'boolean', description: 'With `plan`: implement the plan in a git worktree of its own.' },
        handoff: { type: 'string', description: "The handoff file's path. Pass it in place of `plan`." },
      },
    },
  })
}

export async function queueContinuation($: EngineInterface, e: Frozen<Args<'tool.call'>>) {
  if (e.agentId !== undefined) {
    return { result: 'No clear for a subagent: this tool clears the main session.' }
  }

  const continuation = await validContinuation($, e as ContinuationInput)

  if (continuation === undefined) {
    return {
      result:
        'Nothing queued: pass either the slug of a plan under .turbo/plans/ as `plan`, with `worktree` if wanted, ' +
        'or the path of an existing handoff file as `handoff`, without `worktree`.',
    }
  }

  pendingContinuation = continuation
  const afterClear = 'plan' in continuation ? `runs /${IMPLEMENT_COMMAND} on the plan` : 'continues from the handoff'

  return {
    result: `The session clears and ${afterClear} once this turn ends. Finish any remaining task, then end the turn.`,
  }
}

async function validContinuation(
  $: EngineInterface,
  { plan, worktree, handoff }: ContinuationInput,
): Promise<PendingContinuation | undefined> {
  if (plan !== undefined && handoff !== undefined) {
    return undefined
  }

  if (typeof plan === 'string' && SLUG.test(plan) && (await $.fs.exists(`.turbo/plans/${plan}.md`))) {
    return { plan, worktree: worktree === true }
  }

  if (typeof handoff === 'string' && ONE_LINE.test(handoff) && worktree !== true && (await $.fs.exists(handoff))) {
    return { handoff }
  }

  return undefined
}

export async function continueAfterTurn($: EngineInterface, reason: TurnCompleteReason) {
  const continuation = pendingContinuation
  pendingContinuation = undefined

  if (continuation === undefined || reason !== 'answer') {
    return
  }

  $.clock.after(0, () =>
    void ('plan' in continuation ? clearThenImplement($, continuation) : clearThenResume($, continuation.handoff)),
  )
}

async function clearThenImplement($: EngineInterface, plan: PlanContinuation) {
  const args = plan.worktree ? `${plan.plan} in a worktree` : plan.plan
  const typed = `/${IMPLEMENT_COMMAND} ${args}`

  if (!(await clearOrToast($, typed))) {
    return
  }

  try {
    await $.command.run({ command: IMPLEMENT_COMMAND, args })
  } catch (error) {
    $.ui.toast(`${messageOf(error)}: cleared, but the plan did not start. Run ${typed}`, TOAST)
  }
}

async function clearThenResume($: EngineInterface, handoff: string) {
  const reply = `reply "Read the handoff at ${handoff} and continue"`

  if (!(await clearOrToast($, reply))) {
    return
  }

  await submitOrToast(
    $,
    handoffPrompt(handoff, 'cleared'),
    `${handoff}: cleared, but the continue prompt was not sent. Reply "Read the handoff at ${handoff} and continue".`,
  )
}

async function clearOrToast($: EngineInterface, next: string) {
  try {
    await $.command.run({ command: 'clear' })

    return true
  } catch (error) {
    $.ui.toast(`${messageOf(error)}: clear failed. Run /clear, then ${next}`, TOAST)

    return false
  }
}
