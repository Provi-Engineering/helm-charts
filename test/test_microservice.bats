# bats file_tags=tag:all, tag:microservice
setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load 'test_helper/bats-file/load'

  TEST_TEMP_DIR="$(temp_make)"
}

teardown() {
  temp_del "$TEST_TEMP_DIR"
}

# bats test_tags=tag:microservice-basic
@test "microservice: outputs a template" {
  run helm template -f test/fixtures/microservice/values-basic.yaml test/fixtures/microservice/
  assert_output --partial 'app.kubernetes.io/name: "dummy"'
  assert_output --partial 'kind: ServiceAccount'
  assert_output --partial 'kind: Deployment'
  assert_output --partial 'kind: StatefulSet'
  assert_output --partial 'kind: ConfigMap'
  assert_output --partial 'kind: Job'
  assert_output --partial 'kind: CronJob'
  assert_output --partial 'kind: Ingress'
}

# bats test_tags=tag:microservice-basic
@test "microservice: matches expected output" {
  helm template -f test/fixtures/microservice/values-basic.yaml test/fixtures/microservice/ > "$TEST_TEMP_DIR/microservice_output.yaml"
  assert diff -ub test/expected_output/microservice.yaml "$TEST_TEMP_DIR/microservice_output.yaml"
}

# bats test_tags=tag:microservice-no-global
@test "microservice: fails when no global section is defined" {
  run helm template -f test/fixtures/microservice/badvalues-noglobal.yaml test/fixtures/microservice/ 
  assert_failure
  assert_output --partial "You must define the global annotation"
}

# bats test_tags=tag:microservice-no-labels
@test "microservice: fails when no global labels are defined" {
  run helm template -f test/fixtures/microservice/badvalues-nolabels.yaml test/fixtures/microservice/ 
  assert_failure
  assert_output --partial "You must define global labels"
}
