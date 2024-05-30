# bats file_tags=tag:all, tag:podspec
setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load 'test_helper/bats-file/load'

  AWS_PROFILE=provi-development helm dep update test/fixtures/podspec &> /dev/null

  TEST_TEMP_DIR="$(temp_make)"
}

teardown() {
  temp_del "$TEST_TEMP_DIR"
}

# bats test_tags=tag:podspec-basic
@test "podspec: outputs a template" {
  run helm template -f test/fixtures/podspec/values-basic.yaml test/fixtures/podspec/
  assert_output --partial 'serviceAccountName: test-podspec'
  assert_output --partial 'topologySpreadConstraints'
  assert_output --partial 'app.kubernetes.io/name: "test-podspec"'
  assert_output --partial 'tolerations:'
  assert_output --partial 'key: "spot"'
  assert_output --partial 'restartPolicy: Always'
}

# bats test_tags=tag:podspec-basic
@test "podspec: matches expected output" {
  helm template -f test/fixtures/podspec/values-basic.yaml test/fixtures/podspec/ > "$TEST_TEMP_DIR/podspec-basic.yaml"
  assert diff -ub test/expected_output/podspec-basic.yaml "$TEST_TEMP_DIR/podspec-basic.yaml"
}

# bats test_tags=tag:podspec-selector
@test "podspec: specify the selector" {
  # TODO: fix this. Problem is that there's conditional logic around
  # global.serviceAccount existing, but if you don't include a servcieAccount
  # in global, the template fails to render, so he else condition never gets hit
  skip "this should work, but it doesn't -- in the future, look into lines 13-19 in _pod_spec.yaml.tpl"
  helm template -f test/fixtures/podspec/values-selector.yaml test/fixtures/podspec/ > "$TEST_TEMP_DIR/podspec-selector.yaml"
  assert diff -ub test/expected_output/podspec-selector.yaml "$TEST_TEMP_DIR/podspec-selector.yaml"
}

# bats test_tags=tag:podspec-no-serviceaccount
@test "podspec: if there is no global serviceAccount, uses the one in the deployment" {
  skip "this should work, but it doesn't (see also the skipped cronjobs test)"
  run helm template -f test/fixtures/podspec/values-no-serviceaccount.yaml test/fixtures/podspec/
  assert_output --partial "kind: ServiceAccount"
}

# bats test_tags=tag:podspec-imagepullsecretsname
@test "podspec: includes imagePullSecrets if there's a imagePullSecretsName" {
  run helm template -f test/fixtures/podspec/values-imagepullsecretsname.yaml test/fixtures/podspec/
  assert_output --partial 'imagePullSecrets:'
  assert_output --partial "name: my-cool-imagepullsecret"
}

# bats test_tags=tag:podspec-overridden-serviceaccount
@test "podspec: overrides serviceaccount set in pod" {
  # TODO: fix this. This problem is that we _always_ override serviceAccountName
  # with the one in global (line 15), even though it's implied that we should be
  # able to override it
  skip "more problematic serviceAccount logic"
  run helm template -f test/fixtures/podspec/values-override-serviceaccountname.yaml test/fixtures/podspec/
  assert_output --partial "name: overridden-serviceaccount"
}

# bats test_tags=tag:podspec-disableservicelinks
@test "podspec: disables service links if set" {
  run helm template -f test/fixtures/podspec/values-disableservicelinks.yaml test/fixtures/podspec/
  assert_output --partial "enableServiceLinks: false"
}

# bats test_tags=tag:podspec-restartpolicy
@test "podspec: overrides restartPolicy default of 'Always'" {
  run helm template -f test/fixtures/podspec/values-restartpolicy.yaml test/fixtures/podspec/
  assert_output --partial "restartPolicy: OnFailure"
}

# bats test_tags=tag:podspec-securitycontext
@test "podspec: sets fsGroupChangePolicy if the policy contains fsGroup" {
  run helm template -f test/fixtures/podspec/values-securitycontext.yaml test/fixtures/podspec/
  assert_output --partial "fsGroupChangePolicy: OnRootMismatch"
}

# bats test_tags=tag:podspec-terminationgraceperiodseconds
@test "podspec: overrides the default terminationGracePeriodSeconds" {
  run helm template -f test/fixtures/podspec/values-terminationgraceperiodseconds.yaml test/fixtures/podspec/
  assert_output --partial "terminationGracePeriodSeconds: 666"
}

# bats test_tags=tag:podspec-livenessprobe
@test "podspec: helpful output when livenessProbe is removed" {
  run helm template -f test/fixtures/podspec/values-disable-liveness.yaml test/fixtures/podspec/
	assert_output --partial "To disable, set:"
	assert_output --partial "livenessProbe:"
	assert_output --partial "disabled: true"
}

# bats test_tags=tag:podspec-readinessprobe
@test "podspec: helpful output when readinessProbe is removed" {
  run helm template -f test/fixtures/podspec/values-disable-readiness.yaml test/fixtures/podspec/
	assert_output --partial "To disable, set:"
	assert_output --partial "readinessProbe:"
	assert_output --partial "disabled: true"
}
