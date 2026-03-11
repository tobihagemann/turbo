---
name: codex
description: This skill should be used when the user asks to "review code with codex", "run codex review", "run codex exec", "execute a task with codex", "use codex to...", "ask codex", "consult codex", "review uncommitted changes", "review against main", "review a commit", "codex review", "codex exec", or wants AI-powered code review or autonomous task execution using the codex CLI.
---

# Codex

AI-powered code review and autonomous task execution via the codex CLI.

- Both modes run non-interactively and are safe to invoke with generous timeouts

## Review Mode

### Uncommitted Changes

```bash
codex review --uncommitted
```

### Against a Base Branch

```bash
codex review --base main
codex review --base develop
```

### Specific Commit

```bash
codex review --commit <sha>
codex review --commit HEAD~1
```

### Custom Prompt (standalone)

Cannot be combined with `--uncommitted`, `--base`, or `--commit`.

```bash
codex review "Focus on security issues and error handling"
```

### Review Options

- Use `--title` to add context when reviewing feature branches or PRs
- Use a generous timeout (30 minutes / 1800000ms)

## Exec Mode

Run autonomous tasks non-interactively. Progress streams to stderr; final result on stdout.

```bash
codex exec "task description"
```

### Permission Levels

| Level | Flag | When to Use |
|-------|------|-------------|
| Read-only (default) | *(none)* | Analysis, code reading, generating reports |
| Workspace write | `--sandbox workspace-write` | Editing files within the project |
| Full access | `--sandbox danger-full-access` | Installing packages, running tests, system operations |
| Full auto | `--full-auto` | Combined with a sandbox level for unattended execution |

### Exec Options

| Option | Description |
|--------|-------------|
| `--full-auto` | Allow file edits without confirmation prompts |
| `--sandbox <level>` | Permission level: `danger-full-access`, `workspace-write` |
| `--json` | JSON Lines output (progress + final message) |
| `-o <path>` | Write final message to a file |
| `--output-schema <path>` | Enforce JSON Schema on the output |
| `--ephemeral` | No persisted session files |
| `--skip-git-repo-check` | Bypass git repository requirement |
| `-m, --model <MODEL>` | Specify the model to use |

### Interpreting Results

- Exec output is a starting point, not a guaranteed solution
- Cross-reference suggestions with project documentation and conventions
- Test incrementally rather than applying all changes at once
- For file-editing tasks, always review the diff before committing
- Use a generous timeout (60 minutes / 3600000ms)
