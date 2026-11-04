---
id: infrasec-5248_faster-make-check
prepared_by: Claude Code (Opus 5.5) with Mike Bell
purpose: Cut make check's wall time by running the bats files in parallel, dropping bats-file, and skipping the Helm repo refresh.
---

## Plan

### Intent

[INFRASEC-5248](https://teamprovi.atlassian.net/browse/INFRASEC-5248). The Verification goals
number the ticket's acceptance criteria 1 to 10 in the order the ticket lists them.

### Premises

Checked against `main` at `a424256`:

- Confirmed: there are 123 tests in 12 files under `test/`. Five of them call `skip`.
- Confirmed: every `setup()` loads bats-support, bats-assert and bats-file. bats-file is used only
  for `temp_make` and `temp_del`, 12 each.
- Confirmed: `scripts/update-fixture-charts.sh:79` runs `helm dependency update` with no flags. The
  fixtures depend only on `file://../../../charts/common`.
- Confirmed: on this Mac, `parallel` is moreutils' and GNU parallel is absent. The bundled bats
  (1.11.0) needs GNU parallel or rush for `--jobs`.
- Confirmed: `TAG=<typo> make test` runs 0 tests and passes today.
- Refuted (comment 158034, option 1): loading the helpers once per file does not save the time
  the comment estimated. bats sources the file again for every test. Timings on this Mac, bats
  only: unchanged 49s, top-level loads 46.8s, bats-file dropped 39.1s, parallel per file 15.0s,
  parallel with bats-file dropped 13.7s.
- Baseline `make check` in this worktree at `a424256`: 55.35s and 52.65s back to back, 123/123
  passing, clean tree afterwards.

### Scope

- `scripts/test.sh` (new)
- `Makefile` (the `test` target only)
- `scripts/update-fixture-charts.sh` (the `helm dependency update` call and its echo line)
- `test/test_*.bats` (setup and teardown only)
- `.gitmodules` and the `test/test_helper/bats-file` submodule (removed)
- `README.md` (the Testing section, and the Development and Releasing links)
- `test/test_autoscaler.bats` and `test/test_configmaps.bats` (the `cmp -s` assertions only)
- `CLAUDE.md` (the Toolchain, Gate implementations, and Services rows)
- `docs/plans/infrasec-5248_faster-make-check.md`

Not touched: `test/fixtures/**`, `test/expected_output/**`, `.github/workflows/release.yml`,
`charts/common/**`, and `scripts/check.sh`.

Tier: Standard. The operator chose this at the intake stop. The Tiers definition would place a
change to the gate scripts at Full.

### Approach

1. **Fixture refresh.** In `scripts/update-fixture-charts.sh`, run `helm dependency update
   --skip-refresh`. The flag exists in Helm 3 and 4, so the Helm 3 security job keeps working.
2. **Tests drop bats-file.** In each `test/test_*.bats`, `setup()` loads bats-support and
   bats-assert and sets `TEST_TEMP_DIR="$BATS_TEST_TMPDIR"`. The `teardown()` is removed. No
   test body changes.
3. **Remove the submodule.** Remove `test/test_helper/bats-file` from `.gitmodules` and from the
   index. `make install` needs no change.
4. **Runner, `scripts/test.sh`.** It runs from the repo root, with `TAG` defaulting to `all` and
   the bats binary overridable through `BATS` (for verification only).
   - **Count.** `expected=$(bats --count --filter-tags tag:$TAG test/)`. If that is 0, it exits 1
     naming the tag.
   - **Run directory.** It creates one run directory with `mktemp -d`.
   - **Parallel run.** `xargs -P <cores>` runs one bats per `test/*.bats` file, where cores comes
     from `getconf _NPROCESSORS_ONLN` and falls back to 4. Each bats gets `TMPDIR=<run>/tmp
     --no-tempdir-cleanup --filter-tags tag:$TAG`, and its stdout and stderr go to
     `<run>/out/<file>.tap`.
   - **Output.** The per-file outputs print in file order.
   - **Pass or fail.** It counts `ok` and `not ok` lines, including `# skip` ones. It fails when
     xargs exits non-zero, when any test is `not ok`, or when that count differs from
     `expected`, printing the expected and actual counts.
   - **Cleanup.** On pass it deletes the run directory. On failure it keeps it and prints the
     path of the kept temp dirs. Each test's dir has a `.name` file beside it naming the test.
   - **No GNU parallel.** It never calls `parallel` or `bats --jobs`.
5. **Makefile.** The `test` target becomes `TAG=$(TAG) bash scripts/test.sh`, which drops
   `BATSLIB_TEMP_PRESERVE_ON_FAILURE`. The `TAG ?= all` default stays.
6. **Docs.**
   - `README.md`'s Testing section covers: `make check` versus `make test`, the parallel run,
     that a `TAG` selecting no tests fails, and where a failed run's temp dirs are kept.
   - `CLAUDE.md` updates three rows. Toolchain lists bats-support and bats-assert only. Gate
     implementations describes the parallel per-file runner and its count guard. Services
     drops the Helm repo refresh.

Added at the operator's instruction after implementation ("Make all 3 followup fixes now"):

7. **Diff on failure.** The two `assert cmp -s` assertions become `assert diff -u`. The
   comparison stays byte-exact (no `-b`), and a failure prints the diff.
8. **README links.** The Development and Releasing sections link the missing `dev/README.md`.
   Point Development at the Testing section, and drop the dead link from Releasing.
9. **Locally configured repositories.** A repo in the engineer's `repositories.yaml` with no
   cached index fails `helm dependency update` even with `--skip-refresh`. The fixture script
   runs it with `HELM_REPOSITORY_CONFIG=/dev/null`, since the only dependency is `file://`. This
   removes the failure, so no message is needed.

### Verification goals

Evidence is command output saved under the session scratchpad and summarised in the PR.

| AC | Goal | Kind | Evidence |
|---|---|---|---|
| 1 | `make check` runs all 123 tests and exits 0 | test | `make check` output: the runner reports 123 of 123 tests, exit 0 |
| 2 | A changed expected output fails the gate | test | Edit one line of `test/expected_output/autoscaler.yaml`, run `make check`: exit non-zero with the failing test shown. Restore the file with `git checkout` |
| 3 | The tree is clean after a passing and a failing run | inspection | `git status --short` is empty after the AC1 and AC2 runs (after the AC2 restore) |
| 4 | No Helm repository refresh | test | `make check` with `HELM_REPOSITORY_CONFIG` listing an unreachable repo (`http://127.0.0.1:9`) and `HELM_REPOSITORY_CACHE` holding a stub index for it: it passes with no "Hang tight" or "Unable to get an update" line. The same setup without `--skip-refresh` prints those lines (control) |
| 5 | `TAG` runs only the tagged tests | test | `TAG=podspec-securitycontext make test` runs exactly 1 test. `TAG=no-such-tag make test` exits non-zero naming the tag (brainstorm Q2) |
| 6 | Wall time at most 50% of `main` | test | Two timed `make check` runs back to back on this Mac, compared with the 55.35s/52.65s baseline. Both must be 26.3s or less |
| 7 | Fewer tests than defined fails, whatever `parallel` is installed | test | `BATS=<scratch wrapper that drops one ok line>` `make test` exits non-zero with expected and actual counts. AC1 passes on this Mac, where moreutils' `parallel` shadows GNU's. `scripts/test.sh` has no `parallel` or `--jobs` |
| 8 | CI's `make test` behaves the same | inspection | `CI=true make test < /dev/null` passes with 123 tests. `release.yml`'s test job runs `make test` after `update-fixture-charts.sh`. The runner uses only bash, xargs, mktemp and getconf, which ubuntu-latest has |
| 9 | bats-file is gone and the docs match | inspection | `.gitmodules` has no bats-file entry. `git grep -n 'bats-file\|temp_make\|temp_del'` finds only this plan. `git submodule status` lists two helpers. The `CLAUDE.md` Toolchain row is updated |
| 10 | A failed run keeps its temp dirs, and the README says how | test | The AC2 run prints a kept temp-dir path that exists and holds that test's output. `README.md` explains it |
| F1 | A failing `cmp` test prints a diff | test | Edit one line of `test/expected_output/autoscaler.yaml`, run `make check`: the output shows the changed line as a `-`/`+` pair. Restore the file |
| F2 | No dead README links | inspection | `grep -n 'dev/README' README.md` finds nothing |
| F3 | A configured repo with no cached index does not break `make check` | test | `make check` with `HELM_REPOSITORY_CONFIG` listing an unreachable repo and no cached index passes (failed before this step) |

### Risks

- **Interleaved or lost failure output.** This would show as a failing run whose diff is missing.
  Per-file capture printed in order prevents it, and the AC2 run checks it.
- **xargs exit codes differ** between GNU (123) and BSD. The runner treats any non-zero as
  failure.
- **A first-run race creating Helm's cache dirs** between parallel `helm template` calls is
  unlikely. `check.sh` and CI both run `helm dependency` first, which creates them.
- **Noisy output.** `--no-tempdir-cleanup` prints a `BATS_RUN_TMPDIR` line per file. The runner
  may drop those lines from a passing run's output.
- **A killed run** leaves its run directory under `$TMPDIR`. That is the same as the old
  preserve-on-failure behaviour.
- **The Stop hook names the failing gate `check`**, as it does today. It reads only the exit code
  and the last 200 lines, so the failing file's output must come last on a failure.

### Out of scope

- Fixture `Chart.yaml`/`Chart.lock` version drift: INFRASEC-5247.
- Running the tests on pull requests: INFRASEC-5242.
- `README.md`'s Releasing steps name `common/Chart.yaml`; the path is `charts/common/Chart.yaml`.

### Parking

Step 9, the gate run, after the follow-up fixes. Next: the plan-compliance review, then the PR.
