# bats file_tags=tag:all, tag:affinity
setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load 'test_helper/bats-file/load'

  TEST_TEMP_DIR="$(temp_make)"
}

teardown() {
  temp_del "$TEST_TEMP_DIR"
}

# bats test_tags=tag:affinity-basic
@test "affinity: outputs a template" {
  run helm template -f test/fixtures/affinity/values-basic.yaml test/fixtures/affinity/
  assert_output --partial 'key: foo'
  assert_output --partial 'key: type'
  assert_output --partial '- testaffinity'
}

# bats test_tags=tag:affinity-basic
@test "affinity: matches expected output" {
  helm template -f test/fixtures/affinity/values-basic.yaml test/fixtures/affinity/ > "$TEST_TEMP_DIR/affinity_output.yaml"
  assert diff -ub test/expected_output/affinity.yaml "$TEST_TEMP_DIR/affinity_output.yaml"
}

# bats test_tags=tag:affinity-zone-only
@test "affinity: hostname false renders only the zone spread" {
  run helm template -f test/fixtures/affinity/values-basic.yaml --set deployments.web.pod.topologySpreadConstraints.hostname=false test/fixtures/affinity/
  assert_success
  assert_output --partial 'topologyKey: topology.kubernetes.io/zone'
  refute_output --partial 'topologyKey: kubernetes.io/hostname'
}

# bats test_tags=tag:affinity-zone-only
@test "affinity: hostname set as the string false renders only the zone spread" {
  run helm template -f test/fixtures/affinity/values-basic.yaml --set-string deployments.web.pod.topologySpreadConstraints.hostname=false test/fixtures/affinity/
  assert_success
  refute_output --partial 'topologyKey: kubernetes.io/hostname'
}

# bats test_tags=tag:affinity-zone-only
@test "affinity: hostname true or blank keeps the hostname spread" {
  for value in true null; do
    run helm template -f test/fixtures/affinity/values-basic.yaml --set deployments.web.pod.topologySpreadConstraints.hostname=$value test/fixtures/affinity/
    assert_success
    assert_output --partial 'topologyKey: kubernetes.io/hostname'
  done
}
