# Test stage

The change is verified before it is pushed and before a human sees it.

## Gate run

Run `make check`. Its output is the evidence; your own report of a pass is not. Any code change
after a green run means running it again.

**The Stop hook** runs `make check` when the session ends a turn on a tree that differs from
`main` and holds the turn while it fails; a second stop on the same red tree ends the turn and
tells the operator which gate failed.

Once `make check` is green, commit the change under Commits, before the first review pass; fixes
from the passes are later commits.

Then the review passes the tier runs (Tiers) run in this order. Each runs outside this session's
context, in a subagent or in a command that dispatches its own, so the reviewer sees the change
and not this session's reasoning. A subagent can use only the tools its definition grants: put in
its prompt anything those tools cannot fetch.

## Simplify

Full only. Dispatch the `code-simplifier:code-simplifier` subagent (Models) on the changed files.
It makes clarity, reuse, and efficiency changes with no behavior change. It edits files, so read
what it changed, then rerun `make check`.

## Code review

At the Full tier, run the built-in `/code-review` at `medium` on the changeset for correctness; it
dispatches its own reviewers, which inherit the session's model (Models).

## The plan-compliance review

At both tiers, dispatch a `feature-dev:code-reviewer` subagent (Models) for plan compliance. It
has no shell and cannot run git: save the output of `git diff main` (committed and uncommitted
changes) and `git status --short --untracked-files=all` (which lists each new untracked file) to a
file. Save the `/code-review` findings (Full) and the final `make check` output to files too. Give
the subagent the paths of those files and of the plan, and these files from the skill's
references: `.claude/skills/dev-workflow/references/plan-compliance.md` (its brief) and
`.claude/skills/dev-workflow/references/tiers.md`, plus `REVIEW.md` and the specification when one
exists. The PR body lists this pass's findings under the rating the subagent gives.

## Security review

Full only. Commit each fix from Simplify and Code review still uncommitted under Commits, so the
command's diff holds the change and every fix. Then dispatch a general-purpose subagent (Models)
that invokes `/security-review` through the Skill tool, waits for every sub-task the command
launches, and returns only the command's report. A `security-guidance` finding joins this
review's findings; nothing waits for it. Record each finding's disposition and continue in the
same turn.

Fix each finding inside the plan's Scope, or record why it stands; a finding that reaches
credentials, authorization, or untrusted input blocks the change until it is fixed. A fix that
needs a file outside the Scope returns to the plan gate (an out-of-scope fix widens the ticket),
and a security problem that predates the change becomes a follow-up ticket. Commit the fixes,
rerun `make check`, and run this review once more; skip the recheck when no finding was fixed.
Operator gate (the recheck decides whether the change ships): the recheck reports a finding not
already dispositioned.

## The fix loop

A fix from Simplify or Code review that changes code reruns `make check` and every pass after the
one that found it. Keep each pass's findings and dispositions: the PR body carries them. The
session decides each finding's disposition and any plan amendment; the implementation subagent
(Models) makes every fix, from Code review, Security review, and the PR review round, given the
finding, the plan, and the worktree path.
