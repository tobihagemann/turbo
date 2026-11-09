export type ContextLeft = string | null

export type TurnReading = {
  sentAt: number
  model: string
  effort?: string | number
  cacheTotal: number
}

export type OpenItem = { id: string; text: string; detail?: string; resolvedAt?: number }

declare module 'claude-code' {
  interface PluginState {
    turbo: { contextLeft: ContextLeft; turnReading: TurnReading | null; cacheTtl: number; openItems: OpenItem[] }
  }
}
