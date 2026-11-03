````markdown
---
id: <ticket key>_<subject>
prepared_by: <agent and model> with <operator>
purpose: <one sentence>
---

## Plan

### Intent
A link to the ticket, which holds the intent and its acceptance criteria. Do not copy,
compact, or summarize them here; the Verification goals refer to them by the ticket's
numbering. Link the specification when one exists.

### Premises
What the ticket and specification assume, checked against the base branch at a named short commit SHA: confirmed or refuted.

### Scope
The files and globs this change may touch. Nothing outside this list changes. End with the
tier the operator approves (Tiers): `Tier: Full` or `Tier: Standard`.

### Approach
The chosen approach, in the order it will be built.

### Verification goals
| AC | Goal | Kind | Evidence |
|---|---|---|---|
| 1 | The behavior a passing check demonstrates | test or inspection | Named test, or named artifact |

### Risks
What could go wrong and how it would show.

### Out of scope
Work found during planning, proposed as follow-up tickets.

### Parking
Current step, blocker if parked, next action.
````
