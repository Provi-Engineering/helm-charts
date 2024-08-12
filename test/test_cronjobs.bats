# bats file_tags=tag:all, tag:cronjobs
setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load 'test_helper/bats-file/load'

  AWS_PROFILE=provi-development helm dep update test/fixtures/cronjobs &> /dev/null

  TEST_TEMP_DIR="$(temp_make)"
}

teardown() {
  temp_del "$TEST_TEMP_DIR"
}

# bats test_tags=tag:cronjobs-basic
@test "cronjobs: outputs a template" {
  run helm template -f test/fixtures/cronjobs/values-basic.yaml test/fixtures/cronjobs/
  assert_output --partial 'kind: CronJob'
  assert_output --partial 'test.annotation: hello-test-world'
	assert_output --partial 'test.override.annotation: hello-override-world'
	assert_output --partial 'testOverrideLabel: hello-override-world'
  assert_output --partial 'name: test-cronjobs'
  assert_output --partial 'nodeAffinity'
  assert_output --partial 'schedule: "0 * * * *"'
}

# bats test_tags=tag:cronjobs-basic
@test "cronjobs: matches expected output" {
  helm template -f test/fixtures/cronjobs/values-basic.yaml test/fixtures/cronjobs/ > "$TEST_TEMP_DIR/default_output.yaml"
  assert diff -ub test/expected_output/cronjobs.yaml "$TEST_TEMP_DIR/default_output.yaml"
}

# bats test_tags=tag:cronjobs-global-serviceaccount
@test "cronjobs: includes service account if specified in the global section" {
  helm template -f test/fixtures/cronjobs/values-global-serviceaccount.yaml test/fixtures/cronjobs/ > "$TEST_TEMP_DIR/global_serviceaccount_output.yaml"
  assert diff -ub test/expected_output/cronjobs-global-serviceaccount.yaml "$TEST_TEMP_DIR/global_serviceaccount_output.yaml"
}

# bats test_tags=tag:cronjobs-serviceaccount
@test "cronjobs: includes service account if specified" {
  skip "this should work, but it doesn't -- in the future, look into lines 11-15 in _cronjob.yaml.tpl"
  helm template -f test/fixtures/cronjobs/values-serviceaccount.yaml test/fixtures/cronjobs/ > "$TEST_TEMP_DIR/serviceaccount_output.yaml"
  assert diff -ub test/expected_output/values-serviceaccount.yaml "$TEST_TEMP_DIR/serviceaccount_output.yaml"
}

# bats test_tags=tag:cronjobs-suspend
@test "cronjobs: suspends job if disabled is true" {
  run helm template -f test/fixtures/cronjobs/values-suspend.yaml test/fixtures/cronjobs/
  assert_output --partial 'suspend: true'
}

# bats test_tags=tag:cronjobs-concurrency
@test "cronjobs: overrides default concurrencyPolicy" {
  run helm template -f test/fixtures/cronjobs/values-concurrency.yaml test/fixtures/cronjobs/
  assert_output --partial 'concurrencyPolicy: Allow'
}

# bats test_tags=tag:cronjobs-failed-limit
@test "cronjobs: overrides default failedJobsHistoryLimit" {
  run helm template -f test/fixtures/cronjobs/values-failed-limit.yaml test/fixtures/cronjobs/
  assert_output --partial 'failedJobsHistoryLimit: 10'
}

# bats test_tags=tag:cronjobs-success-limit
@test "cronjobs: overrides default successfulJobsHistoryLimit" {
  run helm template -f test/fixtures/cronjobs/values-success-limit.yaml test/fixtures/cronjobs/
  assert_output --partial 'successfulJobsHistoryLimit: 10'
}

# bats test_tags=tag:cronjobs-starting-deadline
@test "cronjobs: adds startingDeadlineSeconds if defined" {
  run helm template -f test/fixtures/cronjobs/values-starting-deadline.yaml test/fixtures/cronjobs/
  assert_output --partial 'startingDeadlineSeconds: 10'
}

# bats test_tags=tag:cronjobs-no-schedule
@test "cronjobs: fails when no scheudle is defined" {
  run helm template -f test/fixtures/cronjobs/badvalues-no-schedule.yaml test/fixtures/cronjobs/
	assert_failure
  assert_output --partial 'You must specify a schedule for cronJob [scheduler]'
}

# bats test_tags=tag:cronjobs-timezone
@test "cronjobs: includes timeZone if specified" {
  run helm template -f test/fixtures/cronjobs/values-timezone.yaml test/fixtures/cronjobs/
  assert_output --partial 'timeZone: US/Central'
}
