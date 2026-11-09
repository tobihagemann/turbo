# Diagrams

The [workflow guide](../docs/workflows.md) diagrams are authored in draw.io (`how-plan-connects.drawio` and `how-finalize-connects.drawio`), each rendered to a sibling `.svg`. Not Mermaid.

## Collaboration Workflow

The user does visual positioning in draw.io (drag and drop); Claude handles XML-level consistency (spacing, sizing, alignment, gap normalization). Visual positioning is what draw.io excels at. Precise numerical consistency (uniform gaps, aligned coordinates, matching sizes) is tedious in the GUI but straightforward via XML edits.

When the user shares a screenshot or says they moved things around, read the `.drawio` file and audit for consistency issues (gaps, sizes, positions, arrow anchors) rather than trying to redesign the layout. The user's spatial arrangement is intentional; Claude's job is to clean up the numbers.

## SVG Export

The draw.io CLI exports SVGs. Use these flags to match the user's preferences:

```bash
/Applications/draw.io.app/Contents/MacOS/draw.io --export --format svg --transparent --embed-svg-fonts false --output <output.svg> <input.drawio>
```

No `--embed-diagram` (no copy of diagram), no `--embed-svg-images` (no embedded images), `--embed-svg-fonts false` (no embedded fonts), `--transparent` (transparent background).

Never hand-edit a draw.io SVG. Even for trivial string replacements, update the `.drawio` source and re-export. The sandbox blocks the Mach port; run with `dangerouslyDisableSandbox: true`.

# Design Rules

All values are multiples of 10 to align with draw.io's 10px grid.

## Overall Layout

Lay each diagram out landscape. GitHub renders a wide diagram at a readable size, while a tall one shrinks to fit the column. `how-finalize-connects.drawio` carries the proportions to aim for.

Put the pipeline the diagram is about at the center and arrange what it connects to around it: some containers to its left, some to its right, some below. `how-plan-connects.drawio` centers `/plan` this way.

## Shapes

- **Pills** (skill references, steps): **150x40**, arcSize=50
- All pills use the same dimensions regardless of text length

## Container Padding

- **Width**: 30px padding on each side (recursive):
  - Pill containers: 30 + 150 + 30 = w:**210**
  - Phase sub-containers: 30 + 150 + 30 = w:**210**
  - /finalize: 30 + 210 + 30 = w:**270**
  - /review-code: 30 + (6x150 + 5x20) + 30 = w:**1060** (parallel layout)
  - /self-improve: **390** (2-column layout with output pills at x=210)
- **Height top padding**: first pill at y=**50** (detail containers) or y=**40** (phase sub-containers)
- **Height bottom padding**: **20**

## Internal Spacing

- First pill y: **50** (detail containers) or **40** (phase sub-containers)
- Vertical gap between pills: **20** (uniform everywhere)
- Pill y positions in detail containers: **50, 110, 170, 230, 290, 350, 410**
- Pill y positions in phase sub-containers: **40, 100, 160, 220**
- Gap between phases inside /finalize: **20**
- Phase y positions inside /finalize: **50, 170, 290, 410**

## Inter-Container Spacing

- Horizontal gap between containers: **80**
- Vertical gap between containers: **60**
- Pill-to-container gap: **50** (from pill center y to connected container's nearest edge)

## IDs

- Before adding new cells or edges, find the highest existing numeric ID in the file and start from the next available number. Duplicate IDs cause draw.io to reject the file.

## Positions

- All container x,y on the **10-grid** (multiples of 10, >= 40)
- Use simple hyphens, not em dashes, in labels

## Arrows

- Cross-container arrows use orthogonal auto-routing. Leave exit/entry anchors off; draw.io strips them whenever an endpoint is dragged, so a layout pass silently undoes them
- Route around any container standing between source and target rather than crossing it. Force the detour with waypoints through an inter-container corridor, since auto-routing alone will cut through
- Leave the waypoints draw.io writes when an edge is hand-routed, including pairs that repeat the same point. They are the tool's own routing state and it regenerates them on the next drag; removing them discards the route and re-runs auto-routing
- After a layout pass, re-check that no arrow crosses a container. Fix a crossing by adding waypoints, not by removing them
- No labels on 1:1 pill-to-container arrows, or on a pill's arrow to the tool it wraps
- Keep labels on non-obvious connections (test failures, stuck after 2 cycles, routing labels)
- Container labels use skill name only (e.g., "/finalize"), no sublabels

## Expansion Rules

When deciding whether a sub-skill gets its own expansion swimlane or stays as a pill inside the parent:

- **Single-call wrappers stay as pills.** A skill whose only job is a single `/codex-exec` invocation should be shown as a pill inside the parent container, with a solid arrow to a sibling `/codex-exec` pill. Do NOT give it a separate expansion container — the expansion would add no information.
- **Multi-step skills get their own container.** Skills with a meaningful internal flow (e.g., `/refine-plan` with review → evaluate → apply → re-run) earn their own swimlane.

When encoding routing decisions (one step branches to multiple paths):

- **Use dashed labeled arrows, not label pills.** From the branching step, draw a dashed arrow to each target pill, with the branch label as the edge value (e.g., `direct`, `plan`, `ship`, `split`). Do NOT insert intermediate label pills — they add a box without a corresponding step.
- Match the style from existing examples: `/finalize`'s Analyze → /ship / /split-and-ship pattern and `/plan`'s Analyze complexity → /discuss-change / /draft-plan pattern both use this convention.

When an arrow crosses a container boundary to invoke another skill:

- **Originate from a named invocation pill, not an unrelated prior step.** If container A calls `/foo` at the end of its flow, add a `/foo` pill as the final step inside A and draw the cross-container arrow from that pill, not from the step that happened to come before the invocation. Example: `/discuss-change`'s final step is an `/implement` pill, not `Confirm shape`; the arrow to the `/implement` container originates from that pill so the semantics match the invocation.

## Colors (Tailwind)

- Plan (green): fill #dcfce7, stroke #22c55e, font #14532d, container fill #f0fdf4
- Review (blue): fill #dbeafe, stroke #3b82f6, font #1e3a5f, container fill #eff6ff
- Debug (orange): fill #ffedd5, stroke #f97316, font #7c2d12, container fill #fff7ed
- Knowledge (purple): fill #f3e8ff, stroke #a855f7, font #581c87, container fill #faf5ff
- Implement (teal): fill #ccfbf1, stroke #14b8a6, font #134e4a, container fill #f0fdfa
- Git (yellow): fill #fef9c3, stroke #eab308, font #713f12, container fill #fefce8
- Finalize: fill #f8fafc, stroke #3b82f6, font #1e3a5f

# Terminal Captures

The [Claude Code mod guide](../docs/claude-code-mod.md) shows the mod as terminal windows (`mod-*.svg`) captured from a real session.

1. Run Claude Code in a scratch project inside a 124-column tmux pane (`tmux new-session -x 124`). Seed the state the shot shows through prompts.
2. Read the pane back with `tmux capture-pane -p -e -N` and cut the frame to the lines the shot shows. For a shot of something transient, such as a spinner or a notice that times out, save a frame every half second while it runs and pick from those.
3. tmux reports a background only on cells that carry text, while the terminal paints a highlighted block, such as a submitted prompt, across its full width on every line. Set that background at the start of each of the block's lines and pad the lines to the pane width.
4. Strip OSC 8 hyperlinks, since they carry absolute paths and session URLs. Drop indicators specific to this machine, such as `← N agents`.
5. Replace `\e[39m` with `\e[38;2;196;196;196m`. freeze ignores the default-foreground reset, and the explicit color keeps the bold and background that a full `\e[0m` reset would end. freeze ignores the default-background reset too, so a highlight such as a selected dialog tab runs on to the end of its line: replace `\e[49m` with the window color, `\e[48;2;23;23;23m`. freeze also ignores reverse video, which marks a focused button, so replace `\e[7m` with an explicit background and foreground.
6. Render the frame with [freeze](https://github.com/charmbracelet/freeze):

   ```bash
   freeze <frame.ansi> --language ansi --window --padding 20,64,20,24 --border.radius 8 --line-height 1.3 --font.family "JetBrains Mono, ui-monospace, SFMono-Regular, Menlo, Consolas, monospace" -o assets/mod-<name>.svg
   ```

   The font stack keeps freeze from embedding a 370 KB font. The wider right padding absorbs fallback fonts that run wider than JetBrains Mono.
7. freeze drops bold, so add `font-weight="bold"` to each `<tspan>` the frame sets bold. Bold starts at `\e[1m` and lasts across color changes until `\e[0m` or `\e[22m`. Strikethrough survives, but freeze puts its `text-decoration` on an empty `<tspan>` ahead of the text, so move it onto the `<tspan>` that follows.
8. freeze flows each line's `<tspan>`s one after another, so a glyph the font lacks, such as `⎿`, falls back to a font of another width and shifts everything after it on the line. Pin each `<tspan>` to its terminal column: give it an `x` of the line's `x` plus its zero-based column times one cell width, 0.6 times the font size.
9. Confirm that `grep -E '/Users/|-Users-|/private/tmp/|file://|claude\.ai/code' assets/mod-*.svg` prints nothing. A Bash call in the shot prints the scratch project's absolute path, which encodes the user name as `-Users-<name>-`, so shorten that path in the frame before rendering.
