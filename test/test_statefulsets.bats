# bats file_tags=tag:all, tag:statefulsets
setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load 'test_helper/bats-file/load'

  TEST_TEMP_DIR="$(temp_make)"
}

teardown() {
  temp_del "$TEST_TEMP_DIR"
}

@test "statefulsets: outputs a template" {
  run helm template -f test/fixtures/statefulsets/values-basic.yaml test/fixtures/statefulsets/
  assert_output --partial 'kind: StatefulSet'
  assert_output --partial 'app.kubernetes.io/name: "test-statefulsets"'
  assert_output --partial 'volumeClaimTemplates'
}

@test "statefulsets: matches expected output" {
  helm template -f test/fixtures/statefulsets/values-basic.yaml test/fixtures/statefulsets/ > "$TEST_TEMP_DIR/default_output.yaml"
  assert diff -ub test/expected_output/statefulsets.yaml "$TEST_TEMP_DIR/default_output.yaml"
}
