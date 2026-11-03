# Parking

When blocked (an unanswered question, a red gate with an unplanned cause), park the plan as the
plans rule describes and stop: only the operator can resolve the blocker, and an unattended
session does not decide for them. A specification or plan parked before approval stays
uncommitted in its worktree.

A return to Design from the Test stage (the operator's choice at the plan gate) parks the Build in
the ticket's Build worktree: the return keeps that worktree and creates the ticket's Design
worktree for the specification edit. After the edit merges, the next session resumes the ticket's
Build worktree, rebases it onto `origin/main`, runs the `build-start` pickup review on the edited
specification, and returns to the plan gate. A resume with no specification change skips the
pickup review. When that pickup review raises an Important finding that changes what will be
built, the Build parks again for another specification edit and the same loop repeats.

To resume a parked ticket, start from the state file and the plan's Parking section, enter the
stage's existing worktree (never create a second one for the same stage), and continue from the
parked step.
