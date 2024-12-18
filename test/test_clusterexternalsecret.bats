# bats file_tags=tag:all, tag:clusterexternalsecret
setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load 'test_helper/bats-file/load'

  AWS_PROFILE=provi-development helm dep update test/fixtures/clusterexternalsecret &> /dev/null

  TEST_TEMP_DIR="$(temp_make)"
}

teardown() {
  temp_del "$TEST_TEMP_DIR"
}

# bats test_tags=tag:basic
@test "clusterexternalsecret: outputs a template" {
  run helm template -f test/fixtures/clusterexternalsecret/values-basic.yaml test/fixtures/clusterexternalsecret/
  assert_output --partial 'kind: ClusterExternalSecret'
  assert_output --partial 'helm.sh/hook: pre-install,pre-upgrade'
  assert_output --partial 'argocd.argoproj.io/hook: PreSync'
}

# bats test_tags=tag:basic
@test "clusterexternalsecret: matches expected output" {
  helm template -f test/fixtures/clusterexternalsecret/values-basic.yaml test/fixtures/clusterexternalsecret/ > "$TEST_TEMP_DIR/default_output.yaml"
  assert diff -ub test/expected_output/clusterexternalsecret-basic.yaml "$TEST_TEMP_DIR/default_output.yaml"
}
