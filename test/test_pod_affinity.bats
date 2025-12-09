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
