# Code structure for concurrent work

Several agents and engineers work in this repo at once. Structure changes so two tickets rarely
touch the same lines.

- **One concern per module**, with a small public surface. Add new behavior as a new module
  rather than growing a shared one.
- **Registries over conditional chains.** Where code selects among variants, register each
  variant in one place so a new ticket adds an entry instead of editing a branch other tickets
  also edit.
- **Reuse before adding.** Search for an existing helper first. Extracting shared code is its
  own ticket, not a side effect of a feature ticket.
- **Known hotspots.** `.claude/rules/hotspots.md` lists the files that change together. A
  ticket touching one declares it in its scope and does not run in parallel with another ticket
  that does. Two tickets with overlapping scope run in sequence, never in parallel.
- **Everything runs locally.** Code paths are testable against fixtures with no network and no
  credentials, so every change has a fast `make check` loop.
