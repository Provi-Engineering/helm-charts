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
  assert_output --partial 'karpenter.sh/controller'
}

# bats test_tags=tag:affinity-basic
@test "affinity: matches expected output" {
  helm template -f test/fixtures/affinity/values-basic.yaml test/fixtures/affinity/ > "$TEST_TEMP_DIR/affinity_output.yaml"
  assert diff -ub test/expected_output/affinity.yaml "$TEST_TEMP_DIR/affinity_output.yaml"
}

# bats test_tags=tag:affinity-override
@test "affinity: allows overriding the anti-affinity label" {
  run helm template -f test/fixtures/affinity/values-anti-affinity-overrides.yaml test/fixtures/affinity/
  assert_output --partial 'my-cool-key'
  assert_output --partial '- foo'
}

# bats test_tags=tag:affinity-disabled
@test "affinity: allows disabling automatic anti-affinity" {
  run helm template -f test/fixtures/affinity/values-anti-affinity-disabled.yaml test/fixtures/affinity/
  refute_output --partial 'podAntiAffinity'
}
