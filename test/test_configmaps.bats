# bats file_tags=tag:all, tag:configmaps
setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load 'test_helper/bats-file/load'

  AWS_PROFILE=provi-development helm dep update test/fixtures/configmaps &> /dev/null

  TEST_TEMP_DIR="$(temp_make)"
}

teardown() {
  temp_del "$TEST_TEMP_DIR"
}

# bats test_tags=tag:basic
@test "configmaps: outputs a template" {
  run helm template -f test/fixtures/configmaps/values-basic.yaml test/fixtures/configmaps/
  assert_output --partial 'kind: ConfigMap'
  assert_output --partial 'provi.repository: https://github.com/example/repo'
  assert_output --partial 'foo: "bar"'
  assert_output --partial 'number: "1"'
  assert_output --partial 'properties: "fruit.type=banana\n"'
}

# bats test_tags=tag:basic
@test "configmaps: matches expected output" {
  helm template -f test/fixtures/configmaps/values-basic.yaml test/fixtures/configmaps/ > "$TEST_TEMP_DIR/default_output.yaml"
  assert cmp -s test/expected_output/configmaps.yaml "$TEST_TEMP_DIR/default_output.yaml"
}

# bats test_tags=tag:file-template
@test "configmaps: file templating works" {
  run helm template -f test/fixtures/configmaps/values-file-template.yaml test/fixtures/configmaps/
  assert_output --partial 'foo: baz'
}

# bats test_tags=tag:inline-template
@test "configmaps: inline templating works" {
  run helm template -f test/fixtures/configmaps/values-inline-template.yaml test/fixtures/configmaps/
  assert_output --partial 'foo: bif'
}

# bats test_tags=tag:multi-template
@test "configmaps: multiple templates works" {
  run helm template -f test/fixtures/configmaps/values-multi-template.yaml test/fixtures/configmaps/
  assert_output --partial 'foo=banana'
  assert_output --partial 'bar=apple'
}

# bats test_tags=tag:multi-template-inline
@test "configmaps: inline multiple templates works" {
  run helm template -f test/fixtures/configmaps/values-multi-inline-template.yaml test/fixtures/configmaps/
  assert_output --partial 'foo=mango'
  assert_output --partial 'bar=papaya'
}

# bats test_tags=tag:data-inline-file
@test "configmaps: dumps contents of a file" {
  run helm template -f test/fixtures/configmaps/values-data-inline-file.yaml test/fixtures/configmaps/
  assert_output --partial 'properties: |-'
  assert_output --partial 'fruit.type=lemon'
  assert_output --partial 'foo: "bar"'
}

# bats test_tags=tag:data-inline-json-file
@test "configmaps: dumps contents of a json file" {
  run helm template -f test/fixtures/configmaps/values-data-inline-json-file.yaml test/fixtures/configmaps/
  assert_output --partial 'properties: |-'
  assert_output --partial '"fruit": {'
  assert_output --partial '"type": "kiwi"'
  assert_output --partial 'foo: "bar"'
}

# bats test_tags=tag:data-inline-yaml-file
@test "configmaps: dumps contents of a yaml file" {
  run helm template -f test/fixtures/configmaps/values-data-inline-yaml-file.yaml test/fixtures/configmaps/
  assert_output --partial 'properties.yaml: |-'
  assert_output --partial 'fruit:'
  assert_output --partial 'type: orange'
  assert_output --partial 'foo: "bar"'
}
