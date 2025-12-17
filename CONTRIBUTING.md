# Contributing

This document explains how to work with our Git repository, how to choose the right branch, and how to submit changes so they can be released in the correct version line.

We maintain **multiple active release lines** (e.g. `1.8.x` and `1.9.x`) and use a `release/X.Y` branching pattern for long-lived maintenance branches.

---

## Table of Contents

1. [Branching Model Overview](#branching-model-overview)
2. [Which Branch Should I Use?](#which-branch-should-i-use)
3. [Working on Features](#working-on-features)
4. [Working on Bugfixes](#working-on-bugfixes)
5. [Versioning and Tags](#versioning-and-tags)
6. [Pull Request Guidelines](#pull-request-guidelines)
7. [Commit Message Guidelines](#commit-message-guidelines)
8. [Release & Backport Policy](#release--backport-policy)
9. [Development Setup](#development-setup)

---

## Branching Model Overview

We use a simple branching structure with:

- **`main`**
  - The primary development branch.
  - New features and most bugfixes are merged here first.
  - Represents the next minor/major release line (e.g. `1.9.x`).

- **`release/X.Y`**
  - Long-lived maintenance branch for a specific minor version.
  - Example: `release/1.8`, `release/1.9`, etc.
  - Only receives **bugfixes**, **security fixes**, and **critical stability changes** compatible with that `X.Y` API.
  - Patch releases (e.g. `1.8.1`, `1.8.2`) are cut from this branch.

- **Short-lived topic branches**
  - Created from `main` or a `release/X.Y` branch:
    - **Feature branches:** `feature/<short-description>`
    - **Bugfix branches:** `bugfix/<issue-or-short-description>`
    - **Chore/infra branches:** `chore/<description>`

We do **not** develop directly on tags. Tags (e.g. `v1.8.0`) are immutable pointers to specific release commits.

---

## Which Branch Should I Use?

Use this decision tree to pick a base branch for your work:

1. **Are you implementing a new feature, API, or behavior change?**
   - **Yes →** Base your work on **`main`**.
   - We only add new features to the latest development line.

2. **Are you fixing a bug that affects the latest release line (e.g. `1.9.x`)?**
   - **Yes →** Base your work on **`main`**.
   - Maintainers will backport to older `release/X.Y` branches if needed.

3. **Are you fixing a bug that only affects an older maintained line (e.g. `1.8.x`), and you know it does not apply to current `main`?**
   - **Yes →** Base your work on **`release/1.8`** (or the relevant `release/X.Y` branch).
   - Mention this explicitly in your PR description.

If you are unsure, default to **`main`** and describe the affected versions in your issue/PR; maintainers will decide whether and where to backport.

---

## Working on Features

1. **Sync your local repo**

   ```bash
   git fetch origin
   git checkout main
   git pull origin main
	```

2. **Create a feature branch**

   ```bash
   git checkout -b feature/<short-description>
   ```

3. Implement your changes, tests, and docs.

4. Run the test suite and linters (see [Development Setup](#development-setup)).

5. Push your branch and open a PR targeting **`main`**.

   ```bash
   git push origin feature/<short-description>
   ``` 

---

## Working on Bugfixes

### A. Bugfixes that should land in the latest line (default)

Most bugfixes should be implemented against `main` first.

1. **Sync from `main`**

   ```bash
   git fetch origin
   git checkout main
   git pull origin main
   ```

2. **Create a bugfix branch**

   ```bash
   git checkout -b bugfix/<issue-or-short-description>
   ```

3. Implement the fix and tests.

4. Push and open a PR targeting **`main`**.

   ```bash
   git push origin bugfix/<issue-or-short-description>
   ```

5. In the PR description, specify which versions are affected:
   - For example: “Affects 1.8.x and 1.9.x” or “Introduced in 1.9.0”.

Backports to `release/X.Y` branches (see [Release & Backport Policy](#release--backport-policy)).

---

### B. Bugfixes for a specific maintenance branch (`release/X.Y`)

If you know a bug affects a specific old line (e.g. `1.8.x`) and you are targeting that line explicitly:

1. **Start from the maintenance branch**

   ```bash
   git fetch origin
   git checkout release/1.8
   git pull origin release/1.8
   ```

2. **Create a bugfix branch**

   ```bash
   git checkout -b bugfix/1.8/<issue-or-short-description>
   ```

3. Implement the fix and tests.

4. Push and open a PR targeting **`release/1.8`**.

   ```bash
   git push origin bugfix/1.8/<issue-or-short-description>
   ```

5. In the PR description, mention:
   - That it targets `release/1.8`.
   - Whether the same bug exists in `main` or other release lines.

Forward-port this fix to `main` and other branches via cherry-pick if applicable.

---

## Versioning and Tags

We use **Semantic Versioning**: `MAJOR.MINOR.PATCH` (e.g. `1.8.1`).

- **Tags**
  - Created in the form `vMAJOR.MINOR.PATCH` (e.g. `v1.8.0`, `v1.8.1`).
  - Point to the exact commit used to build that release.
  - Example tagging pattern:

    ```bash
    # On release/1.8 after merging all fixes
    git checkout release/1.8
    git pull origin release/1.8

    # Update version metadata in the codebase to 1.8.1 (if applicable)
    git commit -am "Bump version to 1.8.1"

    git tag -a v1.8.1 -m "Release 1.8.1"
    git push origin release/1.8
    git push origin v1.8.1
    ```

---

## Pull Request Guidelines

When opening a PR:

1. **Base branch**
   - Default: `main`
   - Bugfix for a specific line: `release/X.Y` (only if you’re intentionally targeting that line).

2. **Keep PRs focused**
   - One logical change per PR (e.g. one bugfix, one feature).
   - Avoid mixing refactors, style changes, and behavior changes unless necessary.

3. **Tests**
   - Add or update tests to cover your change.
   - Ensure the test suite passes locally.

4. **Documentation**
   - Update relevant docs/comments if behavior or APIs change.
   - For user-facing changes, update the changelog entry in the appropriate section if requested by maintainers.

5. **Checklist for the PR description**
   - Brief summary of the change.
   - Include the Jira ticket key.
   - Affected version lines (e.g. “Affects 1.8.x and 1.9.x”).
   - Any breaking changes or migration notes.

---

## Commit Message Guidelines

We prefer clear, structured commit messages. A good pattern is:

- Short, imperative subject line (max ~72 characters).
- Optional body with:
  - Motivation/intent.
  - High-level description of what changed.
  - Any implications or follow-up work.

Examples:

- `INFRASEC-1234 Fix race condition in request cache`
- `INFRASEC-1234 Add retry logic to API client`
- `INFRASEC-1234 Backport: validate config on startup for 1.8.x`

If you use a conventional format (e.g. Conventional Commits), keep it consistent and include the Jira key in the body of the PR mesage:

- `fix: handle null values in parser`
- `feat: add pagination to list endpoint`
- `chore: update CI matrix`

---

## Release & Backport Policy

We support multiple active lines using `release/X.Y` branches:

- **Current line (e.g. `1.9.x`)**
  - Developed on `main`.
  - Features + bugfixes + refactors.
  - Minor/major versions are branched off as `release/X.Y` when released.

- **Previous lines (e.g. `release/1.8`)**
  - Only receive:
    - Critical bugfixes
    - Security fixes
    - Low-risk stability improvements
  - No new features or breaking changes.

### How backports work

1. A bugfix is merged into `main`.
2. Developer determines which `release/X.Y` branches are affected.
3. The fix is cherry-picked into those branches:

   ```bash
   # Example: backport from main to release/1.8
   git checkout release/1.8
   git pull origin release/1.8
   git cherry-pick <commit-sha-from-main>
   # Resolve conflicts if any, then:
   git push origin release/1.8
   ```

4. A new patch release (e.g. `v1.8.1`) is cut from `release/1.8`.
