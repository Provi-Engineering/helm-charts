PROFILE := ${AWS_PROFILE}
REPO_BUCKET := ${HELM_REPO_BUCKET}
TAG ?= all

.PHONY: package
package:
	helm package common -d _repo

.PHONY: publish
publish:
	AWS_PROFILE=${PROFILE} helm s3 push --force _repo/common-*.tgz provi

.PHONY: init-repo
init-repo:
	AWS_PROFILE=${PROFILE} helm s3 init s3://${REPO_BUCKET}
	AWS_PROFILE=${PROFILE} helm repo add provi s3://${REPO_BUCKET}

# hint: run single tests like this:
# test/bats/bin/bats --filter-tags tag:nodns test/
.PHONY: test
test:
	BATSLIB_TEMP_PRESERVE_ON_FAILURE=1 AWS_PROFILE=${PROFILE} test/bats/bin/bats --filter-tags tag:${TAG} test/
