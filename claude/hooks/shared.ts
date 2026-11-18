import type { EngineInterface } from 'claude-code'

export const TOAST = { timeoutMs: 60_000 }

export const ONE_LINE = /^[^\p{Cc}\p{Cf}\p{Zl}\p{Zp}]+$/u

export function messageOf(error: unknown) {
  return error instanceof Error ? error.message : String(error)
}

export function handoffPrompt(handoff: string, reset: 'compacted' | 'cleared') {
  return (
    `The session was ${reset}. Read the handoff at ${handoff}, ` +
    'then use the TaskList tool and continue with the next step it names.'
  )
}

export async function submitOrToast($: EngineInterface, text: string, notSent: string) {
  try {
    const submitted = await $.prompt.submit({ text })

    if (submitted.drop === undefined) {
      return
    }
  } catch {}

  $.ui.toast(notSent, TOAST)
}
