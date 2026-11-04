#!/usr/bin/env bash
# Run the bats suite one file per process, in parallel, and fail unless every
# selected test ran and passed. Selected by TAG (default all); BATS overrides
# the bats binary (for verification only).

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

tag="${TAG:-all}"
bats="${BATS:-test/bats/bin/bats}"

expected=$("$bats" --count --filter-tags "tag:${tag}" test/)
if [[ "$expected" -eq 0 ]]; then
  echo "Error: no tests have the tag '${tag}'" >&2
  exit 1
fi

run_dir=$(mktemp -d)
mkdir "$run_dir/tmp" "$run_dir/out"

cores=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)

export RUN_DIR="$run_dir" BATS_BIN="$bats" BATS_TAG="$tag"
xargs_status=0
printf '%s\0' test/test_*.bats | xargs -0 -n 1 -P "$cores" bash -c '
  file=$1
  TMPDIR="$RUN_DIR/tmp" "$BATS_BIN" --no-tempdir-cleanup \
    --filter-tags "tag:${BATS_TAG}" "$file" > "$RUN_DIR/out/$(basename "$file").tap" 2>&1
' _ || xargs_status=$?

ran=0
failed=0
failed_files=()
passed_files=()
for out in "$run_dir"/out/*.tap; do
  ok=$(grep -c '^ok ' "$out" || true)
  not_ok=$(grep -c '^not ok ' "$out" || true)
  ran=$((ran + ok + not_ok))
  failed=$((failed + not_ok))
  if [[ "$not_ok" -gt 0 ]]; then
    failed_files+=("$out")
  else
    passed_files+=("$out")
  fi
done

# Passing files first, failing files last, so a failure's output ends the log.
for out in ${passed_files[@]+"${passed_files[@]}"} ${failed_files[@]+"${failed_files[@]}"}; do
  # A file with no selected tests prints only its empty plan.
  [[ "$(grep -v '^BATS_RUN_TMPDIR: ' "$out")" == "1..0" ]] && continue
  echo "# $(basename "$out" .tap)"
  grep -v '^BATS_RUN_TMPDIR: ' "$out" || true
done

echo
echo "Tests: ${ran} of ${expected} ran, ${failed} failed (tag:${tag})"

if [[ "$xargs_status" -ne 0 || "$failed" -ne 0 || "$ran" -ne "$expected" ]]; then
  [[ "$ran" -ne "$expected" ]] && echo "Error: expected ${expected} tests, ran ${ran}" >&2
  [[ "$xargs_status" -ne 0 ]] && echo "Error: a bats process exited non-zero (xargs status ${xargs_status})" >&2
  echo "Temp dirs kept (N.name names test N; directory N holds its files):" >&2
  for out in ${failed_files[@]+"${failed_files[@]}"}; do
    sed -n 's|^BATS_RUN_TMPDIR: \(.*\)$|  \1/test/|p' "$out" >&2
  done
  echo "Run directory kept: ${run_dir}" >&2
  exit 1
fi

rm -rf "$run_dir"
