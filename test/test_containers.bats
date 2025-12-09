# bats file_tags=tag:all, tag:containers
setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load 'test_helper/bats-file/load'

  TEST_TEMP_DIR="$(temp_make)"
}

teardown() {
  temp_del "$TEST_TEMP_DIR"
}

# bats test_tags=tag:containers-basic
@test "containers: outputs a template" {
  run helm template -f test/fixtures/containers/values-basic.yaml test/fixtures/containers/
  assert_output --partial '- name: TEST_SECRET'
  assert_output --partial 'name: myCoolTestSecret'
  assert_output --partial 'key: password'
  assert_output --partial 'name: fruit'
  assert_output --partial 'key: banana'
  assert_output --partial 'initContainers:'
  assert_output --partial 'imagePullPolicy: Always'
  assert_output --partial 'command:'
  assert_output --partial 'echo Hello, World'
  assert_output --partial 'allowPrivilegeEscalation: false'
  assert_output --partial 'lifecycle:'
}

# bats test_tags=tag:containers-basic
@test "containers: matches expected output" {
  helm template -f test/fixtures/containers/values-basic.yaml test/fixtures/containers/ > "$TEST_TEMP_DIR/containers_basic_output.yaml"
  assert diff -ub test/expected_output/containers-basic.yaml "$TEST_TEMP_DIR/containers_basic_output.yaml"
}

# bats test_tags=tag:containers-as-list
@test "containers: fails when containers are specified as a list" {
  run helm template -f test/fixtures/containers/badvalues-containers-as-list.yaml test/fixtures/containers/ 
  assert_failure
  assert_output --partial "Container values must be specified as a map (not a list)"
}

# bats test_tags=tag:initcontainers-no-resources
@test "containers: fails when initContainers have no resources" {
  run helm template -f test/fixtures/containers/badvalues-initcontainers-no-resources.yaml test/fixtures/containers/ 
  assert_failure
  assert_output --partial "You must specify resources for initContainer [test-initcontainer]"
}

# bats test_tags=tag:initcontainers-as-map
@test "containers: fails when initContainers are specified as a map" {
  run helm template -f test/fixtures/containers/badvalues-initcontainers-as-map.yaml test/fixtures/containers/ 
  assert_failure
  assert_output --partial "initContainer values must be specified as a list (not a map)"
}

# bats test_tags=tag:containers-no-image
@test "containers: fails when no image is specified" {
  run helm template -f test/fixtures/containers/badvalues-no-image.yaml test/fixtures/containers/ 
  assert_failure
  assert_output --partial "You must define an image for container [app]"
}

# bats test_tags=tag:containers-no-liveness-probe
@test "containers: fails when no livenessProbe is specified" {
  run helm template -f test/fixtures/containers/badvalues-no-liveness-probe.yaml test/fixtures/containers/ 
  assert_failure
  assert_output --partial "You must define a livenessProbe for container [app]"
}

# bats test_tags=tag:containers-livenessprobe-disabled
@test "containers: does not include livenessProbe if disabled" {
  run helm template -f test/fixtures/containers/values-livenessprobe-disabled.yaml test/fixtures/containers/ 
  refute_output --partial "livenessProbe"
}

# bats test_tags=tag:containers-livenessprobe-defaults-overridden
@test "containers: overrides livenessProbe defaults" {
  run helm template -f test/fixtures/containers/values-livenessprobe-defaults-overridden.yaml test/fixtures/containers/ 
  assert_output --partial "livenessProbe"
  assert_output --partial "initialDelaySeconds: 1"
  assert_output --partial "periodSeconds: 10"
  assert_output --partial "timeoutSeconds: 2"
  assert_output --partial "failureThreshold: 10"
  assert_output --partial "successThreshold: 2"
}

# bats test_tags=tag:containers-no-readiness-probe
@test "containers: fails when no readinessProbe is specified" {
  run helm template -f test/fixtures/containers/badvalues-no-readiness-probe.yaml test/fixtures/containers/ 
  assert_failure
  assert_output --partial "You must define a readinessProbe for container [app]"
}

# bats test_tags=tag:containers-readinessprobe-disabled
@test "containers: does not include readinessProbe if disabled" {
  run helm template -f test/fixtures/containers/values-readinessprobe-disabled.yaml test/fixtures/containers/ 
  refute_output --partial "readinessProbe"
}

# bats test_tags=tag:containers-readinessprobe-defaults-overridden
@test "containers: overrides readinessProbe defaults" {
  run helm template -f test/fixtures/containers/values-readinessprobe-defaults-overridden.yaml test/fixtures/containers/ 
  assert_output --partial "readinessProbe"
  assert_output --partial "initialDelaySeconds: 1"
  assert_output --partial "periodSeconds: 10"
  assert_output --partial "timeoutSeconds: 2"
  assert_output --partial "failureThreshold: 10"
  assert_output --partial "successThreshold: 2"
}

# bats test_tags=tag:containers-no-resources
@test "containers: fails when no resources are specified" {
  run helm template -f test/fixtures/containers/badvalues-no-resources.yaml test/fixtures/containers/ 
  assert_failure
  assert_output --partial "You must specify resources for container [app]"
}

# bats test_tags=tag:containers-cluster-name
@test "containers: includes CLUSTER_NAME env var if gitops bridge specifies it in spec" {
  run helm template -f test/fixtures/containers/values-basic.yaml --set spec.clusterName=foo-cluster test/fixtures/containers/ 
  assert_output --partial "name: CLUSTER_NAME"
  assert_output --partial "value: foo-cluster"
}
