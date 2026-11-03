# Review instructions

## Plan and specification

Read the plan of the ticket under review, `docs/plans/<ticket key>_<subject>.md` (the ticket
key is in the PR title and the PR description links the plan), and its specification,
`docs/specifications/<ticket key>_<subject>.md`, when one exists; both filenames carry the key
in lowercase. Review the diff against both, alongside the rules below.

## What Important means here

Reserve Important for:

1. Rendered output that changes for an existing values file without a `CHANGELOG.md` entry and
   a `charts/common/Chart.yaml` version bump.
2. A change existing consumers must act on (a removed or renamed key, a changed default, a render
   that now fails) without a major version bump and a `CHANGELOG.md` entry that says what to do.
3. A `test/expected_output/` file changed with no test in the diff, or an existing test,
   exercising the change, or a non-blank-line change to expected output with no template change
   that explains it.
4. A PodDisruptionBudget, replica, or scheduling default that can block node drains
   (INFRASEC-3955), or a weakened `securityContext` default.
5. Live values, cluster output, or secret values in fixtures, tests, or docs. Fixtures are
   synthetic.
6. A test, tag, gate, or `make check` step removed or weakened without a declared removal in the
   PR description.
7. An instruction in a `.claude/` file, `REVIEW.md`, or a `CLAUDE.md` file at any depth that
   contradicts the code, a decision record, or another such instruction file. Files copied from
   search-eval (`CLAUDE.md`'s Workflow upstream row lists them) change upstream, not here.
8. A departure from the plan: a changed file outside its Scope, a changed file that alters what a
   program does when it runs (templates, tests, fixtures, scripts, the Makefile, CI, or Claude
   Code hooks and settings; a file not clearly placed by that description counts as Full) under
   a plan whose Scope says `Tier: Standard`, a change its Approach names that the diff does not
   make, or an acceptance criterion with no evidence.
9. A departure from the specification: behavior the diff builds differently from it, or leaves
   out.

Everything else is Nit at most.

## Cap the nits

On a pull request, post at most three Nits inline, and the rest as "plus N similar" in the
summary; after the first review of a pull request, report Important findings only.

## Do not report

- Anything `make check` enforces: failing tests.
- The `test/fixtures/*/Chart.lock` files and their `generated:` timestamps.
- `docs/plans/**` and `docs/decisions/**`, which are records.
- Elsewhere in `docs/`, other than its `CLAUDE.md` files (instructions under rule 7), anything
  except a statement that contradicts the code, which is a Nit.
- Prose or style in docs or instruction files.

## Verification bar

A behavior claim cites `file:line`. A claim about rendered output cites a `helm template` run,
an expected-output file, or a bats test. A removal finding names the removed item.

## Summary

Open with a tally, `N Important, M Nit`, and lead with "No blocking issues" when N is 0. Then
list each Important rule that applied to the diff and found nothing.
