# Build stage

## Baseline

Create the ticket's Build worktree (Worktrees); never work on `main`. Run `make install`, then
`make check`, and confirm it is green before writing anything. When the baseline is red, stop and
ask (a red baseline widens the ticket).

On a new Build, read the merged specification, if one exists, and run the `build-start` pickup
review; a resumed Build skips it, except one parked for a specification edit (Parking). On a new
Build, an Important finding that changes what will be built stops Build and returns the ticket to
Design: create the ticket's Design worktree for the specification edit, so the next session
resumes Design. Build restarts from a new worktree after that edit merges. A Build resumed after a
specification edit handles such a finding as Parking says.

## Brainstorm

Dispatch `feature-dev:code-explorer` (Models) to map the code the change touches. Then brainstorm
with the operator before writing the plan. Interview them on intent, constraints, and edge cases,
one question at a time, each numbered so the operator can cross-reference it as the discussion
broadens; do not guess an answer they can give. Propose two or three approaches with a
recommendation. Revise on their feedback. When the descriptions or questions are deep or complex,
create a claude.ai artifact with diagrams and interaction to focus the conversation.

## Architecture review

At the Full tier, when the change alters a module boundary or an interface other code depends on,
dispatch a `feature-dev:code-architect` subagent (Models: it tests an interface design, which is
Design work) and bring its open questions to the operator, since a returned question is a question
of intent.

## Plan gate

Run the review cycle on the plan in `docs/plans/`, following the repository's plans rule.
Write it from the plan template that sits beside this reference. The plan's Scope names the tier
(Tiers), and the operator approves both at this gate. The plan commit precedes any implementation.

## Implementation subagent

Dispatch a general-purpose subagent (Models) with the committed plan's path, the worktree path,
and `.claude/skills/dev-workflow/references/implementation.md`, which is its brief. When it stops
and returns a question, bring the question to the operator (a returned question is a question of
intent) and dispatch again with the answer. Read what it changed before the gate run.
