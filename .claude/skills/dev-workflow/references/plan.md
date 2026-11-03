# Plan stage

The ticket in the tracker carries the intent; there is no separate intent file.

## The intake review

Run the intent review (trigger `intake`): it reads the ticket, every comment, and linked issues.
Work without a ticket first gets one: restate the request as acceptance criteria.
Operator gate (the request is the only record of its intent): the operator confirms the criteria.
Only then file them in the tracker (the Tracker repo fact), since the plan filename and the commit
subject need the ticket's key, and run the intake review on it. No other path files a ticket.

## The finding gate

Act on the intake result: settle each Important finding as Result handling says. At this gate the
session asks each finding's question, states no tier and no specification recommendation, and
stops at each finding before going on. Before running a "needs execution" item that spans more
than a few files, dispatch `feature-dev:code-explorer` (Models) to map them. The Facts section
checks the ticket's premises against `main`; a refuted premise is an Important finding.
Operator gate (scope belongs to the operator): the operator decides whether to close the ticket.
Post a ticket comment carrying the evidence only after the operator approves it, since a comment
reaches the team. A finding is settled when the operator has answered it and every ticket edit the
operator approved is on the ticket. When the operator closes the ticket, stop and state no tier.

## The intake stop

Reached only once every Important finding is settled, or at once when there are none. State a
provisional tier (Tiers) from what the ticket will change, and a specification recommendation:
none when the deliverable is a document or a data pull (data captured from a source outside the
repo; the Deliverables that need no specification repo fact lists this repository's cases),
otherwise for or against with a reason. Then stop.
Operator gate (whether Design runs and which tier applies are scope, which the operator decides):
continue only after the operator answers. Then delete the workflow state file,
`.claude/dev-workflow-state.yaml`, in the root checkout, so a later compaction there does not
re-invoke the workflow.
