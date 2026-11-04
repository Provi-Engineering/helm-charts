# Helm Charts

This repository contains Provi's Helm charts

## Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

  helm repo add provi https://provi-engineering.github.io/helm-charts

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo
provi` to see the charts.

## Development

See [Testing](#testing) for running the chart's tests.

### Releasing

To release:
* Update the `CHANGELOG.md`
* Update the version in `common/Chart.yaml`
* Run `. scripts/update-fixture-charts.sh <version>` (where `<version>` is the version you've updated to
* PR your change
* Merge

Github actions will tag and deploy the chart.

The chart will be accessible in two ways:
* via `helm repo add s3://provi-helm-charts` if you're using the [Helm s3 plugin](https://github.com/hypnoglow/helm-s3)
* via https://provi-engineering.github.io/helm-charts/

## Common Microservice

Common microservice is a chart that abstracts away majority of boilerplate helm
code for deploying microservices.

Please check out [documentation for details](common/README.md)

### Testing

When cloning, don't for get to run:

```
git clone --recurse-submodules git@github.com:Provi-Engineering/helm-charts.git
```

If you did forget, you can run:

```
git submodule update --init
```

#### To run all tests

```
make check
```

`make check` is the full gate: it refreshes the fixture charts against the current
`charts/common` version, runs the tests, then restores the fixtures. `make test` runs only the
tests, and needs the fixture dependencies that `make check` builds, so run `make check` once in a
fresh checkout.

The tests run in parallel, one bats process per `test/test_*.bats` file. The run fails if any test
fails or if fewer tests ran than the tag selects.

#### To run individual tests

```
TAG=podspec-securitycontext make test
```

A `TAG` that selects no tests fails and names the tag.

#### When a run fails

The run keeps its temp directories and prints their location, one `.../bats-run-*/test/` path per
failing test file. In it, `N.name` names test N, and the directory `N` holds that test's files,
such as its rendered output. A passing run deletes them.

You can get a list of tags by running:
```
git grep tags= | awk -F= '{print $2}'
```
