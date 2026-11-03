---
paths:
  - "docs/**"
---

# Docs layout

`docs/` groups documents by type (tutorials, how-to guides, reference, explanation),
plus decision records, specifications, and plans:

```text
docs/
├── README.md                     index of every doc
├── DESIGN.md                     the project's design document
├── tutorials/
│   └── tutorial_<subject>.md
├── reference/
│   └── reference_<subject>.md
├── decisions/
│   ├── README.md                 index of decision records
│   └── NNNN-<kebab-title>.md
├── specifications/               created with the first specification
│   └── <ticket key>_<subject>.md
└── plans/
    └── <ticket key>_<subject>.md
```

| Path | Holds |
|---|---|
| `DESIGN.md` | The project's design document: the end-to-end anchor for a body of work |
| `tutorials/` | A guided first run for a newcomer |
| `how-to/` | Steps for a task a reader already understands |
| `reference/` | Facts to look up: fields, commands, schemas |
| `explanation/` | Why something is the way it is |
| `decisions/` | Numbered decision records |
| `specifications/` | Technical approach for a ticket; see `specifications.md` in this folder |
| `plans/` | One plan per ticket, as implementation history; see `plans.md` in this folder |

- **Names** are `{type}_{subject}[_{qualifier}].md`, where `type` is the directory's type
  (`tutorial`, `how-to`, `reference`, `explanation`). Names are lowercase, with hyphens inside
  a field and underscores between fields. Names carry no dates; git history carries them.
  `DESIGN.md` is exempt from this naming rule.
- **Frontmatter.** Each typed document starts with frontmatter whose `id` equals the filename
  stem.
- **Type directories** are created only in the change that writes their first document, so a
  missing directory means no document of that type exists yet.
- **Decisions** are numbered `NNNN-kebab-title.md` records listed in `decisions/README.md`. A
  decision record is a dated account of what was decided; a change supersedes a record with a
  new one, never an edit.
- **Specifications and plans** are named `<ticket key>_<subject>.md` in lowercase and are not indexed.

Nothing else lives under `docs/` except `DESIGN.md` and the agent instructions in
`docs/CLAUDE.md` and `docs/specifications/CLAUDE.md`.
