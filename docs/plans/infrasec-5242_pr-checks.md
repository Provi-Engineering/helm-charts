---
id: infrasec-5242_pr-checks
prepared_by: Claude Code (Opus 5.5) with Mike Bell
purpose: Run the test gate and the Snyk IaC scan on pull requests against main, without running the release.
---

## Plan

### Intent
[INFRASEC-5242](https://teamprovi.atlassian.net/browse/INFRASEC-5242). No specification.
The Verification goals number the ticket's acceptance criteria in order (AC1 to AC8).

### Premises
Checked against `main` at `a424256`:

- Confirmed: `.github/workflows/release.yml` triggers only on push to `main` and `ci-testing`;
  no pull request runs a check.
- Confirmed: `release` runs `needs: [test, security]` with `contents: write`, and has no `if:`,
  so adding a `pull_request` trigger alone would run it on pull requests.
- Confirmed: the `test` job copies the steps of `scripts/check.sh` and runs `make test`; it never
  runs `make install` or `make check`.
- Confirmed: the `security` job installs the latest Helm 3 with `get-helm-3` inside the
  `snyk/snyk:node` container.
- Confirmed: every fixture depends on `charts/common` through `file://`, so `make check` needs no
  network beyond the bats submodules, which are public https repositories.
- Confirmed: `main` has no branch protection and no ruleset, so a new check is advisory.

### Scope
- `.github/workflows/release.yml` (hotspot: `.claude/rules/hotspots.md`)
- `CLAUDE.md`: the CI repo-fact row only
- `docs/plans/infrasec-5242_pr-checks.md`

No chart output changes, so no version bump and no `CHANGELOG.md` entry.

Tier: Full

### Approach
1. Add `pull_request: branches: [main]` to the workflow's `on:` block, beside the existing push
   trigger.
2. `test` job: keep the checkout and the `azure/setup-helm@v5` v4.3.1 step; drop
   `submodules: true` and replace the copied dependency, fixture, and `make test` steps with
   `make install` then `make check`, so CI runs the same targets as engineers.
3. `security` job: replace the `apt-get`/`curl`/`get-helm-3` step with `azure/setup-helm@v5`
   pinned to `v4.3.1`, inside the existing container. The fixture-preparation and Snyk steps stay.
4. `release` job: add `if: github.event_name == 'push'`, so pushes to `main` and `ci-testing`
   still release and a pull request never does.
5. `CLAUDE.md` CI row: say that pull requests against `main` run `test` and `security`, and
   pushes to `main` and `ci-testing` also run `release`; drop the "until INFRASEC-5242 lands"
   clause.
6. Local `make check` green, then open the PR; its own checks are the main evidence.

### Verification goals
| AC | Goal | Kind | Evidence |
|---|---|---|---|
| 1 | The PR shows a `test` check before merge | inspection | This ticket's PR checks list |
| 2 | `test` fails when a chart test fails | inspection | The `test` job's last step is `make check`; `scripts/check.sh` runs under `set -euo pipefail` and ends with `make test`, so a failing bats test exits non-zero and fails the step |
| 3 | The PR check and local `make check` agree on one commit | test and inspection | `test` runs `make check` (workflow diff); local `make check` and the PR's `test` both green on the PR head SHA |
| 4 | The PR shows a `security` (Snyk IaC) check before merge | inspection | This ticket's PR checks list |
| 5 | The Snyk job installs Helm 4 | inspection | Workflow diff, and the `security` job log showing Helm v4.3.1 installed |
| 6 | A PR never runs `release`; pushes to `main` and `ci-testing` still do | inspection | `release` shows as skipped on the PR; the `if:` in the workflow diff |
| 7 | A push to `main` still runs `test`, `security`, and `release` | inspection | The Actions run for the merge commit on `main` (chart-releaser finds no new version and publishes nothing) |
| 8 | Merged through the dev-workflow skill | inspection | The merged PR and this plan's commit |

### Risks
- `azure/setup-helm` may not run inside `snyk/snyk:node`. It would show as a red `security` check
  on the PR. The fallback, running `security` on `ubuntu-latest` without the container, changes
  the Approach and needs re-approval.
- A PR from a fork gets no `SNYK_TOKEN`, so `security` fails there. Issue authors are internal
  only, so PRs come from branches in this repository.
- The merge run on `main` (AC7) is only observable after merge. If `release` is skipped there, the
  `if:` is wrong; a follow-up fix would be needed before the next chart release.

### Out of scope
- Make `test` and `security` required checks on `main` (branch protection or a ruleset), once
  this merges and the check names are fixed: follow-up ticket, filed at Deploy (brainstorm Q2).
- Workflow-level `permissions: contents: read` and a `concurrency` group for PR runs: declined
  by the operator (brainstorm Q5).

### Parking
Step 8, the implementation subagent: plan approved.
