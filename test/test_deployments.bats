# bats file_tags=tag:all, tag:deployments
setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load 'test_helper/bats-file/load'

  AWS_PROFILE=provi-development helm dep update test/fixtures/deployments &> /dev/null

  TEST_TEMP_DIR="$(temp_make)"
}

teardown() {
  temp_del "$TEST_TEMP_DIR"
}

# bats test_tags=tag:deployments-basic
@test "deployments: outputs a template" {
  run helm template -f test/fixtures/deployments/values-basic.yaml test/fixtures/deployments/
  assert_output --partial 'kind: Deployment'
  assert_output --partial 'nodeAffinity'
  assert_output --partial 'memory: 256Mi'
  assert_output --partial '- name: RAILS_ENV'
  refute_output --partial 'arn:aws:iam::<nil>'
}

# bats test_tags=tag:deployments-basic
@test "deployments: matches expected output" {
  helm template -f test/fixtures/deployments/values-basic.yaml test/fixtures/deployments/ > "$TEST_TEMP_DIR/default_output.yaml"
  assert diff -ub test/expected_output/deployments.yaml "$TEST_TEMP_DIR/default_output.yaml"
}

# bats test_tags=tag:deployments-selector
@test "deployments: specify the selector" {
  helm template -f test/fixtures/deployments/values-selector.yaml test/fixtures/deployments/ > "$TEST_TEMP_DIR/deployments-selector.yaml"
  assert diff -ub test/expected_output/deployments-selector.yaml "$TEST_TEMP_DIR/deployments-selector.yaml"
}

# bats test_tags=tag:deployments-no-serviceaccount
@test "deployments: if there is no global serviceAccount, uses the one in the deployment" {
  skip "this should work, but it doesn't (see also the skipped cronjobs test)"
  run helm template -f test/fixtures/deployments/values-no-serviceaccount.yaml test/fixtures/deployments/
  assert_output --partial "kind: ServiceAccount"
}

# bats test_tags=tag:deployments-serviceaccount-role
@test "deployments: adds serviceAccount role if specified" {
  run helm template -f test/fixtures/deployments/values-serviceaccount-role.yaml test/fixtures/deployments/
  assert_output --partial 'eks.amazonaws.com/role-arn: "arn:aws:iam::123456789:role/my-cool-role'
}
