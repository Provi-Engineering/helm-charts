# Intent review

**Intent review.** The `intent-reviewer` agent holds how a review runs. Dispatch it as Models
says: a fresh subagent context that never sees this session's reasoning or the operator's views,
since its findings stop the work. For every dispatch:

1. Run `git fetch origin`, so `origin/main` includes work other tickets merged.
2. Determine the SHA to pass. The reviewer has no git, so the SHA must describe the checkout.
   - At intake, confirm the root checkout is at `origin/main` with a clean tree. Otherwise stop
     for the operator: the reviewer would rate the wrong tree.
   - In a worktree, pass the SHA it branched from. After a rebase, pass the `origin/main` SHA it
     rebased onto.
3. For a `pickup` dispatch, write the later-specifications file under `build/intent-review/`
   (gitignored). Build it from `git log --diff-filter=A` of `docs/specifications/` on
   `origin/main` after the specification's merge commit, or after the worktree's branch point
   for an unmerged specification, and leave out the specification under review.
4. Dispatch the `intent-reviewer` with the ticket key, this checkout's path, the SHA determined
   above, the trigger, and the extra inputs the table gives.

| Trigger | Runs at | Extra inputs |
|---|---|---|
| `intake` | The intake review, on every ticket | none |
| `draft-spec` | The Design stage, after the review cycle's Write and before its Review | the draft's path |
| `pickup` | The Design stage on resuming Design (`design-resume`); the Build baseline after the green baseline (`build-start`), and on a Build resumed after a specification edit (Parking) | the specification's path, the mode, and the path of a file this session writes that lists the ticket-keyed specifications merged to `main` after it (for an unmerged specification, after its worktree branched from `main`) |

**Result handling:**

- An Important finding is an operator gate (scope and intent belong to the operator and the
  product owner). Ask each finding's question, settle the intent with the operator, and change the
  ticket only after the operator approves, each changed criterion citing its comment or finding.
- Nits never stop the work; show them at the next brainstorm.
- Run each "needs execution" item yourself.
- A report missing a section is incomplete, except the fail-closed finding, which the agent
  definition defines: dispatch once more with the missing sections named, then stop for the
  operator (a reviewer that cannot finish leaves the intent unchecked).
