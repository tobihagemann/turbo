# Turbo Skill Lessons

**When `checkout` is set:** write every lesson routed to a turbo skill into one handoff file at `<checkout>/.turbo/handoff/<YYYY-MM-DD>-turbo-lessons-<slug>.md`, where `<slug>` names the lessons' common subject. When that path already exists, append `-2`, `-3`, and so on to the slug until it is free. State the resolved path before writing. Record for each lesson:

- Which turbo skill it targets, as a path under `codex/skills/<name>/` in the checkout
- The change to make and where in the file it belongs
- The session evidence that motivated it (the correction, failure, or repeated guidance)

**When `checkout` is unset:** use `request_user_input` to ask whether to propose each turbo skill lesson upstream. Ask one question per lesson, at most three per call. Write each lesson the user leaves out to **Auto memory** as Step 6 item 2 writes it, recording the turbo skill it applies to. Treat a lesson whose question could not reach the user the same way. Then, when any lesson remains to propose, run the `$contribute` skill once for all of them, passing each lesson's target skill, change, and evidence.
