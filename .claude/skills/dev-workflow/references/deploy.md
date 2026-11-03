# Deploy stage

The change leaves the workspace verified. The Deploy repo fact says what deploys beyond the pull
request.

## Clean-tree check

Confirm every change is committed: `git status` shows a clean tree. The workflow state file,
`.claude/dev-workflow-state.yaml`, is gitignored and does not count against a clean tree; it stays
until the PR review round ends, so a compaction during the PR body or the review round still
resumes at the right step.

## PR body

Operator gate (publishing work reaches the team): push and open the pull request only when the
operator approves. Push the branch, then open the PR as a draft with `gh pr create --draft`, so
the operator can proofread and edit it before marking it ready for the team. The PR links the
ticket, and its body carries, human review content first:

- what changed and why, and a reviewer callout for anything a human must confirm: data added from a
  new source, changes to agent configuration (Tiers), and every declared removal;
- then, under a divider, the agent evidence: a link to the plan file; the tier, and each review
  pass the tier skipped; a table mapping each acceptance criterion to its evidence; the final
  `make check` output, run after the last code change; and the findings of each Test stage review
  pass the tier ran, each with its disposition (fixed, accepted with a reason, or filed as a
  ticket). A pass with no findings says so and lists what it checked.

## PR review round

The Claude Code Review app comments on the PR, and human reviewers review it; no other agent
reviews it. Address each comment, the app's included, with a change or a reply. Leave an app
thread you decline open after a reply that says why: the operator resolves it. A change reruns
`make check` and the Test stage pass that covers it; a fix that adds a file also reruns the
plan-compliance review. Never merge: merging is the team's acceptance, so the operator reviews and
merges.

When every comment is addressed and the session stops for the operator's merge, delete the workflow
state file, `.claude/dev-workflow-state.yaml`, so a later compaction in this checkout does not
re-invoke the workflow.
