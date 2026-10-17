# Rules

- You may consult the knowledge graph before working
- You may integrate what you learn into the knowledge graph
- Keep the subagent harness aligned with the parent harness: Claude Code delegates to headless Claude Code agents, while Pi delegates to native background Pi agents (`runner.type: pi`) through `pi-subagents`
    - Use a different subagent harness only when the user explicitly requests it

## Knowledge graph — `~/work/brain`

A Zettelkasten: focused, reusable engineering ideas joined by explained relationships. One graph, shared
by all agents and sessions.

### Reading
- Orient through a structure note (`index.md`, or the project's), not filenames.
- Find the existing conceptual home before writing anything new.
- Read a note with its neighborhood: links, backlinks, parent structure notes.

### Writing
- One conceptual center per note. Atomic ≠ short.
- Distilled, present-tense claims: what is true, not how you found out.
- Standalone: understandable without the conversation that produced it. No "as discussed".
- Code, docs and git history are the source of truth. Link them, don't copy. Keep only what they can't
  say: the conclusion, the trade-off, the why.
- Mark claims observed, sourced, or inferred.

### Graph
- Fission over ledger: extract an idea to its own note and link it; don't append to a growing note. Two
  conceptual centers means split.
- Name each link's relationship (`refines`, `contradicts`, `alternative-to`) — never a bare "related".
- Surface contradictions rather than overwrite. Supersede by marking the old note, not deleting it.
- Notes are evergreen. Refine and refactor boundaries freely.

### Frontmatter
Every note — this is what makes the graph query-able.

```yaml
---
title: Idempotency keys belong at the API edge # claim-shaped; filename kebab-case, no dates
type: note # note | structure | source | stub | fleeting
status: established # stub | established | superseded
confidence: observed # observed | sourced | inferred
created: 2026-09-18
updated: 2026-09-18
tags: [api-design, reliability] # reuse existing values; resist taxonomy
project: acme-api # omit for cross-project ideas
source: https://... # source notes only
---
```

### Folder structure
```
index.md                root structure note, the entry point
concepts/               cross-project reusable ideas — the core
projects/<project>/     one per project, each with a structure note
sources/                source notes, kept apart from conclusions drawn from them
pr_reviews/<repo>/<pr>/<sha>/review.md
human/                  the user's own notes — read-only for agents
```
`human/` is input, not graph territory: read it, link to it, and draw on it, but never edit, move, rename,
supersede, or fix frontmatter there. It follows the user's conventions, not this doctrine. When a human note
contains an idea worth distilling, write it as a new note elsewhere and link back.
Folders serve retrieval; links carry meaning, so link across them freely. PR reviews are records, not
knowledge: extract reusable ideas into `concepts/` and link back.

### Querying
`brain` is a live Obsidian vault, so graph questions have direct answers — ask before reading files.
The binary ships inside the app and is not on `PATH`; vault-scoped commands need the vault open in
the running app.

```bash
OCLI=/opt/homebrew/bin/obsidian   # grammar: <command> [flag] [key=value]

"$OCLI" search:context query="idempotency key" limit=5  # is there already a conceptual home?
"$OCLI" backlinks file=<note> counts                    # the neighborhood: what points here
"$OCLI" links file=<note>                               # and what this points at
"$OCLI" tags counts sort=count                          # existing vocabulary — reuse before inventing
"$OCLI" properties counts format=tsv                    # frontmatter coverage; a low count is a gap
"$OCLI" property:read name=status file=<note>           # one field, one note
"$OCLI" orphans                                         # no incoming links — connect or mark stub
"$OCLI" unresolved verbose                              # [[links]] with no note yet: the stub queue
"$OCLI" deadends                                        # links nowhere — a note in isolation
```

`vault=brain` disambiguates when several vaults are known. Full surface: `--help` (also `files`,
`read`, `tag`, `bases`, `base:query` for Bases views).
