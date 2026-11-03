---
paths:
  - "docs/specifications/**"
---

# Specifications

A specification records the technical approach for a ticket: the components, the
technologies, and how they fit the existing system. The ticket holds the intent; the
specification links to it and never restates it.

- **When.** The operator decides at the intake stop whether the ticket needs a specification,
  after the agent states its recommendation. Design runs when the answer
  is yes, and when the operator returns the ticket to Design at the plan gate.
- **Authoring.** The developer and the product owner write it together, with the
  `dev-workflow` skill's Design stage.
- **Name.** `docs/specifications/<ticket key>_<subject>.md` in lowercase, so listing
  `docs/specifications/<ticket key>*` finds it from the ticket.
- **Frontmatter.** `id` (equals the filename stem) and `ticket` (the ticket URL). No status
  field: the commit and the PR record who wrote it, when, and who reviewed it.
- **Sections.** Ticket (link only), Premise, Approach (ending with the acceptance checks the
  approach must satisfy), Risks, Out of scope (design-level exclusions only).
- **Level.** Behavior and components, not file paths, line numbers, task order, or test names;
  those belong in the plan, written against the code as it stands at build time. Name a path
  only when where something lives is the design itself.
- **Review.** A new specification goes through the review cycle, then merges
  alone in a dedicated draft PR, which the operator proofreads, marks ready, and someone on the
  development team reviews. A small edit to a specification (wording, a corrected detail, an
  acceptance check clarified during build) rides in the PR of the ticket that prompted it, and
  that PR body calls the edit out. An edit that changes what will be built (the Premise, the
  chosen approach, or Out of scope) takes its own reviewed PR.
- **Accepted design.** A ticket-keyed specification merged to `main` is accepted design: read it
  wherever the work needs it, never as evidence of how the code works. The pickup review
  re-validates it against the code and later specifications;
  `docs/specifications/CLAUDE.md` has the detail.

Before writing a specification, read the template at
`.claude/skills/dev-workflow/references/specification-template.md`; a filled-in example is
`.claude/skills/dev-workflow/references/specification-example.md`.
