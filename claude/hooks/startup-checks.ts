import type { EngineInterface } from 'claude-code'

const TODO_TOOLS_STATUS = 'set CLAUDE_CODE_ENABLE_TODO_TOOLS=1 in settings env (see SETUP.md)'

const TODO_TOOLS_NOTICE =
  '- `CLAUDE_CODE_ENABLE_TODO_TOOLS` is not set to `1` in this session, so the task tools are missing. Before running a Turbo pipeline, tell the user that its step tracking will not work until they add `"CLAUDE_CODE_ENABLE_TODO_TOOLS": "1"` under `env` in `~/.claude/settings.json` and restart Claude Code.'

const COPY_INSTALL_STATUS = 'run /update-turbo once to migrate to the plugin'

const COPY_INSTALL_NOTICE =
  '- An earlier Turbo copy install is still present on this machine. Tell the user to run `/update-turbo` once to migrate to the plugin, or, when that skill is gone, to have you follow https://github.com/tobihagemann/turbo/blob/main/claude/UPDATE.md; until then, copied skills in `~/.claude/skills` shadow the plugin skills of the same name.'

let notices: readonly string[] = []

export const startupNotices = () => notices

async function hasCopyInstall($: EngineInterface) {
  const config = `${await $.env.get('HOME')}/.turbo/config.json`

  try {
    const parsed = JSON.parse(await $.fs.read(config))

    return parsed?.claude?.lastUpdateHead !== undefined || parsed?.lastUpdateHead !== undefined
  } catch {
    return false
  }
}

export async function runStartupChecks($: EngineInterface) {
  const statuses: string[] = []
  const found: string[] = []

  if ((await $.env.get('CLAUDE_CODE_ENABLE_TODO_TOOLS')) !== '1') {
    statuses.push(TODO_TOOLS_STATUS)
    found.push(TODO_TOOLS_NOTICE)
  }

  if (await hasCopyInstall($)) {
    statuses.push(COPY_INSTALL_STATUS)
    found.push(COPY_INSTALL_NOTICE)
  }

  $.ui.status(statuses.length === 0 ? undefined : statuses.join(' · '))
  notices = found
}
