# bats file_tags=tag:all, tag:jobs
setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load 'test_helper/bats-file/load'

  TEST_TEMP_DIR="$(temp_make)"
}

teardown() {
  temp_del "$TEST_TEMP_DIR"
}

# bats test_tags=tag:basic
@test "jobs: outputs a template" {
  run helm template -f test/fixtures/jobs/values-basic.yaml test/fixtures/jobs/
  assert_output --partial 'kind: Job'
  assert_output --partial 'helm.sh/hook: pre-install,pre-upgrade'
  assert_output --partial 'podAntiAffinity'
}

# bats test_tags=tag:basic
@test "jobs: matches expected output" {
  helm template -f test/fixtures/jobs/values-basic.yaml test/fixtures/jobs/ > "$TEST_TEMP_DIR/default_output.yaml"
  assert diff -ub test/expected_output/jobs.yaml "$TEST_TEMP_DIR/default_output.yaml"
}

# bats test_tags=tag:backofflimit
@test "jobs: backoffLimit gets set as expected" {
  run helm template -f test/fixtures/jobs/values-backofflimit.yaml test/fixtures/jobs/
  assert_output --partial 'backoffLimit: 2'
}

# bats test_tags=tag:completions
@test "jobs: completions gets set as expected" {
  run helm template -f test/fixtures/jobs/values-completions.yaml test/fixtures/jobs/
  assert_output --partial 'completions: 2'
}

# bats test_tags=tag:parallelism
@test "jobs: parallelism gets set as expected" {
  run helm template -f test/fixtures/jobs/values-parallelism.yaml test/fixtures/jobs/
  assert_output --partial 'parallelism: 2'
}

# bats test_tags=tag:activedeadlineseconds
@test "jobs: activeDeadlineSeconds gets set as expected" {
  run helm template -f test/fixtures/jobs/values-activedeadlineseconds.yaml test/fixtures/jobs/
  assert_output --partial 'activeDeadlineSeconds: 5'
}

# bats test_tags=tag:restartpolicy
@test "jobs: restartPolicy gets overridden" {
  run helm template -f test/fixtures/jobs/values-restartpolicy.yaml test/fixtures/jobs/
  assert_output --partial 'restartPolicy: Never'
  refute_output --partial 'restartPolicy: Always'
}

# bats test_tags=tag:healthcheck
@test "jobs: livenessProbe and readinessProbe get overridden" {
  run helm template -f test/fixtures/jobs/values-healthcheck.yaml test/fixtures/jobs/
  refute_output --partial 'livenessProbe'
  refute_output --partial 'readinessProbe'
}

# bats test_tags=tag:jobs-serviceaccount
@test "jobs: uses job serviceAccount if there is no global one" {
  skip "this should work, but it doesn't (see skipped test in cronjobs and deployments tests)"
  run helm template -f test/fixtures/jobs/values-serviceaccount.yaml test/fixtures/jobs/
  assert_output --partial 'kind: ServiceAccount'
}
