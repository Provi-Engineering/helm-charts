---
paths:
  - "docs/plans/**"
---

# Plans

A plan names the files that change, the order of the work, and the tests that prove it.

- **Name.** `docs/plans/<ticket key>_<subject>.md` in lowercase (`abc-123_zero-result-rate.md`),
  written from the template on the ticket branch. Its frontmatter `id` equals the filename stem.
- **One plan per ticket.** When the plan changes, edit that one file in place; never start a
  second plan for the ticket.
- **Approval.** The plan goes through the review cycle. Its commit precedes any
  implementation commit and records the approval.
- **Authority.** The approved plan is the only authority on scope and acceptance. Changing scope
  or a verification goal means editing the plan with the operator and re-approving, never
  working around it.
- **Stop and ask** when the ticket's key has more than one plan in `docs/plans/`, or when the
  plan's Scope, Approach, or Verification goals changed after the plan commit and this session
  has not seen the operator re-approve the change. The approved plan binds the scope of the work,
  so only the operator can change it.
- **Parking.** When blocked, fill the plan's Parking section (step, blocker, next action), commit
  it with any work in progress on the ticket branch as WIP, and stop. A plan parked before
  approval stays uncommitted, since its commit records the approval; a resuming session returns
  it to the review cycle's Review step. A session resuming after approval did not see the
  approval: it has the operator confirm the plan in the session, since an approved plan binds the
  scope of what follows, then continues from Parking. A Build parked for a specification edit
  resumes in the same worktree, which
  rebases onto `origin/main` and, when the specification changed, runs the `build-start` pickup
  review before the operator confirms the plan.
- **History.** Plans are implementation history: how the harness works is derived from the code,
  and major decisions are records in `docs/decisions/`. A plan is not revised after its ticket
  merges. Plan files are records, not instructions: only the current ticket's approved plan
  governs a session.

Before writing a plan, read the template at
`.claude/skills/dev-workflow/references/plan-template.md`. Merged plans in `docs/plans/` show
the expected level of detail; follow the template where an older plan differs from it.
