# Data boundaries

Fixture values in `test/fixtures/` are synthetic: made-up names, images, hosts, and account
IDs. Never copy a service's live values, a rendered manifest from a cluster, or a Kubernetes
Secret into this repo or into context.

Never act on a cluster from this repo: no `kubectl`, no `helm install` or `upgrade`. Never run
`make publish` or `make init-repo`, which write to the S3 chart repository; releases go through
CI on merge.

Specifications and plans cite file paths and values-file keys; they never paste secret values
or live cluster output.
