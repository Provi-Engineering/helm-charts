#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

if ! command -v yq &> /dev/null
then
    echo "yq could not be found; install with Homebrew"
    exit 1
fi
SED=gsed

ORG="provi-engineering"
TO_VERSION="1.8.13"
BRANCH_NAME="bump-common-chart-${TO_VERSION}"
COMMIT_MESSAGE="chore: bump common chart to ${TO_VERSION}"
PR_TITLE="Bump common Helm dependency to ${TO_VERSION}"
PR_BODY="This PR updates the common chart dependency to ${TO_VERSION}"

# Define the from versions you want to upgrade
FROM_VERSIONS=("1.8.3" "1.8.9" "1.8.10" "1.8.11" "1.8.12")

# Repos to operate on
REPOS=(
  "AdHaus"
  "barback"
  "boozechoose"
  "bottling-plant"
  "cluster-canary"
  "customer-service-explorer"
  "distiller"
  "eventsink"
  "firewater"
  "forklift"
  "happy-hour"
  "happy-hour-validation-service"
  "maitred"
  "nysla"
  "pallet"
  "provi-devops"
  "provi-service"
  "provi-slack"
  "salesforce-event-consumer"
  "search-service"
  "speakeasy"
  "state-manager"
  "static-sites"
  "victualler-react"
  "wine-cellar"
)

DRY_RUN=false

function usage() {
  cat << EOF
Creates PRs for updating helm-charts with bugs we want to avoid. Edit the globals in the script to control to and from versions and the list of repos.

An example search for repos:

org:provi-engineering path:**/Chart.yaml "name: common" version: 1.8.10

Find a list of repos with this command, for example (finding charts using 1.8.10):

gh search code "1.8.10" --filename Chart.yaml --owner "provi-engineering" --json repository --jq '.[].repository["nameWithOwner"]' | sort -u |  awk -F'/' '{print \$NF}'

Usage:
     -h|--help                  Displays this help
     -v|--verbose               Displays verbose output
     -d|--dry-run               Dry-run mode; no PRs will be created
EOF
}

function parse_params() {
    local param
    while [[ $# -gt 0 ]]; do
        param="$1"
        shift
        case $param in
            -h | --help)
                usage
                exit 0
                ;;
            -v | --verbose)
                verbose=true
                ;;
            -d | --dry-run)
                DRY_RUN=true
                ;;
            *)
                script_exit "Invalid parameter was provided: $param" 1
                ;;
        esac
    done
}

function make_branch() {
  if [ "x$(git branch --list ${BRANCH_NAME})" == "x" ]; then
    if ${DRY_RUN} == "true"; then
      echo "   DRY_RUN: would have created branch $BRANCH_NAME"
    else
      git checkout -b "$BRANCH_NAME"
    fi
  fi
}

function checkout_main_branch() {
  # checkout main branch if it's not
  branch=$(git rev-parse --abbrev-ref HEAD)

  if [ "$branch" != "$DEFAULT_BRANCH" ] && [ "$branch" != "$BRANCH_NAME" ]; then
    git checkout $DEFAULT_BRANCH
    if ${DRY_RUN} == "true"; then
      echo "DRY_RUN: would have pulled"
    else
      git pull
    fi
  fi
}

function main() {

  if [ "${DRY_RUN}" == "true" ]; then
    echo "DRY_RUN enabled"
    echo
  fi

  # Loop over all repos
  for REPO in "${REPOS[@]}"; do
    echo "📦 Processing repo: $REPO"

    # Clone if necessary
    pushd ~/git > /dev/null
    if [ ! -d "$REPO" ]; then
      echo "Cloning $REPO"
      git clone "git@github.com:$ORG/$REPO.git"
    fi
    pushd "$REPO" > /dev/null || exit

    # skip assessment if the PR already exists
    set +e
    pr_exists=$(gh pr view "$BRANCH_NAME" --json url | jq -r '.url')
    set -e
    if [ "x${pr_exists}" != "x" ]; then
      echo "🔁 PR already exists for $REPO: $pr_exists"
      echo
      continue
    fi

    DEFAULT_BRANCH=$(git remote show origin | awk '/HEAD branch/ {print $NF}')

    # Find all Chart.yaml files (could be in charts/, helm/, etc.)
    CHART_FILES=$(find . -type f -name Chart.yaml)

    UPDATED=false

    for CHART in $CHART_FILES; do
      echo "🔍 Checking $CHART"

      # Extract current version for "common" dependency (if exists)
      CURRENT_VERSION=$(yq '.dependencies[] | select(.name == "common") | .version' "$CHART")

      if [ -z "$CURRENT_VERSION" ]; then
        echo "   ⏭️  No 'common' dependency found, skipping"
        continue
      fi

      # Check against all FROM_VERSIONS
      for FROM in "${FROM_VERSIONS[@]}"; do
        if [[ "$CURRENT_VERSION" == "$FROM" ]]; then
          echo "   ✅ Match found: $CURRENT_VERSION → $TO_VERSION"

          make_branch

          if [ "${DRY_RUN}" == "true" ]; then
            echo "   DRY_RUN: new file contents:"
            yq -e ".dependencies[0].version = \"${TO_VERSION}\"" "$CHART"
          else
            yq -e -i ".dependencies[0].version = \"${TO_VERSION}\"" "$CHART"
          fi

          if [ "${DRY_RUN}" == "true" ]; then
            echo "   DRY_RUN: would have git-added ${CHART}"
          else
            git add "$CHART"
          fi
          UPDATED=true
          break
        fi
      done
    done

    # Only commit/push if any Chart.yaml was updated
    if [ "$UPDATED" = true ]; then
      if [ "${DRY_RUN}" == "true" ]; then
        echo "DRY_RUN: would have run 'git commit -m \"${COMMIT_MESSAGE}\"'"
        echo "DRY_RUN: would have run 'git push --set-upstream origin  \"${BRANCH_NAME}\"'"
        echo "DRY_RUN: would have run 'gh pr create --title \"$PR_TITLE\" --body \"$PR_BODY\" --base main'"
      else
        git commit -m "$COMMIT_MESSAGE"
        git push --set-upstream origin "$BRANCH_NAME"

        gh pr create --title "$PR_TITLE" --body "$PR_BODY" --base $DEFAULT_BRANCH || echo "⚠️ PR may already exist or failed"
      fi
    else
      echo "🟡 No chart updates needed in $REPO"
    fi

    popd > /dev/null
    echo
  done
  popd > /dev/null
}

parse_params "$@"
main
