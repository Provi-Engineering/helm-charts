# bats file_tags=tag:all, tag:deployments
setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load 'test_helper/bats-file/load'

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

# bats test_tags=tag:deployments-unquoted-accountid
@test "deployments: forces type to string when awsAccountId is unquoted" {
  helm template -f test/fixtures/deployments/badvalues-unquoted-accountid.yaml test/fixtures/deployments/ > "$TEST_TEMP_DIR/default_output.yaml"
  assert diff -ub test/expected_output/deployments.yaml "$TEST_TEMP_DIR/default_output.yaml"
}

# bats test_tags=tag:deployments-with-secrets
@test "deployments: renders ClusterExternalSecret if secrets are included" {
  run helm template -f test/fixtures/deployments/values-with-secrets.yaml test/fixtures/deployments/
  assert_output --partial 'kind: ClusterExternalSecret'
  assert_output --partial 'key: rds!cluster-1a123b45-6c78-901d-e234-f5678901a23b'
  assert_output --partial 'secretKey: MY_COOL_SECRET_1'
}

# bats test_tags=tag:pdb-min-available
@test "deployments: renders podDisruptionBudget if included" {
  run helm template -f test/fixtures/deployments/values-pdb-minAvailable.yaml test/fixtures/deployments/
  assert_output --partial 'kind: PodDisruptionBudget'
  assert_output --partial 'name: my-cool-app-web-pdb'
  assert_output --partial 'selector: my-cool-app-deployment-web'
  assert_output --partial 'minAvailable: 1' 
}

# bats test_tags=tag:pdb-max-unavailable
@test "deployments: renders podDisruptionBudget with maxUnavailable" {
  run helm template -f test/fixtures/deployments/values-pdb-maxUnavailable.yaml test/fixtures/deployments/
  assert_output --partial 'kind: PodDisruptionBudget'
  assert_output --partial 'maxUnavailable: 2' 
}

# bats test_tags=tag:pdb-min-avail-percent
@test "deployments: renders podDisruptionBudget with minAvailable as a percentage" {
  run helm template -f test/fixtures/deployments/values-pdb-minAvailPercent.yaml test/fixtures/deployments/
  assert_output --partial 'kind: PodDisruptionBudget'
  assert_output --partial 'minAvailable: 25%' 
}

# bats test_tags=tag:pdb-multi-deployment-rendering
@test "deployments: ensures a separate document between all deployments when PDBs are defined" {
  run helm template -f test/fixtures/deployments/values-multiple-deployments.yaml test/fixtures/deployments/
  refute_output --partial 'karpenter---'
  assert_output --partial 'maxUnavailable: 0'
}
