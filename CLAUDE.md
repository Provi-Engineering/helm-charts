# CLAUDE.md

Instructions for Claude Code working in helm-charts: Provi's shared `common` Helm library chart,
which service charts depend on for their Kubernetes manifests. Start every ticket with
`/dev-workflow <KEY>`. The `dev-workflow` skill holds the workflow and cites the repo facts below
by their labels. Run the session unattended (auto mode) only after the plan is approved.

## Repo facts

| Repo fact | Value |
|---|---|
| Project | `charts/common` is a Helm library chart: named templates for deployments, statefulsets, jobs, cronjobs, ingresses, autoscalers, PDBs, and the pod spec they share. `test/` renders fixture charts that depend on it and compares the output |
| Language | Helm templates (Go templates and Sprig) producing Kubernetes YAML; tests in bats |
| Toolchain | Helm 4 (CI pins v4.3.1; `make check` refuses Helm 3, whose blank-line output differs). bats-core and its helpers are git submodules that `make install` initialises. [uv](https://docs.astral.sh/uv/) runs the Stop hook only |
| Gate implementations | `make test` runs the bats suite in `test/`. `make check` builds `charts/common`'s dependencies, points every fixture chart at the current `charts/common` version, runs `make test`, then restores the fixture `Chart.yaml` and `Chart.lock` files. `make test` alone needs those fixture dependencies, so in a fresh checkout or worktree run `make check` once before `make test` or `TAG=<tag> make test` (one tagged test; not a gate). If a killed run leaves `test/fixtures/*/Chart.*` modified, `git checkout -- test/fixtures` restores them |
| Services the gates need | No credentials and no cluster. `make install` fetches the bats submodules, and `make check` runs `helm dependency update` in each fixture, which also refreshes any Helm repositories you have configured locally |
| Images | None |
| CI | GitHub Actions, `.github/workflows/release.yml`; read it to learn what CI runs. Pull requests against `main` run `test` (`make install`, then `make check`) and `security` (Snyk IaC); pushes to `main` and `ci-testing` also run `release`, which a pull request never does. Neither check is required by branch protection, so a merge is not blocked by a red check |
| Tracker | Jira project `INFRASEC`, keys like `INFRASEC-123` |
| Issue authors | Internal only |
| Tier examples | Full: `charts/common/**`, `test/**`, `scripts/`, the Makefile, `.github/`, `.gitmodules`, `.snyk`, and Claude Code hooks and settings. Standard: `README.md`, `charts/common/README.md`, `CHANGELOG.md` on its own, documents, plans, specifications, and agent instructions |
| Deliverables that need no specification | Documents: how-to, explanation, reference, and decision records |
| Deploy | A merge to `main` runs the tests and a Snyk IaC scan, then chart-releaser publishes `charts/common`'s `version` as a GitHub release and in the GitHub Pages chart index (provi-engineering.github.io/helm-charts) if that version is new; CI does not push to the S3 repository. Consumers (helm-deployments, provi-eks-workloads) take a release only when they bump their dependency pin. A release ticket bumps `charts/common/Chart.yaml`, adds a `CHANGELOG.md` entry, and regenerates the fixtures with `scripts/update-fixture-charts.sh <version>` |
| Workflow upstream | Copied from search-eval `c4cb069`: `.claude/skills/dev-workflow/`, `.claude/agents/intent-reviewer.md`, `.claude/hooks/stop_make_check.py`, `.claude/rules/concurrent-work.md`, and `.claude/rules/documentation/`. Change them there and re-copy; only `SKILL.md`'s gate sentence differs here. Every other `.claude/` file, `REVIEW.md`, and this file are helm-charts' own |
