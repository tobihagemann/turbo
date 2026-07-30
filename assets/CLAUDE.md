# Diagrams

The main README diagrams are authored in draw.io (`how-turboplan-connects.drawio` and `how-finalize-connects.drawio`), each rendered to a sibling `.svg`. Not Mermaid.

## Collaboration Workflow

The user does visual positioning in draw.io (drag and drop); Claude handles XML-level consistency (spacing, sizing, alignment, gap normalization). Visual positioning is what draw.io excels at. Precise numerical consistency (uniform gaps, aligned coordinates, matching sizes) is tedious in the GUI but straightforward via XML edits.

When the user shares a screenshot or says they moved things around, read the `.drawio` file and audit for consistency issues (gaps, sizes, positions, arrow anchors) rather than trying to redesign the layout. The user's spatial arrangement is intentional; Claude's job is to clean up the numbers.

## SVG Export

The draw.io CLI exports SVGs. Use these flags to match the user's preferences:

```bash
/Applications/draw.io.app/Contents/MacOS/draw.io --export --format svg --transparent --embed-svg-fonts false --output <output.svg> <input.drawio>
```

No `--embed-diagram` (no copy of diagram), no `--embed-svg-images` (no embedded images), `--embed-svg-fonts false` (no embedded fonts), `--transparent` (transparent background).

Never hand-edit the SVG. Even for trivial string replacements, update the `.drawio` source and re-export. The sandbox blocks the Mach port; run with `dangerouslyDisableSandbox: true`.

# Design Rules

All values are multiples of 10 to align with draw.io's 10px grid.

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

- Exit toward target: exitX=0 (left) or exitX=1 (right)
- Enter from source direction: entryY=0 (top) or entryY=1 (bottom)
- No labels on 1:1 pill-to-container arrows or /peer-review → /codex
- Keep labels on non-obvious connections (test failures, stuck after 2 cycles, routing labels)
- Container labels use skill name only (e.g., "/finalize"), no sublabels

## Expansion Rules

When deciding whether a sub-skill gets its own expansion swimlane or stays as a pill inside the parent:

- **Single-call wrappers stay as pills.** A skill whose only job is a single `/codex-exec` invocation (e.g., `/peer-draft-plan`) should be shown as a pill inside the parent container, with a solid arrow to a sibling `/codex-exec` pill. Do NOT give it a separate expansion container — the expansion would add no information.
- **Multi-step skills get their own container.** Skills with a meaningful internal flow (e.g., `/refine-plan` with review → evaluate → apply → re-run) earn their own swimlane.

When encoding routing decisions (one step branches to multiple paths):

- **Use dashed labeled arrows, not label pills.** From the branching step, draw a dashed arrow to each target pill, with the branch label as the edge value (e.g., `small-task / shell`, `complex`, `ship`, `split`). Do NOT insert intermediate label pills — they add a box without a corresponding step.
- Match the style from existing examples: `/finalize`'s Analyze → /ship / /split-and-ship pattern and `/turboplan`'s Analyze complexity → /draft-plan / /create-spec pattern both use this convention.

When an arrow crosses a container boundary to invoke another skill:

- **Originate from a named invocation pill, not an unrelated prior step.** If container A calls `/foo` at the end of its flow, add a `/foo` pill as the final step inside A and draw the cross-container arrow from that pill, not from the step that happened to come before the invocation. Example: `/pick-next-prompt`'s final step is a `/turboplan` pill, not `Mark in-progress`; the loopback arrow to `/turboplan` originates from the `/turboplan` pill so the semantics match the label ("shell mode").

## Colors (Tailwind)

- Plan (green): fill #dcfce7, stroke #22c55e, font #14532d, container fill #f0fdf4
- Review (blue): fill #dbeafe, stroke #3b82f6, font #1e3a5f, container fill #eff6ff
- Debug (orange): fill #ffedd5, stroke #f97316, font #7c2d12, container fill #fff7ed
- Knowledge (purple): fill #f3e8ff, stroke #a855f7, font #581c87, container fill #faf5ff
- Implement (teal): fill #ccfbf1, stroke #14b8a6, font #134e4a, container fill #f0fdfa
- Git (yellow): fill #fef9c3, stroke #eab308, font #713f12, container fill #fefce8
- Finalize: fill #f8fafc, stroke #3b82f6, font #1e3a5f
