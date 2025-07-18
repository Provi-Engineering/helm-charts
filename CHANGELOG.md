# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.8.13] - 2025-07-17

### Fixed

- Removes the `argocd.argoproj.io/hook: PreSync` annotation from the cluster-scoped `ClusterExternalSecret` manifests, since it can cause errors rendering the JSON used internally by ArgoCD.

## [1.8.12] - 2025-06-12

### Fixed

- If there are multiple deployments defined and the second (or any subsequent after the first) deployment has a `podDisruptionBudget` defined, then the template does not put a newline after each deployment, thereby not creating a separate document (because there needs to be a `---` on its own line in Yaml to separate documents), and thereby causing less than all of your deployments to be created.

## [1.8.11] - 2025-06-12

### Fixed

- The Pod Disruption Template used `app` as the matchLabels selector, but the selector used by Deployments and all the various resources is `selector`. This aligns PDBs with the rest of the resources.

## [1.8.10] - 2025-04-28

### Fixed

- ALB Ingresses which have the `ttl` annotation (`external-dns.alpha.kubernetes.io/ttl`) will keep triggering external-dns to modify the records, but nothing actually happens, which is a waste of resources and adds unnecessary logging.

## [1.8.9] - 2025-01-10

### Added

- A service can specify that its base domain should redirect to a www. domain by adding the `redirectHostToWWW` key with the base domain as the value. e.g. if your hostnames list includes www.example.com you can specify `redirectHostToWWW: example.com` in order to set the ALB rules to do this. At the moment this is only supported for one hostname per service definition.

## [1.8.8] - 2025-01-03

### Added

- Pod Disruption Budgets can be defined by adding a `podDisruptionBudget` to a deployment with `minAvailable` and `maxUnavailable` specified as described [in the Kubernetes documentation](https://kubernetes.io/docs/tasks/run-application/configure-pdb/).

## [1.8.7] - 2024-12-23

### Added

- Added the `hostnameAliases` list for services to specify additional HTTP host headers that should be accepted  by the load balancer, e.g. if you have a CNAME alias to a domain in the hostnames list.

## [1.8.6] - 2024-12-19

### Added

- You can include a `healthcheckProtocol` in the `ingresses` section, which will add the `alb.ingress.kubernetes.io/healthcheck-protocol` annotation to the Ingress.

## [1.8.5] - 2024-12-19

### Added

- You can include a `healthcheckPort` in the `ingresses` section, which will add the `alb.ingress.kubernetes.io/healthcheck-port` annotation to the Ingress.

## [1.8.4] - 2024-12-18

### Added

- You can now specify `targetMemoryUtilization` and/or `targetCPUUtilization` for the autoscaler. Existing usage of `targetUtilization` will continue to assume you mean cpu.

## [1.8.3] - 2024-12-18

### Added

- Added the `ClusterExternalSecret` template. If you include a `secrets` key in your values file, the template will be rendered.

## [1.8.2] - 2024-12-17

### Fixed

- If the global variable `awsAccountId` is not quoted, it will ensure it is an int and not an float64 (which will fail to deploy).

## [1.8.1] - 2024-11-04

### Added

- Added an `imperva` boolean which will take care of prepending an `origin-` to the hostnames and adding an annotation to add the original hostname to the listener rule conditions so that Imperva requests to that hostname will work.

## [1.8.0] - 2024-10-29

### Fixed

- Remove static replicas from deployment when autoscaling enabled
- Fixed autoscaling.behavior error

## [1.7.7] - 2024-08-13

### Fixed

- Fixed a logic error in the serviceaccount template
- Fixed the `serviceAccount` syntax in the values file for the cronjobs tests and un-skipped a test

### Added

- Added test to the CI job

## [1.7.6] - 2024-08-12

### Added

- Added `timeZone` to cronJobs.

## [1.7.5] - 2024-05-30

### Changed

- New repo created for releasing helm-charts repo via Github Pages (using chart-releaser)

## [1.7.4] - 2024-05-16

### Fixed

- Root context was not being passed to containers in all cases.

## [1.7.3] - 2024-05-15

### Changed

- Added optional support for `resources.limits.cpu` value.

## [1.7.2] - 2024-05-03

### Changed

- Changed the default `pathType` from `ImplementationSpecific` to `Prefix` so that listener rules in the ALBs will be configured as `/*` to match all paths defined in the application.

## [1.7.1] - 2024-05-03

### Changed

- Switched to using the root context passed to the templates to access values passed by the Gitops Bridge in the Ingress. This is more flexible for fugure use.

### Added

- Added a default `CLUSTER_NAME` env var for containers which contains the cluster name. This will generally be set by Gitops Bridge.

## [1.6.0] - 2024-02-07

### Added

- Variables provided by Gitops Bridge (`.Values.spec.ingress.route53_weight` and `.Values.spec.clusterName`) will now add annotations to the Ingress which will affect `external-dns`. This allows for blue/green clusters by weighting DNS towards one cluster or another. The pattern is described at https://aws-ia.github.io/terraform-aws-eks-blueprints/patterns/blue-green-upgrade.

## [1.6.0] - 2024-02-07

### Added

- Ingresses now support ALBs when specifying `alb` as the `ingressClass`. You also must specify `scheme` (`internal` or `internet-facing`) and `certificateArn` when using `alb`.
- The ALB will redirect http requests to https.

## [1.5.1] - 2023-11-07

### Fixed

- No longer defaults to "foobar" for `imagePullSecrets`; instead, only include `imagePullSecrets` if `imagePullSecretsName` is defined.

## [1.5.0] - 2023-04-DD

- Adds bats tests to ensure output doesn't change when we make changes or additions, and to ensure correct behavior when we add features.

## [1.4.1] - 2023-04-19

### Changed

- Allows a configurable role name for the `serviceAccount`. By default, it will still use the `serviceAccount.name` field for the IAM role annotation, but if `serviceAccount.role.name` is provided, it will use that instead.

## [1.4.0] - 2023-03-07

### Added

- Adds configurable ephemeral storage requests.

## [1.3.0] - 2023-03-06

### Added

- Adds the ability to make node affinity configurable, rather than hard-coding karpenter node affinity.

## [1.2.0] - 2023-03-01

### Added

- Adds the ability to provide multiple tolerations. Adding new tolerations is more flexible now, as you simply provide the taint key values as a list, instead of only using pre-configured tolerations. E.g., to tolerate spot instances, simply add `spot` to the list of tolerations in the deployments pod spec.

## [1.1.0] - 2023-03-01

### Added

- Adds `topologyKeyConstraints` to allow scheduling pods on separate nodes and in separate availability zones.

## [1.0.4] - 2023-02-28

### Fixed

- Gets rid of a nil pointer error when `hostnmesNoExternalDNS` is not set in an Ingress.

## [1.0.3] - 2023-02-27

### Added

- The `Ingress` resource section now has a `hostnmesNoExternalDNS` list. This allows you to specify a hostname to which `ingress-nginx` can route but which does not get a DNS entry created by `external-dns`. The use-case for this is when we create Imperva entries. We need to manually (or via Terraform) create a record which routes to the Imperva URL. Imperva will then forward requests to the load balancer, and `ingress-nginx` routes to the application.

## [1.0.2] - 2023-02-09

### Fixed

- Removes the `tls` key to avoid using the cert-manager Certificate template in case anybody still has the `tls: true` setting in their values file.


## [1.0.1] - 2023-02-08

### Fixed

- Removed trailing dash for the `common.kubernetes.containerspec` template definition, thus allowing multiple containers per pod.

## [0.0.1] - 2022-12-19

### Fixed

- Removed trailing dash for the `common.kubernetes.containerspec` template definition, thus allowing multiple containers per pod.

## [1.0.0] - 2022-11-29

### Added

- A `spotInstances` toleration to utilize spot instances, if desired
- A service account annotation to support features used in `eks_skeleton`
- A `dry-run` target for the Makefile, for ensuring Helm templates compile
- Set node affiinity to leverage karpenter

### Changed

- Removed SSL termination at the ingress
- Used `ingressClassName` field instead of the deprecated ingress class annotation

## [0.1.0] - 2022-08-24

### Added

- Initial release
