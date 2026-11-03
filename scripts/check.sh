#!/usr/bin/env bash
# Run the chart tests the way CI does, then restore the fixture charts that
# update-fixture-charts.sh rewrites, so a run leaves the tree as it found it.

set -euo pipefail

helm_version=$(helm version --short)
if [[ "$helm_version" != v4.* ]]; then
  echo "Error: helm 4 required (CI pins v4.3.1); found ${helm_version}" >&2
  exit 1
fi

if [[ ! -x test/bats/bin/bats ]]; then
  echo "Error: test/bats is missing; run make install first" >&2
  exit 1
fi

snapshot=$(mktemp -d)
tar -cf "$snapshot/fixtures.tar" test/fixtures/*/Chart.yaml test/fixtures/*/Chart.lock

restore_fixtures() {
  tar -xf "$snapshot/fixtures.tar"
  rm -rf "$snapshot"
}
trap restore_fixtures EXIT

helm dependency build charts/common
bash scripts/update-fixture-charts.sh "$(awk -F': ' '/^version:/ {print $2}' charts/common/Chart.yaml)"
make test
