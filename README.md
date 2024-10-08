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

Please refer to chart [develoment documentation](dev/README.md)

### Releasing

See instructions in the [develoment documentation](dev/README.md). The upshot:
* Update the `CHANGELOG.md`
* Update the version in `common/Chart.yaml`
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
make test
```

#### To run individual tests

```
TAG=podspec-securitycontext make test
```

You can get a list of tags by running:
```
git grep tags= | awk -F= '{print $2}'
```
