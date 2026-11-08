export type ContextLeft = string | null

export type TurnReading = {
  sentAt: number
  model: string
  effort?: string | number
  cacheTotal: number
}

declare module 'claude-code' {
  interface PluginState {
    turbo: { contextLeft: ContextLeft; turnReading: TurnReading | null; cacheTtl: number }
  }
}
