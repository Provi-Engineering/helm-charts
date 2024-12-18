# bats file_tags=tag:all, tag:autoscaler
setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load 'test_helper/bats-file/load'

  AWS_PROFILE=provi-development helm dep update test/fixtures/autoscaler &> /dev/null

  TEST_TEMP_DIR="$(temp_make)"
}

teardown() {
  temp_del "$TEST_TEMP_DIR"
}

# bats test_tags=tag:autoscaler-basic
@test "autoscaler: outputs a template" {
  run helm template -f test/fixtures/autoscaler/values-basic.yaml test/fixtures/autoscaler/
  assert_output --partial 'kind: HorizontalPodAutoscaler'
}

# bats test_tags=tag:autoscaler-basic
@test "autoscaler: matches expected output" {
  helm template -f test/fixtures/autoscaler/values-basic.yaml test/fixtures/autoscaler/ > "$TEST_TEMP_DIR/default_output.yaml"
  assert cmp -s test/expected_output/autoscaler.yaml "$TEST_TEMP_DIR/default_output.yaml"
}

# bats test_tags=tag:minReplicas-default
@test "autoscaler: if a minReplicas value is not provided, a defualt is used" {
  run helm template -f test/fixtures/autoscaler/values-default-minreplica.yaml test/fixtures/autoscaler/
  assert_output --partial 'minReplicas: 1'
}

# bats test_tags=tag:maxReplicas-default
@test "autoscaler: if a maxReplicas value is not provided, a defualt is used" {
  run helm template -f test/fixtures/autoscaler/values-default-maxreplica.yaml test/fixtures/autoscaler/
  assert_output --partial 'maxReplicas: 3'
}

# bats test_tags=tag:autoscaler-target-utilization
@test "autoscaler: overrides the averageUtilization value if provided" {
  run helm template -f test/fixtures/autoscaler/values-target-utilization.yaml test/fixtures/autoscaler/
  assert_output --partial 'averageUtilization: 95'
}

# bats test_tags=tag:autoscaler-memory-utilization
@test "autoscaler: cretes a memory resource utilization target if provided" {
  run helm template -f test/fixtures/autoscaler/values-memory.yaml test/fixtures/autoscaler/
  assert_output --partial 'name: cpu'
  assert_output --partial 'name: memory'
  assert_output --partial 'averageUtilization: 60'
  assert_output --partial 'averageUtilization: 50'
}
