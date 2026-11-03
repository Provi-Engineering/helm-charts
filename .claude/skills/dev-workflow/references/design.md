# Design stage

Design runs when the operator says, at the intake stop, that the ticket needs a specification, or
returns the ticket to Design at the plan gate (Parking); never decide either on your own
judgment. Go to Build when the operator has said the ticket needs none, or when the ticket's
specification has merged. An existing Design worktree of the ticket whose PR has not merged, or
an open specification PR, resumes Design, even when an earlier specification for the ticket has
merged.

1. Create the ticket's Design worktree, or enter it when resuming (Worktrees). On resuming, run
   the `design-resume` pickup review before brainstorming.
2. Dispatch two or three `feature-dev:code-explorer` agents (Models) in parallel, each on a different
   aspect (similar features, architecture, extension points), and read the files they name.
3. Brainstorm with the operator and the product owner as in the brainstorm: one numbered question
   at a time; propose two or three approaches with a recommendation. At the Full tier, when the
   change alters a module boundary or an interface other code depends on, dispatch
   `feature-dev:code-architect` (Models) to test the recommended approach. Put each criteria edit
   the operator approves on the ticket.
4. Run the review cycle on the specification, following the specifications rule. Write it from the
   specification template that sits beside this reference; a filled-in example sits beside it too.
   After the review cycle's Write and before its Review, run the `draft-spec` intent review, and
   revise the draft with the operator on an Important finding.
5. Operator gate (publishing work reaches the team): push and open the specification's dedicated
   draft PR with `gh pr create --draft` only when the operator approves. Stop: the merge is
   acceptance, and Build starts from the merged specification, in a later session. Once the PR is opened,
   or the stage stops for the merge, delete the Design worktree's workflow state file,
   `.claude/dev-workflow-state.yaml`, so a later compaction there does not re-invoke the workflow.
