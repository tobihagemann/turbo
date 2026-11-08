export type ContextLeft = string | null

declare module 'claude-code' {
  interface PluginState {
    turbo: { contextLeft: ContextLeft }
  }
}
