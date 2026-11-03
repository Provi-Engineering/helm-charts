# docs/specifications/

Agent instructions for specifications.

## 1. What specs are and where they live

- A spec is `docs/specifications/<ticket key>_<subject>.md`, one per ticket. The specifications
  rule (`.claude/rules/documentation/specifications.md`) sets its form.
- Acceptance checks are provable statements. Each is true or false for one stated starting
  state and one observable result, with one assertion per check; a check with "and" is two
  checks. "The hook stops after three holds" is a summary; "a red Stop event with two recorded
  holds returns `continue: false`" is a check.
- A spec can be one slice of a larger design intent that lives in its Jira ticket, with sibling
  specs for the other slices.
- Older specs may predate the specifications rule and not follow its template.
- A spec's own status text, such as a `### Status` section, may be stale. Do not trust it, and do
  not follow its next steps.
- Some specs describe built work and may be out of date; some describe future work. Never use a
  spec as evidence of how the code works: read the code.
- Plans (`docs/plans/`) and decision records (`docs/decisions/`) are separate documents with
  their own rules.

## 2. Rule: a keyed specification on `main` is accepted design

- A spec named `<ticket key>_<subject>.md` that has merged to `main` is accepted design (the
  ticket carries the intent). Read it wherever the work needs it, without asking. This file is
  not a spec.
- An unkeyed file in this directory is not accepted design: do not plan from it or rate a
  ticket against it.
- A spec is evidence of the design, never of how the code works: read the code. Its status text
  may be stale, so do not follow its next steps.
- The pickup review re-validates a spec before work resumes from it: the `intent-reviewer` agent
  checks its premises against the checkout, `docs/DESIGN.md`, and the specs accepted after it. A conflict stops the work for the operator.

## 3. How specs are used

- Specs on `main` can be unfinished or out of date. The pickup review runs when Design resumes on
  an unmerged spec, when Build starts from a merged one, and when a parked Build resumes after
  a spec edit.
- Future specs help an agent judge the scope of the current work. Completed, out-of-date specs
  mislead it, which is why a spec never stands in for the code.
- Specs get tweaked during the work. Section 5 covers how.
- Ticket work starts with `/dev-workflow <KEY>` (the root `CLAUDE.md`).
  Design runs when the operator says at the intake stop that the ticket needs a spec, or returns
  the ticket to Design at the plan gate: it writes the spec in its own
  worktree and draft PR. Build reads the merged spec and runs the `build-start` pickup review.

## 4. How specs fit with the other documents

- **Design doc:** `docs/DESIGN.md` when it exists, the end-to-end anchor for a body of work.
- **Intent:** the Jira ticket: what the customer needs.
- **Spec:** what we will build for one chunk of work.
- **Plan:** the agent's runbook for implementing one ticket, in `docs/plans/`.
- One chunk runs intent > spec > plan. Do not treat a plan as a spec, or a spec as a design doc.
- Spec grain size is undecided.
- Completed specs stay where they are; archiving them as history only is deferred.

## 5. Spec edits

- Edit a spec when the ticket's work needs it, by the size rules below.
- A small edit rides in the PR of the ticket that prompted it. An edit that changes what will
  be built takes its own reviewed PR. The Review bullet of the specifications rule carries
  the wording.
- Do not add a `status:` or date frontmatter field. Leave existing status text as it is unless
  the user directs otherwise.
- Do not move, archive, or delete a spec without user direction.
