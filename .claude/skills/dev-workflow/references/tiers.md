# Tiers

A ticket runs at one of two tiers, set by what its change does rather than where its files live:

- **Full.** The change alters what a program does when it runs: code, its tests, the configs it
  reads, the build and dependency files, CI, or Claude Code hooks and settings.
- **Standard.** Every other change.

The Tier examples repo fact lists this repository's cases. The examples illustrate the definition
and are not a list to keep complete. A file the definition does not clearly place counts as Full,
so a new kind of file gets more review, not less.

**Agent configuration** is `CLAUDE.md` at any depth, `REVIEW.md`, and every `.claude/**` path. A
change to its hooks or settings is Full, and a change to the rest, which is instructions, is
Standard.

Gates cover repo code only. Agent configuration gets no tests, make targets, or CI checks.

| Run | Standard | Full |
|---|---|---|
| The gate run (`make check`, also run by the Stop hook and CI) | yes | yes |
| The plan and its review cycle (the plan gate) | yes | yes |
| Commit once `make check` is green (the gate run) | yes | yes |
| The plan-compliance review | yes | yes |
| The architecture review | no | on a module boundary or interface change |
| Simplify | no | yes |
| Code review (`/code-review`) | no | yes |
| Security review | no | yes |

The intake stop states a provisional tier, the plan's Scope names the tier the operator approves,
and the plan-compliance review checks every changed file against the definition.
