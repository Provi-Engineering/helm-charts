#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <common_chart_version>" >&2
  exit 1
fi

if ! command -v helm >/dev/null 2>&1; then
  echo "Error: helm is not installed or not in PATH" >&2
  exit 1
fi

COMMON_VERSION="$1"
FIXTURES_ROOT="test/fixtures"

if [[ ! -d "$FIXTURES_ROOT" ]]; then
  echo "Error: $FIXTURES_ROOT directory not found" >&2
  exit 1
fi

for chart_dir in "$FIXTURES_ROOT"/*/; do
  [[ -d "$chart_dir" ]] || continue

  chart_file="${chart_dir}Chart.yaml"
  lock_file="${chart_dir}Chart.lock"

  # Remove legacy symlinks so we can write real files
  if [[ -L "$chart_file" ]]; then
    rm "$chart_file"
  fi
  if [[ -L "$lock_file" ]]; then
    rm "$lock_file"
  fi

  cat > "$chart_file" <<EOF
apiVersion: v2
name: my-cool-app
description: Defaults chart for testing
type: application
version: 1.0.0
dependencies:
  - name: common
    repository: file://../../../charts/common
    version: "$COMMON_VERSION"
EOF

  echo "Running helm dependency update in ${chart_dir}"
  # Equivalent to 'helm dep up' in modern Helm (aka 'helm up')
  (cd "$chart_dir" && helm dependency update)
done
