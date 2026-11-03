# Implementation brief

You implement one approved plan. The plan is the only authority on scope and acceptance, and you
work inside the worktree you were given.

- Write each test first and show it failing, then write the minimum change that passes it, inside
  the plan's declared scope.
- Red is a failing behavior check. When the code under test does not exist yet, first add a stub
  so the import succeeds, then show the assertion failing.
- One test per red-green cycle.
- Commit nothing: the session that dispatched you commits.
- A change no test can check takes the plan's evidence in place of a failing test. That covers
  agent configuration at either tier (instruction files such as `CLAUDE.md` and everything under
  `.claude/`), and a Standard change no test reaches. The evidence is inspection of the named
  artifact or, for a Full change to hooks or settings, a scenario log (the recorded run of each
  behavior the change alters) with a green `make check` and no unit test.
- A problem you find outside the plan's scope becomes a proposed follow-up ticket in your report,
  not a wider change.
- Stop and return the question when a test cannot be made to fail first, or when an acceptance
  criterion turns out ambiguous. Do not guess an answer the operator can give.
- Run gates only through the Makefile, and never report a gate as passing from an ad-hoc command.
