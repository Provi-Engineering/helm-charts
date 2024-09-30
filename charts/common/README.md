# Common Microservice

Helm chart to accomodate the most basic and straightforward setup for deploying microservices on EKS.

## Supported resources

- Deployment
- StatefulSet
- Ingress
- Job
- CronJob

## Setting up a new project

For new projects, let's create a few directories and files:

```bash
mkdir -p helm/project
mkdir helm/project/templates
touch helm/project/Chart.yaml
touch helm/project/templates/microservice.yaml.tpl
touch helm/values.yaml
```

Next, edit `Chart.yaml` file with:

```yaml
apiVersion: v2
name: your-app-name
description: Your application description
type: application
version: 0.1.0
dependencies:
  - name: common
    repository: s3://provi-helm-charts
    version: 0.1.0
```

Edit `helm/project/templates/microservice.yaml.tpl`:

```
{{- include "common.kubernetes.microservice" . }}
```

Edit `helm/values.yaml` (you can have multiple values files, one per env):

```yaml
global:
  # See examples for global options below

deployments:
  myapp:
    # See examples below
ingresses:
  myapp:
    # See examples below
```

## Example configuration

Example `values.yaml` file:

```yaml
# Global sections defines the image, labels and annotations that will apply to all resources
global:
  image: docker.io/REPONAME:TAGNAME
  appDomain: myapp # Your application subdomain
  rootDomain: pvfog.org # EKS env root domain
  labels:
    # Identify who owns the service
    team: your-team-name
    # Severity label could be used for configuring monitoring/alerting
    # Possible values: noncritical, critical
    severity: noncritical
  annotations:
    # Extra useful bits of information to track the owners or comm channels
    provi.slack: "dev"
    provi.repository: https://github.com/example/repo
  env:
    # Environment variables for all microservice containers
    RAILS_ENV: production

deployments:
  myapp:
    # Defines which ports are exposed on the container
    service:
      ports:
        http:
          port: 8080
          targetPort: 8080
          protocol: TCP
    serviceAccount:
      enabled: true
      annotations:
        # Configure IAM role. Roles could be created in terraform.
        eks.amazonaws.com/role-arn: arn:aws:iam::XXX:role/role-name
    # Number of replicas if using static number of pods
    replicas: 1
    # Dynamic number of pods to scale up/down based on pod CPU utilization (default: 80%)
    autoscaling:
      minReplicas: 2
      maxReplicas: 6
      targetUtilization: 80
      # Optional - this will scale down the pods 1 at a time every 120s (2mins)
      # Details of options defined:
      #   https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#scaling-policies
      behavior:
        scaleDown:
          policies:
          - type: Pods
            value: 1
            periodSeconds: 120
    pod:
      containers:
        app:
          env:
            RACK_ENV: production
            RAILS_ENV: production
          resources:
            requests:
              memory: 256Mi
              cpu: 250m
            limits:
              memory: 256Mi
          # Liveness and readiness probes must be set but disabled by default
          # TODO: add example probe
          livenessProbe:
            disabled: true
          readinessProbe:
            disabled: true

# Stateful sets are the same as deployments but they get persistent disk storage
statefulSets:
  myapp-stateful:
    # service and service account is similar to deployment
    replicas: 1
    pod:
      containers:
        app:
          # ...
          # most of the container spec is the same as deployment
          # ...
          # Bind the persistent volume clain into container
          volumeMounts:
            - name: data
              mountPath: /data
    volumeClaimTemplates:
      - metadata:
          name: data
        spec:
          accessModes:
            - "ReadWriteOnce"
          resources:
            requests:
              # Specify amount of storage required.
              # IMPORTANT: Resizing the volume via k8s spec change is not possible.
              # Pick the right amount of storage first time. Resizing volumes later is done in AWS console.
              storage: "10Gi"

# Jobs that run on chart install/upgrades, useful for database migrations, etc.
jobs:
  myapp-migrations:
    annotations:
      helm.sh/hook: pre-install,pre-upgrade
      helm.sh/hook-delete-policy: before-hook-creation
      helm.sh/hook-weight: "0"
    pod:
      restartPolicy: Never
      containers:
        migrate:
          command:
            - bundle
            - exec
            - rake
            - db:migrate
          resources:
            requests:
              memory: 256Mi
              cpu: 100m
            limits:
              memory: 256Mi

# Cron jobs allow running scheduled workloads.
# By default we keep pods around from 5 last executions to investigate logs.
cronJobs:
  myapp-scheduler:
    schedule: "0 * * * *"
    pod:
      containers:
        schedule:
          command:
            - bundle
            - exec
            - rake
            - do:something
          resources:
            requests:
              memory: 256Mi
              cpu: 100m
            limits:
              memory: 256Mi

# Ingress allows to expose the services in K8s
ingresses:
  myapp:
    # Define app/root domain if they're not set in the `global` section
    # appDomain: myapp # Your application subdomain
    # rootDomain: pvfog.org # EKS env root domain
    class: nginx # nginx for public traffic, nginx-internal for internal traffic
    service:
      name: myapp
      port: 8080
```

## Configuring Secret Environment Variables

There are currently 3 ways to configure secret values for environment variables:

1. Globally for all containers, using `global.env` attribute.
2. Per container, using `env` attribute.
3. Per container, using `envFrom` attribute.

**Globally**

```yaml
global:
  env:
    # Full version
    MY_SECRET_VAL:
      secretKeyRef:
        name: myapp
        key: secret-key

    # Shorthand version
    # We will use chart name as a secret name by default (myapp in this case)
    MY_SECRET_VAL:
      secretValue: secret-key

    # Optional version
    MY_SECRET_VAL:
      optionalSecretValue: secret-key
```

**Per container**

```yaml
deployments:
  myapp:
    pod:
      containers:
        app:
          env:
            # Full version
            MY_SECRET_VAL:
              secretKeyRef:
                name: myapp
                key: secret-key
            # Shorthand version
            MY_SECRET_VAL:
              secretValue: secret-key
```

**Setting multiple env vars from a file**

```yaml
deployments:
  myapp:
    pod:
      containers:
        app:
          # We will set environment variables from all key-value pairs in the myapp secret
          envFrom:
            - secretKeyRef:
                name: myapp
          # You can mix variables defined in the file with additional values below
          env:
            EXTRA_VAR: value
```

## Configuring Service Accounts

By default pods do not have SA (Service Account) enabled. To enable SA, add the following
config to your workload pod spec. Example:

```yaml
deployments:
  api:
    pod:
      serviceAccount:
        enabled: true
```

If SA `name` is not provided, we'll generate name for this pod based on the chart
name and type of the workload, ie. if your application chart is named `myapp`,
deployment pod named `api`, the SA name will be `myapp-deployment-api`.

To specify your own SA name, add `name` attribute:

```yaml
deployments:
  api:
    pod:
      serviceAccount:
        enabled: true
        name: myapp
```

In order to map SA to an IAM role, we will need to create a bit of Terraform code:

```tf
locals {
  account_id    = data.aws_caller_identity.current.account_id
  oidc_provider = trimprefix(data.aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://")

  service_accounts = formatlist(
    "system:serviceaccount:${var.k8s_namespace}:%s",
    var.k8s_service_accounts
  )
}

data "aws_eks_cluster" "main" {
  name = var.eks_cluster_name
}

data "aws_iam_policy_document" "assume_eks" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${local.account_id}:oidc-provider/${local.oidc_provider}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:sub"
      values   = local.service_accounts
    }
  }
}

resource "aws_iam_role" "service_user" {
  name               = "${local.component_cluster}-${var.env}-serviceuser"
  assume_role_policy = data.aws_iam_policy_document.assume_eks.json

  inline_policy {
    name   = "main"
    policy = data.template_file.s3_policy.rendered
  }
}
```

Where the necessary values are:

- `eks_cluster_name` - Name of your EKS cluster
- `k8s_namespace` - Your application namespace in k8s. Do not use `default` namespace.
- `k8s_service_accounts` - Names of service accounts to map to the IAM role.

Based on the example of SA, we can use:

```tf
eks_cluster_name     = "dev"
k8s_namespace        = "myapp"
k8s_service_accounts = [
  "myapp-deployment-web",
  "myapp-deployment-worker"
]
```

Or in case if you want to have a single role for all workloads:

```tf
k8s_service_accounts = ["myapp"]
```
