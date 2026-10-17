---
name: brain
description: Save useful lessons from the current conversation to the knowledge graph at ~/work/brain.
disable-model-invocation: true
---

# Brain

Save anything from this conversation that will still help in a future session.

1. Read the whole conversation, including tool results.
2. Keep only reusable conclusions: how something works, why a choice was made, why an approach failed, the cause of a problem, or a correction to an existing note. Skip play-by-play, temporary details, and facts already clear in code, docs, or git history. If nothing is worth saving, say so and stop.
3. Follow `~/AGENTS.md`. Search before writing, then read the likely home, its nearby notes, and the relevant structure note. Update the existing home when possible; otherwise create and connect a new note. Never edit `human/`.
4. Follow the note, link, and frontmatter rules in `~/AGENTS.md`. Run `orphans` and `unresolved`, and fix any problems you introduced.
5. Briefly list each note you changed and why. Do not commit unless asked.
