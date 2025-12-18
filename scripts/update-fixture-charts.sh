Script started on Thu Dec 18 15:52:53 2025
[1m[3m%[23m[1m[0m                                                                                                                                                             k..t/helm-charts\]7;file://negroni/Users/chris.reisor/git/helm-charts\[0m[23m[24m[J[01;32mchris.reisor@negroni[00m [01;34mgit/helm-charts[00m [33m(INFRASEC-4257-affinity-and-topology) [00m[00m[1m»[0m [K[?1h=[6 q[?2004hggd[?1l>[0 q[?2004l
kgd\[?1h=[1mdiff --git a/CHANGELOG.md b/CHANGELOG.md[m[m
[1mindex 3cc89d0..eedd8de 100644[m[m
[1m--- a/CHANGELOG.md[m[m
[1m+++ b/CHANGELOG.md[m[m
[36m@@ -7,11 +7,11 @@[m [mand this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0[m[m
 [m[m
 ## [Unreleased][m[m
 [m[m
[31m-## [1.9.0] - 2025-12-17[m[m
[32m+[m[32m## [1.9.0] - 2025-12-18[m[m
 [m[m
 ### Added[m[m
 [m[m
[31m-- Pods now include a default `podAntiAffinity` targeting `karpenter.sh/controller: "true"`, with new `antiAffinityLabel` and `antiAffinityDisabled` controls[m [31m plus support for merging with caller-provided affinity rules.[m[m
[32m+[m[32m- Pods now include a default `nodeAffinity` to ensure pods do not get scheduled on nodes labeled `karpenter.sh/controller: "true"`, with new `antiAffinityLa[m [32m[m[32mbel` and `antiAffinityDisabled` controls plus support for merging with caller-provided affinity rules.[m[m
 - Replaced the legacy `pod.topologySpreadConstraints.matchLabels` defaults with `pod.defaultTopologySpreadConstraints`, added a configurable `whenUnsatisfia[m ble`, and allow callers to provide full `topologySpreadConstraints` lists with validation for required fields.[m[m
 - Includes `CONTRIBUTING.md` doc for help on creating patch releases for the 1.8.x series, which is required until all apps are deployed to new clusters.[m[m
 [m[m
[1mdiff --git a/charts/common/templates/_pod_affinity.yaml.tpl b/charts/common/templates/_pod_affinity.yaml.tpl[m[m
[1mindex 7e85a8e..0b04423 100644[m[m
[1m--- a/charts/common/templates/_pod_affinity.yaml.tpl[m[m
[1m+++ b/charts/common/templates/_pod_affinity.yaml.tpl[m[m
[36m@@ -24,28 +24,32 @@[m[m
 {{- else if $rawAffinity }}[m[m
   {{- fail "pod.affinity must be provided as a map" }}[m[m
 {{- end }}[m[m
[31m-{{- $antiAffinityDisabled := default false .pod.antiAffinityDisabled }}[m[m
[31m-{{- if not $antiAffinityDisabled }}[m[m
[31m-  {{- $labelConfig := .pod.antiAffinityLabel | default (dict "karpenter.sh/controller" "true") }}[m[m
[32m+[m[32m{{- $nodeAffinityDisabled := default false .pod.antiAffinityDisabled }}[m[m
[32m+[m[32m{{- if not $nodeAffinityDisabled }}[m[m
[32m+[m[32m  {{- $labelConfig := coalesce .pod.nodeAffinityLabel .pod.antiAffinityLabel (dict "karpenter.sh/controller" "true") }}[m[m
   {{- $matchExpressions := list }}[m[m
   {{- range $labelKey, $labelValue := $labelConfig }}[m[m
     {{- if ne $labelValue nil }}[m[m
[31m-      {{- $matchExpressions = append $matchExpressions (dict "key" $labelKey "operator" "In" "values" (list (printf "%v" $labelValue))) }}[m[m
[32m+[m[32m      {{- $matchExpressions = append $matchExpressions (dict "key" $labelKey "operator" "NotIn" "values" (list (printf "%v" $labelValue))) }}[m[m
:[K[K     {{- end }}[m[m
   {{- end }}[m[m
   {{- if gt (len $matchExpressions) 0 }}[m[m
[31m-    {{- $term := dict "labelSelector" (dict "matchExpressions" $matchExpressions) "topologyKey" "kubernetes.io/hostname" }}[m[m
[31m-    {{- $podAntiAffinity := dict }}[m[m
[31m-    {{- if hasKey $affinity "podAntiAffinity" }}[m[m
[31m-      {{- $podAntiAffinity = deepCopy (get $affinity "podAntiAffinity") }}[m[m
[32m+[m[32m    {{- $nodeAffinity := dict }}[m[m
[32m+[m[32m    {{- if hasKey $affinity "nodeAffinity" }}[m[m
[32m+[m[32m      {{- $nodeAffinity = deepCopy (get $affinity "nodeAffinity") }}[m[m
     {{- end }}[m[m
[31m-    {{- $required := list }}[m[m
[31m-    {{- if hasKey $podAntiAffinity "requiredDuringSchedulingIgnoredDuringExecution" }}[m[m
[31m-      {{- $required = deepCopy (get $podAntiAffinity "requiredDuringSchedulingIgnoredDuringExecution") }}[m[m
[32m+[m[32m    {{- $required := dict }}[m[m
[32m+[m[32m    {{- if hasKey $nodeAffinity "requiredDuringSchedulingIgnoredDuringExecution" }}[m[m
[32m+[m[32m      {{- $required = deepCopy (get $nodeAffinity "requiredDuringSchedulingIgnoredDuringExecution") }}[m[m
     {{- end }}[m[m
[31m-    {{- $required = append $required $term }}[m[m
[31m-    {{- $_ := set $podAntiAffinity "requiredDuringSchedulingIgnoredDuringExecution" $required }}[m[m
[31m-    {{- $_ := set $affinity "podAntiAffinity" $podAntiAffinity }}[m[m
[32m+[m[32m    {{- $nodeSelectorTerms := list }}[m[m
[32m+[m[32m    {{- if hasKey $required "nodeSelectorTerms" }}[m[m
[32m+[m[32m      {{- $nodeSelectorTerms = deepCopy (get $required "nodeSelectorTerms") }}[m[m
[32m+[m[32m    {{- end }}[m[m
[32m+[m[32m    {{- $nodeSelectorTerms = append $nodeSelectorTerms (dict "matchExpressions" $matchExpressions) }}[m[m
[32m+[m[32m    {{- $_ := set $required "nodeSelectorTerms" $nodeSelectorTerms }}[m[m
[32m+[m[32m    {{- $_ := set $nodeAffinity "requiredDuringSchedulingIgnoredDuringExecution" $required }}[m[m
[32m+[m[32m    {{- $_ := set $affinity "nodeAffinity" $nodeAffinity }}[m[m
   {{- end }}[m[m
 {{- end }}[m[m
 {{- if gt (len $affinity) 0 }}[m[m
[1mdiff --git a/scripts/update-fixture-charts.sh b/scripts/update-fixture-charts.sh[m[m
[1mindex 2181a6e..fb7721a 100755[m[m
[1m--- a/scripts/update-fixture-charts.sh[m[m
[1m+++ b/scripts/update-fixture-charts.sh[m[m
[36m@@ -1,80 +1 @@[m[m
[31m-#!/usr/bin/env bash[m[m
[31m-[m[m
[31m-initial_errexit_state=$(set -o | awk '$1=="errexit" {print $2}')[m[m
:[K[K[31m-initial_pipefail_state=$(set -o | awk '$1=="pipefail" {print $2}')[m[m
[31m-initial_nounset_state=$(set -o | awk '$1=="nounset" {print $2}')[m[m
[31m-[m[m
[31m-set -o errexit[m[m
[31m-set -o pipefail[m[m
[31m-set -o nounset[m[m
[31m-[m[m
[31m-restore_shellopts() {[m[m
[31m-  if [[ "$initial_errexit_state" == "off" ]]; then[m[m
[31m-    set +e[m[m
[31m-  else[m[m
[31m-    set -e[m[m
[31m-  fi[m[m
[31m-[m[m
[31m-  if [[ "$initial_pipefail_state" == "off" ]]; then[m[m
[31m-    set +o pipefail[m[m
[31m-  else[m[m
[31m-    set -o pipefail[m[m
[31m-  fi[m[m
[31m-[m[m
[31m-  if [[ "$initial_nounset_state" == "off" ]]; then[m[m
[31m-    set +u[m[m
[31m-  else[m[m
[31m-    set -u[m[m
[31m-  fi[m[m
[31m-}[m[m
[31m-trap restore_shellopts EXIT[m[m
[31m-[m[m
[31m-if [[ $# -ne 1 ]]; then[m[m
[31m-[m[m
[31m-  echo "Usage: $0 <common_chart_version>" >&2[m[m
[31m-  exit 1[m[m
[31m-fi[m[m
[31m-[m[m
[31m-if ! command -v helm >/dev/null 2>&1; then[m[m
[31m-  echo "Error: helm is not installed or not in PATH" >&2[m[m
[31m-  exit 1[m[m
[31m-fi[m[m
[31m-[m[m
[31m-COMMON_VERSION="$1"[m[m
:[K[K[31m-FIXTURES_ROOT="test/fixtures"[m[m
[31m-[m[m
[31m-if [[ ! -d "$FIXTURES_ROOT" ]]; then[m[m
[31m-  echo "Error: $FIXTURES_ROOT directory not found" >&2[m[m
[31m-  exit 1[m[m
[31m-fi[m[m
[31m-[m[m
[31m-for chart_dir in "$FIXTURES_ROOT"/*/; do[m[m
[31m-  [[ -d "$chart_dir" ]] || continue[m[m
[31m-[m[m
[31m-  chart_file="${chart_dir}Chart.yaml"[m[m
[31m-  lock_file="${chart_dir}Chart.lock"[m[m
[31m-[m[m
[31m-  # Remove legacy symlinks so we can write real files[m[m
[31m-  if [[ -L "$chart_file" ]]; then[m[m
[31m-    rm "$chart_file"[m[m
[31m-  fi[m[m
[31m-  if [[ -L "$lock_file" ]]; then[m[m
[31m-    rm "$lock_file"[m[m
[31m-  fi[m[m
[31m-[m[m
[31m-  cat > "$chart_file" <<EOF[m[m
[31m-apiVersion: v2[m[m
[31m-name: my-cool-app[m[m
[31m-description: Defaults chart for testing[m[m
[31m-type: application[m[m
[31m-version: 1.0.0[m[m
[31m-dependencies:[m[m
[31m-  - name: common[m[m
[31m-    repository: file://../../../charts/common[m[m
[31m-    version: "$COMMON_VERSION"[m[m
[31m-EOF[m[m
[31m-[m[m
[31m-  echo "Running helm dependency update in ${chart_dir}"[m[m
[31m-  # Equivalent to 'helm dep up' in modern Helm (aka 'helm up')[m[m
[31m-  (cd "$chart_dir" && helm dependency update)[m[m
[31m-done[m[m
[32m+[m[32mScript started on Thu Dec 18 15:52:53 2025[m[m
[1mdiff --git a/test/expected_output/affinity.yaml b/test/expected_output/affinity.yaml[m[m
[1mindex 9d45871..b46075b 100644[m[m
:[K[K[1m--- a/test/expected_output/affinity.yaml[m[m
[1m+++ b/test/expected_output/affinity.yaml[m[m
[36m@@ -95,12 +95,8 @@[m [mspec:[m[m
                 operator: In[m[m
                 values:[m[m
                 - testaffinity[m[m
[31m-        podAntiAffinity:[m[m
[31m-          requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-          - labelSelector:[m[m
[31m-              matchExpressions:[m[m
[32m+[m[32m            - matchExpressions:[m[m
               - key: karpenter.sh/controller[m[m
[31m-                operator: In[m[m
[32m+[m[32m                operator: NotIn[m[m
                 values:[m[m
                 - "true"[m[m
[31m-            topologyKey: kubernetes.io/hostname[m[m
[1mdiff --git a/test/expected_output/autoscaler.yaml b/test/expected_output/autoscaler.yaml[m[m
[1mindex 9777b6b..caab7a4 100644[m[m
[1m--- a/test/expected_output/autoscaler.yaml[m[m
[1m+++ b/test/expected_output/autoscaler.yaml[m[m
[36m@@ -82,15 +82,14 @@[m [mspec:[m[m
               memory: 256Mi[m[m
               ephemeral-storage: 200Mi[m[m
       affinity:[m[m
[31m-        podAntiAffinity:[m[m
[32m+[m[32m        nodeAffinity:[m[m
           requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-          - labelSelector:[m[m
[31m-              matchExpressions:[m[m
[32m+[m[32m            nodeSelectorTerms:[m[m
[32m+[m[32m            - matchExpressions:[m[m
               - key: karpenter.sh/controller[m[m
[31m-                operator: In[m[m
[32m+[m[32m                operator: NotIn[m[m
                 values:[m[m
                 - "true"[m[m
[31m-            topologyKey: kubernetes.io/hostname[m[m
 ---[m[m
 # Source: my-cool-app/templates/microservice.yaml.tpl[m[m
:[K[K apiVersion: autoscaling/v2[m[m
[1mdiff --git a/test/expected_output/containers-basic.yaml b/test/expected_output/containers-basic.yaml[m[m
[1mindex 54a668f..09510e2 100644[m[m
[1m--- a/test/expected_output/containers-basic.yaml[m[m
[1m+++ b/test/expected_output/containers-basic.yaml[m[m
[36m@@ -121,12 +121,8 @@[m [mspec:[m[m
                 operator: In[m[m
                 values:[m[m
                 - karpenter[m[m
[31m-        podAntiAffinity:[m[m
[31m-          requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-          - labelSelector:[m[m
[31m-              matchExpressions:[m[m
[32m+[m[32m            - matchExpressions:[m[m
               - key: karpenter.sh/controller[m[m
[31m-                operator: In[m[m
[32m+[m[32m                operator: NotIn[m[m
                 values:[m[m
                 - "true"[m[m
[31m-            topologyKey: kubernetes.io/hostname[m[m
[1mdiff --git a/test/expected_output/cronjobs-global-serviceaccount.yaml b/test/expected_output/cronjobs-global-serviceaccount.yaml[m[m
[1mindex fef5b8b..4410545 100644[m[m
[1m--- a/test/expected_output/cronjobs-global-serviceaccount.yaml[m[m
[1m+++ b/test/expected_output/cronjobs-global-serviceaccount.yaml[m[m
[36m@@ -69,12 +69,11 @@[m [mspec:[m[m
                   cpu: 100m[m[m
                   memory: 256Mi[m[m
           affinity:[m[m
[31m-            podAntiAffinity:[m[m
[32m+[m[32m            nodeAffinity:[m[m
               requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-              - labelSelector:[m[m
[31m-                  matchExpressions:[m[m
[32m+[m[32m                nodeSelectorTerms:[m[m
[32m+[m[32m                - matchExpressions:[m[m
                   - key: karpenter.sh/controller[m[m
[31m-                    operator: In[m[m
[32m+[m[32m                    operator: NotIn[m[m
                     values:[m[m
                     - "true"[m[m
:[K[K[31m-                topologyKey: kubernetes.io/hostname[m[m
[1mdiff --git a/test/expected_output/cronjobs-serviceaccount.yaml b/test/expected_output/cronjobs-serviceaccount.yaml[m[m
[1mindex 0d4c84a..c970af0 100644[m[m
[1m--- a/test/expected_output/cronjobs-serviceaccount.yaml[m[m
[1m+++ b/test/expected_output/cronjobs-serviceaccount.yaml[m[m
[36m@@ -73,12 +73,11 @@[m [mspec:[m[m
                   cpu: 100m[m[m
                   memory: 256Mi[m[m
           affinity:[m[m
[31m-            podAntiAffinity:[m[m
[32m+[m[32m            nodeAffinity:[m[m
               requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-              - labelSelector:[m[m
[31m-                  matchExpressions:[m[m
[32m+[m[32m                nodeSelectorTerms:[m[m
[32m+[m[32m                - matchExpressions:[m[m
                   - key: karpenter.sh/controller[m[m
[31m-                    operator: In[m[m
[32m+[m[32m                    operator: NotIn[m[m
                     values:[m[m
                     - "true"[m[m
[31m-                topologyKey: kubernetes.io/hostname[m[m
[1mdiff --git a/test/expected_output/cronjobs.yaml b/test/expected_output/cronjobs.yaml[m[m
[1mindex bd18369..03d5ebe 100644[m[m
[1m--- a/test/expected_output/cronjobs.yaml[m[m
[1m+++ b/test/expected_output/cronjobs.yaml[m[m
[36m@@ -61,12 +61,11 @@[m [mspec:[m[m
                   cpu: 100m[m[m
                   memory: 256Mi[m[m
           affinity:[m[m
[31m-            podAntiAffinity:[m[m
[32m+[m[32m            nodeAffinity:[m[m
               requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-              - labelSelector:[m[m
[31m-                  matchExpressions:[m[m
[32m+[m[32m                nodeSelectorTerms:[m[m
[32m+[m[32m                - matchExpressions:[m[m
                   - key: karpenter.sh/controller[m[m
[31m-                    operator: In[m[m
[32m+[m[32m                    operator: NotIn[m[m
:[K[K                     values:[m[m
                     - "true"[m[m
[31m-                topologyKey: kubernetes.io/hostname[m[m
[1mdiff --git a/test/expected_output/deployments-selector.yaml b/test/expected_output/deployments-selector.yaml[m[m
[1mindex 4fc50b8..becd9cc 100644[m[m
[1m--- a/test/expected_output/deployments-selector.yaml[m[m
[1m+++ b/test/expected_output/deployments-selector.yaml[m[m
[36m@@ -121,15 +121,11 @@[m [mspec:[m[m
                 operator: In[m[m
                 values:[m[m
                 - karpenter[m[m
[31m-        podAntiAffinity:[m[m
[31m-          requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-          - labelSelector:[m[m
[31m-              matchExpressions:[m[m
[32m+[m[32m            - matchExpressions:[m[m
               - key: karpenter.sh/controller[m[m
[31m-                operator: In[m[m
[32m+[m[32m                operator: NotIn[m[m
                 values:[m[m
                 - "true"[m[m
[31m-            topologyKey: kubernetes.io/hostname[m[m
 ---[m[m
 # Source: my-cool-app/templates/microservice.yaml.tpl[m[m
 apiVersion: autoscaling/v2[m[m
[1mdiff --git a/test/expected_output/deployments.yaml b/test/expected_output/deployments.yaml[m[m
[1mindex 46d1e76..b6fc98a 100644[m[m
[1m--- a/test/expected_output/deployments.yaml[m[m
[1m+++ b/test/expected_output/deployments.yaml[m[m
[36m@@ -127,15 +127,11 @@[m [mspec:[m[m
                 operator: In[m[m
                 values:[m[m
                 - karpenter[m[m
[31m-        podAntiAffinity:[m[m
[31m-          requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-          - labelSelector:[m[m
[31m-              matchExpressions:[m[m
[32m+[m[32m            - matchExpressions:[m[m
               - key: karpenter.sh/controller[m[m
[31m-                operator: In[m[m
:[K[K[32m+[m[32m                operator: NotIn[m[m
                 values:[m[m
                 - "true"[m[m
[31m-            topologyKey: kubernetes.io/hostname[m[m
 ---[m[m
 # Source: my-cool-app/templates/microservice.yaml.tpl[m[m
 apiVersion: autoscaling/v2[m[m
[1mdiff --git a/test/expected_output/jobs.yaml b/test/expected_output/jobs.yaml[m[m
[1mindex d50a43b..e3748b3 100644[m[m
[1m--- a/test/expected_output/jobs.yaml[m[m
[1m+++ b/test/expected_output/jobs.yaml[m[m
[36m@@ -54,12 +54,11 @@[m [mspec:[m[m
               cpu: 100m[m[m
               memory: 256Mi[m[m
       affinity:[m[m
[31m-        podAntiAffinity:[m[m
[32m+[m[32m        nodeAffinity:[m[m
           requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-          - labelSelector:[m[m
[31m-              matchExpressions:[m[m
[32m+[m[32m            nodeSelectorTerms:[m[m
[32m+[m[32m            - matchExpressions:[m[m
               - key: karpenter.sh/controller[m[m
[31m-                operator: In[m[m
[32m+[m[32m                operator: NotIn[m[m
                 values:[m[m
                 - "true"[m[m
[31m-            topologyKey: kubernetes.io/hostname[m[m
[1mdiff --git a/test/expected_output/microservice.yaml b/test/expected_output/microservice.yaml[m[m
[1mindex e769301..4fb3136 100644[m[m
[1m--- a/test/expected_output/microservice.yaml[m[m
[1m+++ b/test/expected_output/microservice.yaml[m[m
[36m@@ -177,15 +177,11 @@[m [mspec:[m[m
                 operator: In[m[m
                 values:[m[m
                 - karpenter[m[m
[31m-        podAntiAffinity:[m[m
[31m-          requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-          - labelSelector:[m[m
[31m-              matchExpressions:[m[m
:[K[K[32m+[m[32m            - matchExpressions:[m[m
               - key: karpenter.sh/controller[m[m
[31m-                operator: In[m[m
[32m+[m[32m                operator: NotIn[m[m
                 values:[m[m
                 - "true"[m[m
[31m-            topologyKey: kubernetes.io/hostname[m[m
 ---[m[m
 # Source: my-cool-app/templates/microservice.yaml.tpl[m[m
 apiVersion: autoscaling/v2[m[m
[36m@@ -286,15 +282,14 @@[m [mspec:[m[m
             - mountPath: /data[m[m
               name: data[m[m
       affinity:[m[m
[31m-        podAntiAffinity:[m[m
[32m+[m[32m        nodeAffinity:[m[m
           requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-          - labelSelector:[m[m
[31m-              matchExpressions:[m[m
[32m+[m[32m            nodeSelectorTerms:[m[m
[32m+[m[32m            - matchExpressions:[m[m
               - key: karpenter.sh/controller[m[m
[31m-                operator: In[m[m
[32m+[m[32m                operator: NotIn[m[m
                 values:[m[m
                 - "true"[m[m
[31m-            topologyKey: kubernetes.io/hostname[m[m
   volumeClaimTemplates:[m[m
     - metadata:[m[m
         name: data[m[m
[36m@@ -371,15 +366,14 @@[m [mspec:[m[m
                   cpu: 100m[m[m
                   memory: 256Mi[m[m
           affinity:[m[m
[31m-            podAntiAffinity:[m[m
[32m+[m[32m            nodeAffinity:[m[m
               requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-              - labelSelector:[m[m
[31m-                  matchExpressions:[m[m
[32m+[m[32m                nodeSelectorTerms:[m[m
:[K[K[32m+[m[32m                - matchExpressions:[m[m
                   - key: karpenter.sh/controller[m[m
[31m-                    operator: In[m[m
[32m+[m[32m                    operator: NotIn[m[m
                     values:[m[m
                     - "true"[m[m
[31m-                topologyKey: kubernetes.io/hostname[m[m
 ---[m[m
 # Source: my-cool-app/templates/microservice.yaml.tpl[m[m
 apiVersion: networking.k8s.io/v1[m[m
[36m@@ -487,12 +481,11 @@[m [mspec:[m[m
               cpu: 100m[m[m
               memory: 256Mi[m[m
       affinity:[m[m
[31m-        podAntiAffinity:[m[m
[32m+[m[32m        nodeAffinity:[m[m
           requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-          - labelSelector:[m[m
[31m-              matchExpressions:[m[m
[32m+[m[32m            nodeSelectorTerms:[m[m
[32m+[m[32m            - matchExpressions:[m[m
               - key: karpenter.sh/controller[m[m
[31m-                operator: In[m[m
[32m+[m[32m                operator: NotIn[m[m
                 values:[m[m
                 - "true"[m[m
[31m-            topologyKey: kubernetes.io/hostname[m[m
[1mdiff --git a/test/expected_output/podspec-basic.yaml b/test/expected_output/podspec-basic.yaml[m[m
[1mindex f851914..ca6b55c 100644[m[m
[1m--- a/test/expected_output/podspec-basic.yaml[m[m
[1m+++ b/test/expected_output/podspec-basic.yaml[m[m
[36m@@ -127,15 +127,11 @@[m [mspec:[m[m
                 operator: In[m[m
                 values:[m[m
                 - karpenter[m[m
[31m-        podAntiAffinity:[m[m
[31m-          requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-          - labelSelector:[m[m
[31m-              matchExpressions:[m[m
[32m+[m[32m            - matchExpressions:[m[m
:[K[K               - key: karpenter.sh/controller[m[m
[31m-                operator: In[m[m
[32m+[m[32m                operator: NotIn[m[m
                 values:[m[m
                 - "true"[m[m
[31m-            topologyKey: kubernetes.io/hostname[m[m
 ---[m[m
 # Source: my-cool-app/templates/microservice.yaml.tpl[m[m
 apiVersion: autoscaling/v2[m[m
[1mdiff --git a/test/expected_output/podspec_output.yaml b/test/expected_output/podspec_output.yaml[m[m
[1mindex f851914..ca6b55c 100644[m[m
[1m--- a/test/expected_output/podspec_output.yaml[m[m
[1m+++ b/test/expected_output/podspec_output.yaml[m[m
[36m@@ -127,15 +127,11 @@[m [mspec:[m[m
                 operator: In[m[m
                 values:[m[m
                 - karpenter[m[m
[31m-        podAntiAffinity:[m[m
[31m-          requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-          - labelSelector:[m[m
[31m-              matchExpressions:[m[m
[32m+[m[32m            - matchExpressions:[m[m
               - key: karpenter.sh/controller[m[m
[31m-                operator: In[m[m
[32m+[m[32m                operator: NotIn[m[m
                 values:[m[m
                 - "true"[m[m
[31m-            topologyKey: kubernetes.io/hostname[m[m
 ---[m[m
 # Source: my-cool-app/templates/microservice.yaml.tpl[m[m
 apiVersion: autoscaling/v2[m[m
[1mdiff --git a/test/expected_output/statefulsets.yaml b/test/expected_output/statefulsets.yaml[m[m
[1mindex 29f250c..add1569 100644[m[m
[1m--- a/test/expected_output/statefulsets.yaml[m[m
[1m+++ b/test/expected_output/statefulsets.yaml[m[m
[36m@@ -106,15 +106,14 @@[m [mspec:[m[m
             - mountPath: /data[m[m
               name: data[m[m
       affinity:[m[m
[31m-        podAntiAffinity:[m[m
:[K[K[32m+[m[32m        nodeAffinity:[m[m
           requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-          - labelSelector:[m[m
[31m-              matchExpressions:[m[m
[32m+[m[32m            nodeSelectorTerms:[m[m
[32m+[m[32m            - matchExpressions:[m[m
               - key: karpenter.sh/controller[m[m
[31m-                operator: In[m[m
[32m+[m[32m                operator: NotIn[m[m
                 values:[m[m
                 - "true"[m[m
[31m-            topologyKey: kubernetes.io/hostname[m[m
   volumeClaimTemplates:[m[m
     - metadata:[m[m
         name: data[m[m
[1mdiff --git a/test/fixtures/affinity/Chart.lock b/test/fixtures/affinity/Chart.lock[m[m
[1mindex 11c073e..150a626 100644[m[m
[1m--- a/test/fixtures/affinity/Chart.lock[m[m
[1m+++ b/test/fixtures/affinity/Chart.lock[m[m
[36m@@ -1,6 +1,6 @@[m[m
 dependencies:[m[m
 - name: common[m[m
   repository: file://../../../charts/common[m[m
[31m-  version: 1.9.0[m[m
[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[31m-generated: "2025-12-17T15:09:26.365997-06:00"[m[m
[32m+[m[32m  version: 1.10.0[m[m
[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[32m+[m[32mgenerated: "2025-12-18T15:48:26.804161-06:00"[m[m
[1mdiff --git a/test/fixtures/affinity/Chart.yaml b/test/fixtures/affinity/Chart.yaml[m[m
[1mindex a340089..3930d4f 100644[m[m
[1m--- a/test/fixtures/affinity/Chart.yaml[m[m
[1m+++ b/test/fixtures/affinity/Chart.yaml[m[m
[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
 dependencies:[m[m
   - name: common[m[m
     repository: file://../../../charts/common[m[m
[31m-    version: "1.9.0"[m[m
[32m+[m[32m    version: "1.10.0"[m[m
[1mdiff --git a/test/fixtures/autoscaler/Chart.lock b/test/fixtures/autoscaler/Chart.lock[m[m
:[K[K[1mindex 419ecd6..d0076a4 100644[m[m
[1m--- a/test/fixtures/autoscaler/Chart.lock[m[m
[1m+++ b/test/fixtures/autoscaler/Chart.lock[m[m
[36m@@ -1,6 +1,6 @@[m[m
 dependencies:[m[m
 - name: common[m[m
   repository: file://../../../charts/common[m[m
[31m-  version: 1.9.0[m[m
[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[31m-generated: "2025-12-17T15:09:27.105674-06:00"[m[m
[32m+[m[32m  version: 1.10.0[m[m
[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[32m+[m[32mgenerated: "2025-12-18T15:48:27.507813-06:00"[m[m
[1mdiff --git a/test/fixtures/autoscaler/Chart.yaml b/test/fixtures/autoscaler/Chart.yaml[m[m
[1mindex a340089..3930d4f 100644[m[m
[1m--- a/test/fixtures/autoscaler/Chart.yaml[m[m
[1m+++ b/test/fixtures/autoscaler/Chart.yaml[m[m
[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
 dependencies:[m[m
   - name: common[m[m
     repository: file://../../../charts/common[m[m
[31m-    version: "1.9.0"[m[m
[32m+[m[32m    version: "1.10.0"[m[m
[1mdiff --git a/test/fixtures/clusterexternalsecret/Chart.lock b/test/fixtures/clusterexternalsecret/Chart.lock[m[m
[1mindex 4bc1611..f59001e 100644[m[m
[1m--- a/test/fixtures/clusterexternalsecret/Chart.lock[m[m
[1m+++ b/test/fixtures/clusterexternalsecret/Chart.lock[m[m
[36m@@ -1,6 +1,6 @@[m[m
 dependencies:[m[m
 - name: common[m[m
   repository: file://../../../charts/common[m[m
[31m-  version: 1.9.0[m[m
[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[31m-generated: "2025-12-17T15:09:29.144067-06:00"[m[m
[32m+[m[32m  version: 1.10.0[m[m
[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[32m+[m[32mgenerated: "2025-12-18T15:48:29.001689-06:00"[m[m
[1mdiff --git a/test/fixtures/clusterexternalsecret/Chart.yaml b/test/fixtures/clusterexternalsecret/Chart.yaml[m[m
[1mindex a340089..3930d4f 100644[m[m
[1m--- a/test/fixtures/clusterexternalsecret/Chart.yaml[m[m
:[K[K[1m+++ b/test/fixtures/clusterexternalsecret/Chart.yaml[m[m
[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
 dependencies:[m[m
   - name: common[m[m
     repository: file://../../../charts/common[m[m
[31m-    version: "1.9.0"[m[m
[32m+[m[32m    version: "1.10.0"[m[m
[1mdiff --git a/test/fixtures/configmaps/Chart.lock b/test/fixtures/configmaps/Chart.lock[m[m
[1mindex 383ed3b..089e894 100644[m[m
[1m--- a/test/fixtures/configmaps/Chart.lock[m[m
[1m+++ b/test/fixtures/configmaps/Chart.lock[m[m
[36m@@ -1,6 +1,6 @@[m[m
 dependencies:[m[m
 - name: common[m[m
   repository: file://../../../charts/common[m[m
[31m-  version: 1.9.0[m[m
[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[31m-generated: "2025-12-17T15:09:30.263648-06:00"[m[m
[32m+[m[32m  version: 1.10.0[m[m
[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[32m+[m[32mgenerated: "2025-12-18T15:48:29.692511-06:00"[m[m
[1mdiff --git a/test/fixtures/configmaps/Chart.yaml b/test/fixtures/configmaps/Chart.yaml[m[m
[1mindex a340089..3930d4f 100644[m[m
[1m--- a/test/fixtures/configmaps/Chart.yaml[m[m
[1m+++ b/test/fixtures/configmaps/Chart.yaml[m[m
[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
 dependencies:[m[m
   - name: common[m[m
     repository: file://../../../charts/common[m[m
[31m-    version: "1.9.0"[m[m
[32m+[m[32m    version: "1.10.0"[m[m
[1mdiff --git a/test/fixtures/containers/Chart.lock b/test/fixtures/containers/Chart.lock[m[m
[1mindex fc0b43f..e385b7c 100644[m[m
[1m--- a/test/fixtures/containers/Chart.lock[m[m
[1m+++ b/test/fixtures/containers/Chart.lock[m[m
[36m@@ -1,6 +1,6 @@[m[m
 dependencies:[m[m
 - name: common[m[m
   repository: file://../../../charts/common[m[m
[31m-  version: 1.9.0[m[m
:[K[K[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[31m-generated: "2025-12-17T15:09:31.391356-06:00"[m[m
[32m+[m[32m  version: 1.10.0[m[m
[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[32m+[m[32mgenerated: "2025-12-18T15:48:30.41571-06:00"[m[m
[1mdiff --git a/test/fixtures/containers/Chart.yaml b/test/fixtures/containers/Chart.yaml[m[m
[1mindex a340089..3930d4f 100644[m[m
[1m--- a/test/fixtures/containers/Chart.yaml[m[m
[1m+++ b/test/fixtures/containers/Chart.yaml[m[m
[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
 dependencies:[m[m
   - name: common[m[m
     repository: file://../../../charts/common[m[m
[31m-    version: "1.9.0"[m[m
[32m+[m[32m    version: "1.10.0"[m[m
[1mdiff --git a/test/fixtures/cronjobs/Chart.lock b/test/fixtures/cronjobs/Chart.lock[m[m
[1mindex 081fe8b..12fdb2a 100644[m[m
[1m--- a/test/fixtures/cronjobs/Chart.lock[m[m
[1m+++ b/test/fixtures/cronjobs/Chart.lock[m[m
[36m@@ -1,6 +1,6 @@[m[m
 dependencies:[m[m
 - name: common[m[m
   repository: file://../../../charts/common[m[m
[31m-  version: 1.9.0[m[m
[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[31m-generated: "2025-12-17T15:09:32.450577-06:00"[m[m
[32m+[m[32m  version: 1.10.0[m[m
[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[32m+[m[32mgenerated: "2025-12-18T15:48:31.352985-06:00"[m[m
[1mdiff --git a/test/fixtures/cronjobs/Chart.yaml b/test/fixtures/cronjobs/Chart.yaml[m[m
[1mindex a340089..3930d4f 100644[m[m
[1m--- a/test/fixtures/cronjobs/Chart.yaml[m[m
[1m+++ b/test/fixtures/cronjobs/Chart.yaml[m[m
[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
 dependencies:[m[m
   - name: common[m[m
     repository: file://../../../charts/common[m[m
[31m-    version: "1.9.0"[m[m
[32m+[m[32m    version: "1.10.0"[m[m
[1mdiff --git a/test/fixtures/deployments/Chart.lock b/test/fixtures/deployments/Chart.lock[m[m
:[K[K[1mindex 7ff4ddb..bc38e20 100644[m[m
[1m--- a/test/fixtures/deployments/Chart.lock[m[m
[1m+++ b/test/fixtures/deployments/Chart.lock[m[m
[36m@@ -1,6 +1,6 @@[m[m
 dependencies:[m[m
 - name: common[m[m
   repository: file://../../../charts/common[m[m
[31m-  version: 1.9.0[m[m
[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[31m-generated: "2025-12-17T15:09:38.012485-06:00"[m[m
[32m+[m[32m  version: 1.10.0[m[m
[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[32m+[m[32mgenerated: "2025-12-18T15:48:32.086635-06:00"[m[m
[1mdiff --git a/test/fixtures/deployments/Chart.yaml b/test/fixtures/deployments/Chart.yaml[m[m
[1mindex a340089..3930d4f 100644[m[m
[1m--- a/test/fixtures/deployments/Chart.yaml[m[m
[1m+++ b/test/fixtures/deployments/Chart.yaml[m[m
[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
 dependencies:[m[m
   - name: common[m[m
     repository: file://../../../charts/common[m[m
[31m-    version: "1.9.0"[m[m
[32m+[m[32m    version: "1.10.0"[m[m
[1mdiff --git a/test/fixtures/ingresses/Chart.lock b/test/fixtures/ingresses/Chart.lock[m[m
[1mindex 667c567..c657dbe 100644[m[m
[1m--- a/test/fixtures/ingresses/Chart.lock[m[m
[1m+++ b/test/fixtures/ingresses/Chart.lock[m[m
[36m@@ -1,6 +1,6 @@[m[m
 dependencies:[m[m
 - name: common[m[m
   repository: file://../../../charts/common[m[m
[31m-  version: 1.9.0[m[m
[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[31m-generated: "2025-12-17T15:09:39.098876-06:00"[m[m
[32m+[m[32m  version: 1.10.0[m[m
[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[32m+[m[32mgenerated: "2025-12-18T15:48:32.804286-06:00"[m[m
[1mdiff --git a/test/fixtures/ingresses/Chart.yaml b/test/fixtures/ingresses/Chart.yaml[m[m
[1mindex a340089..3930d4f 100644[m[m
[1m--- a/test/fixtures/ingresses/Chart.yaml[m[m
:[K[K[1m+++ b/test/fixtures/ingresses/Chart.yaml[m[m
[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
 dependencies:[m[m
   - name: common[m[m
     repository: file://../../../charts/common[m[m
[31m-    version: "1.9.0"[m[m
[32m+[m[32m    version: "1.10.0"[m[m
[1mdiff --git a/test/fixtures/jobs/Chart.lock b/test/fixtures/jobs/Chart.lock[m[m
[1mindex 56db834..421b54a 100644[m[m
[1m--- a/test/fixtures/jobs/Chart.lock[m[m
[1m+++ b/test/fixtures/jobs/Chart.lock[m[m
[36m@@ -1,6 +1,6 @@[m[m
 dependencies:[m[m
 - name: common[m[m
   repository: file://../../../charts/common[m[m
[31m-  version: 1.9.0[m[m
[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[31m-generated: "2025-12-17T15:09:40.153238-06:00"[m[m
[32m+[m[32m  version: 1.10.0[m[m
[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[32m+[m[32mgenerated: "2025-12-18T15:48:33.78433-06:00"[m[m
[1mdiff --git a/test/fixtures/jobs/Chart.yaml b/test/fixtures/jobs/Chart.yaml[m[m
[1mindex a340089..3930d4f 100644[m[m
[1m--- a/test/fixtures/jobs/Chart.yaml[m[m
[1m+++ b/test/fixtures/jobs/Chart.yaml[m[m
[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
 dependencies:[m[m
   - name: common[m[m
     repository: file://../../../charts/common[m[m
[31m-    version: "1.9.0"[m[m
[32m+[m[32m    version: "1.10.0"[m[m
[1mdiff --git a/test/fixtures/microservice/Chart.lock b/test/fixtures/microservice/Chart.lock[m[m
[1mindex 175e535..5e09d6a 100644[m[m
[1m--- a/test/fixtures/microservice/Chart.lock[m[m
[1m+++ b/test/fixtures/microservice/Chart.lock[m[m
[36m@@ -1,6 +1,6 @@[m[m
 dependencies:[m[m
 - name: common[m[m
   repository: file://../../../charts/common[m[m
[31m-  version: 1.9.0[m[m
:[K[K[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[31m-generated: "2025-12-17T15:09:41.172052-06:00"[m[m
[32m+[m[32m  version: 1.10.0[m[m
[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[32m+[m[32mgenerated: "2025-12-18T15:48:34.458044-06:00"[m[m
[1mdiff --git a/test/fixtures/microservice/Chart.yaml b/test/fixtures/microservice/Chart.yaml[m[m
[1mindex a340089..3930d4f 100644[m[m
[1m--- a/test/fixtures/microservice/Chart.yaml[m[m
[1m+++ b/test/fixtures/microservice/Chart.yaml[m[m
[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
 dependencies:[m[m
   - name: common[m[m
     repository: file://../../../charts/common[m[m
[31m-    version: "1.9.0"[m[m
[32m+[m[32m    version: "1.10.0"[m[m
[1mdiff --git a/test/fixtures/podspec/Chart.lock b/test/fixtures/podspec/Chart.lock[m[m
[1mindex 81d141e..fe1822a 100644[m[m
[1m--- a/test/fixtures/podspec/Chart.lock[m[m
[1m+++ b/test/fixtures/podspec/Chart.lock[m[m
[36m@@ -1,6 +1,6 @@[m[m
 dependencies:[m[m
 - name: common[m[m
   repository: file://../../../charts/common[m[m
[31m-  version: 1.9.0[m[m
[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[31m-generated: "2025-12-17T15:09:42.257485-06:00"[m[m
[32m+[m[32m  version: 1.10.0[m[m
[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[32m+[m[32mgenerated: "2025-12-18T15:48:35.155465-06:00"[m[m
[1mdiff --git a/test/fixtures/podspec/Chart.yaml b/test/fixtures/podspec/Chart.yaml[m[m
[1mindex a340089..3930d4f 100644[m[m
[1m--- a/test/fixtures/podspec/Chart.yaml[m[m
[1m+++ b/test/fixtures/podspec/Chart.yaml[m[m
[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
 dependencies:[m[m
   - name: common[m[m
     repository: file://../../../charts/common[m[m
[31m-    version: "1.9.0"[m[m
[32m+[m[32m    version: "1.10.0"[m[m
[1mdiff --git a/test/fixtures/statefulsets/Chart.lock b/test/fixtures/statefulsets/Chart.lock[m[m
:[K[K[1mindex 972d85f..e0ee5a1 100644[m[m
[1m--- a/test/fixtures/statefulsets/Chart.lock[m[m
[1m+++ b/test/fixtures/statefulsets/Chart.lock[m[m
[36m@@ -1,6 +1,6 @@[m[m
 dependencies:[m[m
 - name: common[m[m
   repository: file://../../../charts/common[m[m
[31m-  version: 1.9.0[m[m
[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[31m-generated: "2025-12-17T15:09:43.332944-06:00"[m[m
[32m+[m[32m  version: 1.10.0[m[m
[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[32m+[m[32mgenerated: "2025-12-18T15:48:35.830031-06:00"[m[m
[1mdiff --git a/test/fixtures/statefulsets/Chart.yaml b/test/fixtures/statefulsets/Chart.yaml[m[m
[1mindex a340089..3930d4f 100644[m[m
[1m--- a/test/fixtures/statefulsets/Chart.yaml[m[m
[1m+++ b/test/fixtures/statefulsets/Chart.yaml[m[m
[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
 dependencies:[m[m
   - name: common[m[m
     repository: file://../../../charts/common[m[m
[31m-    version: "1.9.0"[m[m
[32m+[m[32m    version: "1.10.0"[m[m
[1mdiff --git a/test/test_cronjobs.bats b/test/test_cronjobs.bats[m[m
[1mindex ba9641f..718d4a0 100644[m[m
[1m--- a/test/test_cronjobs.bats[m[m
[1m+++ b/test/test_cronjobs.bats[m[m
[36m@@ -19,7 +19,7 @@[m [mteardown() {[m[m
        assert_output --partial 'test.override.annotation: hello-override-world'[m[m
   assert_output --partial 'testOverrideLabel: hello-override-world'[m[m
   assert_output --partial 'name: test-cronjobs'[m[m
[31m-  assert_output --partial 'podAntiAffinity'[m[m
[32m+[m[32m  assert_output --partial 'nodeAffinity'[m[m
   assert_output --partial 'schedule: "0 * * * *"'[m[m
 }[m[m
 [m[m
[1mdiff --git a/test/test_jobs.bats b/test/test_jobs.bats[m[m
[1mindex 66a463b..b2b3dce 100644[m[m
[1m--- a/test/test_jobs.bats[m[m
[1m+++ b/test/test_jobs.bats[m[m
:[K[K[36m@@ -16,7 +16,7 @@[m [mteardown() {[m[m
   run helm template -f test/fixtures/jobs/values-basic.yaml test/fixtures/jobs/[m[m
   assert_output --partial 'kind: Job'[m[m
   assert_output --partial 'helm.sh/hook: pre-install,pre-upgrade'[m[m
[31m-  assert_output --partial 'podAntiAffinity'[m[m
[32m+[m[32m  assert_output --partial 'nodeAffinity'[m[m
 }[m[m
 [m[m
 # bats test_tags=tag:basic[m[m
[1mdiff --git a/test/test_pod_affinity.bats b/test/test_pod_affinity.bats[m[m
[1mindex 2d3e846..4b9e0b3 100644[m[m
[1m--- a/test/test_pod_affinity.bats[m[m
[1m+++ b/test/test_pod_affinity.bats[m[m
[36m@@ -36,5 +36,5 @@[m [mteardown() {[m[m
 # bats test_tags=tag:affinity-disabled[m[m
 @test "affinity: allows disabling automatic anti-affinity" {[m[m
   run helm template -f test/fixtures/affinity/values-anti-affinity-disabled.yaml test/fixtures/affinity/[m[m
[31m-  refute_output --partial 'podAntiAffinity'[m[m
[32m+[m[32m  refute_output --partial 'karpenter.sh/controller'[m[m
 }[m[m
[3m(END)[23m[K[K[K[3m(END)[23m[K[K[K[3m(END)[23m[K[K[K[3m(END)[23m[K[K[K[3m(END)[23m[K[K[K[3m(END)[23m[K[K[K[3m(END)[23m[K[K[K[3m(END)[23m[K[K[K[3m(END)[23m[K[K[K[3m(END)[23m[K[K[K[3m(END)[23m[K[K[K[3m(END)[23m[K[K[K[3m(END)[23m[K[K[HM   - name: common[m[m
[HM dependencies:[m[m
[HM[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
[HM[1m+++ b/test/fixtures/statefulsets/Chart.yaml[m[m
[HM[1m--- a/test/fixtures/statefulsets/Chart.yaml[m[m
[HM[1mindex a340089..3930d4f 100644[m[m
[HM[1mdiff --git a/test/fixtures/statefulsets/Chart.yaml b/test/fixtures/statefulsets/Chart.yaml[m[m
[HM[32m+[m[32mgenerated: "2025-12-18T15:48:35.830031-06:00"[m[m
[HM[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[HM[32m+[m[32m  version: 1.10.0[m[m
[HM[31m-generated: "2025-12-17T15:09:43.332944-06:00"[m[m
[HM[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[HM[31m-  version: 1.9.0[m[m
[HM   repository: file://../../../charts/common[m[m
[HM - name: common[m[m
[HM dependencies:[m[m
[HM[36m@@ -1,6 +1,6 @@[m[m
[HM[1m+++ b/test/fixtures/statefulsets/Chart.lock[m[m
[HM[1m--- a/test/fixtures/statefulsets/Chart.lock[m[m
[HM[1mindex 972d85f..e0ee5a1 100644[m[m
[HM[1mdiff --git a/test/fixtures/statefulsets/Chart.lock b/test/fixtures/statefulsets/Chart.lock[m[m
[HM[32m+[m[32m    version: "1.10.0"[m[m
[HM[31m-    version: "1.9.0"[m[m
[HM     repository: file://../../../charts/common[m[m
[HM   - name: common[m[m
[HM dependencies:[m[m
[HM[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
[HM[1m+++ b/test/fixtures/podspec/Chart.yaml[m[m
[HM[1m--- a/test/fixtures/podspec/Chart.yaml[m[m
[HM[1mindex a340089..3930d4f 100644[m[m
[HM[1mdiff --git a/test/fixtures/podspec/Chart.yaml b/test/fixtures/podspec/Chart.yaml[m[m
[HM[32m+[m[32mgenerated: "2025-12-18T15:48:35.155465-06:00"[m[m
[HM[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[HM[32m+[m[32m  version: 1.10.0[m[m
[HM[31m-generated: "2025-12-17T15:09:42.257485-06:00"[m[m
[HM[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[HM[31m-  version: 1.9.0[m[m
[HM   repository: file://../../../charts/common[m[m
[HM - name: common[m[m
[HM dependencies:[m[m
[41;1H[K:[K[K[HM[36m@@ -1,6 +1,6 @@[m[m
[HM[1m+++ b/test/fixtures/podspec/Chart.lock[m[m
[HM[1m--- a/test/fixtures/podspec/Chart.lock[m[m
[HM[1mindex 81d141e..fe1822a 100644[m[m
[HM[1mdiff --git a/test/fixtures/podspec/Chart.lock b/test/fixtures/podspec/Chart.lock[m[m
[HM[32m+[m[32m    version: "1.10.0"[m[m
[HM[31m-    version: "1.9.0"[m[m
[HM     repository: file://../../../charts/common[m[m
[HM   - name: common[m[m
[HM dependencies:[m[m
[HM[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
[HM[1m+++ b/test/fixtures/microservice/Chart.yaml[m[m
[HM[1m--- a/test/fixtures/microservice/Chart.yaml[m[m
[HM[1mindex a340089..3930d4f 100644[m[m
[HM[1mdiff --git a/test/fixtures/microservice/Chart.yaml b/test/fixtures/microservice/Chart.yaml[m[m
[HM[32m+[m[32mgenerated: "2025-12-18T15:48:34.458044-06:00"[m[m
[HM[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[HM[32m+[m[32m  version: 1.10.0[m[m
[HM[31m-generated: "2025-12-17T15:09:41.172052-06:00"[m[m
[HM[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[HM[31m-  version: 1.9.0[m[m
[HM   repository: file://../../../charts/common[m[m
[HM - name: common[m[m
[HM dependencies:[m[m
[HM[36m@@ -1,6 +1,6 @@[m[m
[HM[1m+++ b/test/fixtures/microservice/Chart.lock[m[m
[HM[1m--- a/test/fixtures/microservice/Chart.lock[m[m
[HM[1mindex 175e535..5e09d6a 100644[m[m
[HM[1mdiff --git a/test/fixtures/microservice/Chart.lock b/test/fixtures/microservice/Chart.lock[m[m
[HM[32m+[m[32m    version: "1.10.0"[m[m
[HM[31m-    version: "1.9.0"[m[m
[HM     repository: file://../../../charts/common[m[m
[HM   - name: common[m[m
[HM dependencies:[m[m
[HM[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
[HM[1m+++ b/test/fixtures/jobs/Chart.yaml[m[m
[HM[1m--- a/test/fixtures/jobs/Chart.yaml[m[m
[HM[1mindex a340089..3930d4f 100644[m[m
[HM[1mdiff --git a/test/fixtures/jobs/Chart.yaml b/test/fixtures/jobs/Chart.yaml[m[m
[HM[32m+[m[32mgenerated: "2025-12-18T15:48:33.78433-06:00"[m[m
[41;1H[K:[K[K[HM[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[HM[32m+[m[32m  version: 1.10.0[m[m
[HM[31m-generated: "2025-12-17T15:09:40.153238-06:00"[m[m
[HM[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[HM[31m-  version: 1.9.0[m[m
[HM   repository: file://../../../charts/common[m[m
[HM - name: common[m[m
[HM dependencies:[m[m
[HM[36m@@ -1,6 +1,6 @@[m[m
[HM[1m+++ b/test/fixtures/jobs/Chart.lock[m[m
[HM[1m--- a/test/fixtures/jobs/Chart.lock[m[m
[HM[1mindex 56db834..421b54a 100644[m[m
[HM[1mdiff --git a/test/fixtures/jobs/Chart.lock b/test/fixtures/jobs/Chart.lock[m[m
[HM[32m+[m[32m    version: "1.10.0"[m[m
[HM[31m-    version: "1.9.0"[m[m
[HM     repository: file://../../../charts/common[m[m
[HM   - name: common[m[m
[HM dependencies:[m[m
[HM[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
[HM[1m+++ b/test/fixtures/ingresses/Chart.yaml[m[m
[HM[1m--- a/test/fixtures/ingresses/Chart.yaml[m[m
[HM[1mindex a340089..3930d4f 100644[m[m
[HM[1mdiff --git a/test/fixtures/ingresses/Chart.yaml b/test/fixtures/ingresses/Chart.yaml[m[m
[HM[32m+[m[32mgenerated: "2025-12-18T15:48:32.804286-06:00"[m[m
[HM[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[HM[32m+[m[32m  version: 1.10.0[m[m
[HM[31m-generated: "2025-12-17T15:09:39.098876-06:00"[m[m
[HM[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[HM[31m-  version: 1.9.0[m[m
[HM   repository: file://../../../charts/common[m[m
[HM - name: common[m[m
[HM dependencies:[m[m
[HM[36m@@ -1,6 +1,6 @@[m[m
[HM[1m+++ b/test/fixtures/ingresses/Chart.lock[m[m
[HM[1m--- a/test/fixtures/ingresses/Chart.lock[m[m
[HM[1mindex 667c567..c657dbe 100644[m[m
[HM[1mdiff --git a/test/fixtures/ingresses/Chart.lock b/test/fixtures/ingresses/Chart.lock[m[m
[HM[32m+[m[32m    version: "1.10.0"[m[m
[HM[31m-    version: "1.9.0"[m[m
[HM     repository: file://../../../charts/common[m[m
[41;1H[K:[K[K[HM   - name: common[m[m
[HM dependencies:[m[m
[HM[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
[HM[1m+++ b/test/fixtures/deployments/Chart.yaml[m[m
[HM[1m--- a/test/fixtures/deployments/Chart.yaml[m[m
[HM[1mindex a340089..3930d4f 100644[m[m
[HM[1mdiff --git a/test/fixtures/deployments/Chart.yaml b/test/fixtures/deployments/Chart.yaml[m[m
[HM[32m+[m[32mgenerated: "2025-12-18T15:48:32.086635-06:00"[m[m
[HM[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[HM[32m+[m[32m  version: 1.10.0[m[m
[HM[31m-generated: "2025-12-17T15:09:38.012485-06:00"[m[m
[HM[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[HM[31m-  version: 1.9.0[m[m
[HM   repository: file://../../../charts/common[m[m
[HM - name: common[m[m
[HM dependencies:[m[m
[HM[36m@@ -1,6 +1,6 @@[m[m
[HM[1m+++ b/test/fixtures/deployments/Chart.lock[m[m
[HM[1m--- a/test/fixtures/deployments/Chart.lock[m[m
[HM[1mindex 7ff4ddb..bc38e20 100644[m[m
[HM[1mdiff --git a/test/fixtures/deployments/Chart.lock b/test/fixtures/deployments/Chart.lock[m[m
[HM[32m+[m[32m    version: "1.10.0"[m[m
[HM[31m-    version: "1.9.0"[m[m
[HM     repository: file://../../../charts/common[m[m
[HM   - name: common[m[m
[HM dependencies:[m[m
[HM[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
[HM[1m+++ b/test/fixtures/cronjobs/Chart.yaml[m[m
[HM[1m--- a/test/fixtures/cronjobs/Chart.yaml[m[m
[HM[1mindex a340089..3930d4f 100644[m[m
[HM[1mdiff --git a/test/fixtures/cronjobs/Chart.yaml b/test/fixtures/cronjobs/Chart.yaml[m[m
[HM[32m+[m[32mgenerated: "2025-12-18T15:48:31.352985-06:00"[m[m
[HM[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[HM[32m+[m[32m  version: 1.10.0[m[m
[HM[31m-generated: "2025-12-17T15:09:32.450577-06:00"[m[m
[HM[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[HM[31m-  version: 1.9.0[m[m
[HM   repository: file://../../../charts/common[m[m
[HM - name: common[m[m
[HM dependencies:[m[m
[41;1H[K:[K[K[?1l>[1m[3m%[23m[1m[0m                                                                                                                                                             k..t/helm-charts\]7;file://negroni/Users/chris.reisor/git/helm-charts\[0m[23m[24m[J[01;32mchris.reisor@negroni[00m [01;34mgit/helm-charts[00m [33m(INFRASEC-4257-affinity-and-topology) [00m[00m[1m»[0m [K[?1h=[6 q[?2004hmmake test[?1l>[0 q[?2004l
kmake\BATSLIB_TEMP_PRESERVE_ON_FAILURE=1 AWS_PROFILE= test/bats/bin/bats --filter-tags tag:all test/
[34;1mtest_autoscaler.bats
[0m[1G   autoscaler: outputs a template[K[150G  1/111[2G[1G ✓ autoscaler: outputs a template[K
[0m[1G   autoscaler: matches expected output[K[150G  2/111[2G[1G ✓ autoscaler: matches expected output[K
[0m[1G   autoscaler: if a minReplicas value is not provided, a defualt is used[K[150G  3/111[2G[1G ✓ autoscaler: if a minReplicas value is not provided, a defualt is used[K
[0m[1G   autoscaler: if a maxReplicas value is not provided, a defualt is used[K[150G  4/111[2G[1G ✓ autoscaler: if a maxReplicas value is not provided, a defualt is used[K
[0m[1G   autoscaler: overrides the averageUtilization value if provided[K[150G  5/111[2G[1G ✓ autoscaler: overrides the averageUtilization value if provided[K
[0m[1G   autoscaler: cretes a memory resource utilization target if provided[K[150G  6/111[2G[1G ✓ autoscaler: cretes a memory resource utilization target if provided[K
[0m[34;1mtest_clusterexternalsecret.bats
[0m[1G   clusterexternalsecret: outputs a template[K[150G  7/111[2G[1G ✓ clusterexternalsecret: outputs a template[K
[0m[1G   clusterexternalsecret: matches expected output[K[150G  8/111[2G[1G ✓ clusterexternalsecret: matches expected output[K
[0m[1G   clusterexternalsecret: allows overriding apiVersion[K[150G  9/111[2G[1G ✓ clusterexternalsecret: allows overriding apiVersion[K
[0m[34;1mtest_configmaps.bats
[0m[1G   configmaps: outputs a template[K[150G 10/111[2G[1G ✓ configmaps: outputs a template[K
[0m[1G   configmaps: matches expected output[K[150G 11/111[2G[1G ✓ configmaps: matches expected output[K
[0m[1G   configmaps: file templating works[K[150G 12/111[2G[1G ✓ configmaps: file templating works[K
[0m[1G   configmaps: inline templating works[K[150G 13/111[2G[1G ✓ configmaps: inline templating works[K
[0m[1G   configmaps: multiple templates works[K[150G 14/111[2G[1G ✓ configmaps: multiple templates works[K
[0m[1G   configmaps: inline multiple templates works[K[150G 15/111[2G[1G ✓ configmaps: inline multiple templates works[K
[0m[1G   configmaps: dumps contents of a file[K[150G 16/111[2G[1G ✓ configmaps: dumps contents of a file[K
[0m[1G   configmaps: dumps contents of a json file[K[150G 17/111[2G[1G ✓ configmaps: dumps contents of a json file[K
[0m[1G   configmaps: dumps contents of a yaml file[K[150G 18/111[2G[1G ✓ configmaps: dumps contents of a yaml file[K
[0m[34;1mtest_containers.bats
[0m[1G   containers: outputs a template[K[150G 19/111[2G[1G ✓ containers: outputs a template[K
[0m[1G   containers: matches expected output[K[150G 20/111[2G[1G ✓ containers: matches expected output[K
[0m[1G   containers: fails when containers are specified as a list[K[150G 21/111[2G[1G ✓ containers: fails when containers are specified as a list[K
[0m[1G   containers: fails when initContainers have no resources[K[150G 22/111[2G[1G ✓ containers: fails when initContainers have no resources[K
[0m[1G   containers: fails when initContainers are specified as a map[K[150G 23/111[2G[1G ✓ containers: fails when initContainers are specified as a map[K
[0m[1G   containers: fails when no image is specified[K[150G 24/111[2G[1G ✓ containers: fails when no image is specified[K
[0m[1G   containers: fails when no livenessProbe is specified[K[150G 25/111[2G[1G ✓ containers: fails when no livenessProbe is specified[K
[0m[1G   containers: does not include livenessProbe if disabled[K[150G 26/111[2G[1G ✓ containers: does not include livenessProbe if disabled[K
[0m[1G   containers: overrides livenessProbe defaults[K[150G 27/111[2G[1G ✓ containers: overrides livenessProbe defaults[K
[0m[1G   containers: fails when no readinessProbe is specified[K[150G 28/111[2G[1G ✓ containers: fails when no readinessProbe is specified[K
[0m[1G   containers: does not include readinessProbe if disabled[K[150G 29/111[2G[1G ✓ containers: does not include readinessProbe if disabled[K
[0m[1G   containers: overrides readinessProbe defaults[K[150G 30/111[2G[1G ✓ containers: overrides readinessProbe defaults[K
[0m[1G   containers: fails when no resources are specified[K[150G 31/111[2G[1G ✓ containers: fails when no resources are specified[K
[0m[1G   containers: includes CLUSTER_NAME env var if gitops bridge specifies it in spec[K[150G 32/111[2G[1G ✓ containers: includes CLUSTER_NAME env var if gitops bridge specifies it in spec[K
[0m[34;1mtest_cronjobs.bats
[0m[1G   cronjobs: outputs a template[K[150G 33/111[2G[1G ✓ cronjobs: outputs a template[K
[0m[1G   cronjobs: matches expected output[K[150G 34/111[2G[1G ✓ cronjobs: matches expected output[K
[0m[1G   cronjobs: includes service account if specified in the global section[K[150G 35/111[2G[1G ✓ cronjobs: includes service account if specified in the global section[K
[0m[1G   cronjobs: includes service account if specified[K[150G 36/111[2G[1G ✓ cronjobs: includes service account if specified[K
[0m[1G   cronjobs: suspends job if disabled is true[K[150G 37/111[2G[1G ✓ cronjobs: suspends job if disabled is true[K
[0m[1G   cronjobs: overrides default concurrencyPolicy[K[150G 38/111[2G[1G ✓ cronjobs: overrides default concurrencyPolicy[K
[0m[1G   cronjobs: overrides default failedJobsHistoryLimit[K[150G 39/111[2G[1G ✓ cronjobs: overrides default failedJobsHistoryLimit[K
[0m[1G   cronjobs: overrides default successfulJobsHistoryLimit[K[150G 40/111[2G[1G ✓ cronjobs: overrides default successfulJobsHistoryLimit[K
[0m[1G   cronjobs: adds startingDeadlineSeconds if defined[K[150G 41/111[2G[1G ✓ cronjobs: adds startingDeadlineSeconds if defined[K
[0m[1G   cronjobs: fails when no scheudle is defined[K[150G 42/111[2G[1G ✓ cronjobs: fails when no scheudle is defined[K
[0m[1G   cronjobs: includes timeZone if specified[K[150G 43/111[2G[1G ✓ cronjobs: includes timeZone if specified[K
[0m[34;1mtest_deployments.bats
[0m[1G   deployments: outputs a template[K[150G 44/111[2G[1G ✓ deployments: outputs a template[K
[0m[1G   deployments: matches expected output[K[150G 45/111[2G[1G ✓ deployments: matches expected output[K
[0m[1G   deployments: specify the selector[K[150G 46/111[2G[1G ✓ deployments: specify the selector[K
[0m[1G   deployments: if there is no global serviceAccount, uses the one in the deployment[K[150G 47/111[2G[1G - deployments: if there is no global serviceAccount, uses the one in the deployment (skipped: this should work, but it doesn't (see also the skipped cronjobs test))[K
[0m[1G   deployments: adds serviceAccount role if specified[K[150G 48/111[2G[1G ✓ deployments: adds serviceAccount role if specified[K
[0m[1G   deployments: forces type to string when awsAccountId is unquoted[K[150G 49/111[2G[1G ✓ deployments: forces type to string when awsAccountId is unquoted[K
[0m[1G   deployments: renders ClusterExternalSecret if secrets are included[K[150G 50/111[2G[1G ✓ deployments: renders ClusterExternalSecret if secrets are included[K
[0m[1G   deployments: renders podDisruptionBudget if included[K[150G 51/111[2G[1G ✓ deployments: renders podDisruptionBudget if included[K
[0m[1G   deployments: renders podDisruptionBudget with maxUnavailable[K[150G 52/111[2G[1G ✓ deployments: renders podDisruptionBudget with maxUnavailable[K
[0m[1G   deployments: renders podDisruptionBudget with minAvailable as a percentage[K[150G 53/111[2G[1G ✓ deployments: renders podDisruptionBudget with minAvailable as a percentage[K
[0m[1G   deployments: ensures a separate document between all deployments when PDBs are defined[K[150G 54/111[2G[1G ✓ deployments: ensures a separate document between all deployments when PDBs are defined[K
[0m[34;1mtest_ingresses.bats
[0m[1G   oauth: outputs a template with auth annotations[K[150G 55/111[2G[1G ✓ oauth: outputs a template with auth annotations[K
[0m[1G   ouath: matches expected output[K[150G 56/111[2G[1G ✓ ouath: matches expected output[K
[0m[1G   nodns: outputs a template with no external-dns annotation[K[150G 57/111[2G[1G ✓ nodns: outputs a template with no external-dns annotation[K
[0m[1G   nodns: matches expected output[K[150G 58/111[2G[1G ✓ nodns: matches expected output[K
[0m[1G   basicauth: outputs a template with no external-dns annotation[K[150G 59/111[2G[1G ✓ basicauth: outputs a template with no external-dns annotation[K
[0m[1G   basicauth: matches expected output[K[150G 60/111[2G[1G ✓ basicauth: matches expected output[K
[0m[1G   nginx-external: outputs a template with an ingress class name called nginx[K[150G 61/111[2G[1G ✓ nginx-external: outputs a template with an ingress class name called nginx[K
[0m[1G   nginx-external: matches expected output[K[150G 62/111[2G[1G ✓ nginx-external: matches expected output[K
[0m[1G   nginx-ingress: fails if service is not specified[K[150G 63/111[2G[1G ✓ nginx-ingress: fails if service is not specified[K
[0m[1G   basicauth: uses appDomain and rootDomain to construct a hostname if none specified[K[150G 64/111[2G[1G ✓ basicauth: uses appDomain and rootDomain to construct a hostname if none specified[K
[0m[1G   alb-internal: matches expected output[K[150G 65/111[2G[1G ✓ alb-internal: matches expected output[K
[0m[1G   alb-external: sets scheme[K[150G 66/111[2G[1G ✓ alb-external: sets scheme[K
[0m[1G   alb-scheme-error: ensures a scheme is set[K[150G 67/111[2G[1G ✓ alb-scheme-error: ensures a scheme is set[K
[0m[1G   alb-certarn-error: ensures a certificateArn is set[K[150G 68/111[2G[1G ✓ alb-certarn-error: ensures a certificateArn is set[K
[0m[1G   gitops-bridge: if Values has a spec field (usually from Gitops Bridge), ensure annotations are set[K[150G 69/111[2G[1G ✓ gitops-bridge: if Values has a spec field (usually from Gitops Bridge), ensure annotations are set[K
[0m[1G   default-alb: if no ingressClass is set, default to alb[K[150G 70/111[2G[1G ✓ default-alb: if no ingressClass is set, default to alb[K
[0m[1G   alb-imperva: sets imperva-related annotations and scheme[K[150G 71/111[2G[1G ✓ alb-imperva: sets imperva-related annotations and scheme[K
[0m[1G   alb-imperva-multiple-hostnames: sets imperva-related annotations and scheme with multiple hostnames[K[150G 72/111[2G[1G ✓ alb-imperva-multiple-hostnames: sets imperva-related annotations and scheme with multiple hostnames[K
[0m[1G   alb-imperva-internal-scheme: fails if the scheme is internal[K[150G 73/111[2G[1G ✓ alb-imperva-internal-scheme: fails if the scheme is internal[K
[0m[1G   alb-healthcheck-port: sets healthcheck-port annotation if specified[K[150G 74/111[2G[1G ✓ alb-healthcheck-port: sets healthcheck-port annotation if specified[K
[0m[1G   alb-healthcheck-protocol: sets healthcheck-protocl annotation if specified[K[150G 75/111[2G[1G ✓ alb-healthcheck-protocol: sets healthcheck-protocl annotation if specified[K
[0m[1G   alb-aliases: sets alb host header annotations with hostnameAliases[K[150G 76/111[2G[1G ✓ alb-aliases: sets alb host header annotations with hostnameAliases[K
[0m[1G   www-redirect: creates annotations to redirect base domain to www[K[150G 77/111[2G[1G ✓ www-redirect: creates annotations to redirect base domain to www[K
[0m[34;1mtest_jobs.bats
[0m[1G   jobs: outputs a template[K[150G 78/111[2G[1G ✓ jobs: outputs a template[K
[0m[1G   jobs: matches expected output[K[150G 79/111[2G[1G ✓ jobs: matches expected output[K
[0m[1G   jobs: backoffLimit gets set as expected[K[150G 80/111[2G[1G ✓ jobs: backoffLimit gets set as expected[K
[0m[1G   jobs: completions gets set as expected[K[150G 81/111[2G[1G ✓ jobs: completions gets set as expected[K
[0m[1G   jobs: parallelism gets set as expected[K[150G 82/111[2G[1G ✓ jobs: parallelism gets set as expected[K
[0m[1G   jobs: activeDeadlineSeconds gets set as expected[K[150G 83/111[2G[1G ✓ jobs: activeDeadlineSeconds gets set as expected[K
[0m[1G   jobs: restartPolicy gets overridden[K[150G 84/111[2G[1G ✓ jobs: restartPolicy gets overridden[K
[0m[1G   jobs: livenessProbe and readinessProbe get overridden[K[150G 85/111[2G[1G ✓ jobs: livenessProbe and readinessProbe get overridden[K
[0m[1G   jobs: uses job serviceAccount if there is no global one[K[150G 86/111[2G[1G - jobs: uses job serviceAccount if there is no global one (skipped: this should work, but it doesn't (see skipped test in cronjobs and deployments tests))[K
[0m[34;1mtest_microservice.bats
[0m[1G   microservice: outputs a template[K[150G 87/111[2G[1G ✓ microservice: outputs a template[K
[0m[1G   microservice: matches expected output[K[150G 88/111[2G[1G ✓ microservice: matches expected output[K
[0m[1G   microservice: fails when no global section is defined[K[150G 89/111[2G[1G ✓ microservice: fails when no global section is defined[K
[0m[1G   microservice: fails when no global labels are defined[K[150G 90/111[2G[1G ✓ microservice: fails when no global labels are defined[K
[0m[34;1mtest_pod_affinity.bats
[0m[1G   affinity: outputs a template[K[150G 91/111[2G[1G ✓ affinity: outputs a template[K
[0m[1G   affinity: matches expected output[K[150G 92/111[2G[1G ✓ affinity: matches expected output[K
[0m[1G   affinity: allows overriding the anti-affinity label[K[150G 93/111[2G[1G ✓ affinity: allows overriding the anti-affinity label[K
[0m[1G   affinity: allows disabling automatic anti-affinity[K[150G 94/111[2G[1G ✓ affinity: allows disabling automatic anti-affinity[K
[0m[34;1mtest_podspec.bats
[0m[1G   podspec: outputs a template[K[150G 95/111[2G[1G ✓ podspec: outputs a template[K
[0m[1G   podspec: matches expected output[K[150G 96/111[2G[1G ✓ podspec: matches expected output[K
[0m[1G   podspec: allows overriding topologySpreadConstraints[K[150G 97/111[2G[1G ✓ podspec: allows overriding topologySpreadConstraints[K
[0m[1G   podspec: default topologySpreadConstraints can override whenUnsatisfiable[K[150G 98/111[2G[1G ✓ podspec: default topologySpreadConstraints can override whenUnsatisfiable[K
[0m[1G   podspec: legacy topologySpreadConstraints syntax fails[K[150G 99/111[2G[1G ✓ podspec: legacy topologySpreadConstraints syntax fails[K
[0m[1G   podspec: specify the selector[K[150G100/111[2G[1G - podspec: specify the selector (skipped: this should work, but it doesn't -- in the future, look into lines 13-19 in _pod_spec.yaml.tpl)[K
[0m[1G   podspec: if there is no global serviceAccount, uses the one in the deployment[K[150G101/111[2G[1G - podspec: if there is no global serviceAccount, uses the one in the deployment (skipped: this should work, but it doesn't (see also the skipped cronjobs test))[K
[0m[1G   podspec: includes imagePullSecrets if there's a imagePullSecretsName[K[150G102/111[2G[1G ✓ podspec: includes imagePullSecrets if there's a imagePullSecretsName[K
[0m[1G   podspec: overrides serviceaccount set in pod[K[150G103/111[2G[1G - podspec: overrides serviceaccount set in pod (skipped: more problematic serviceAccount logic)[K
[0m[1G   podspec: disables service links if set[K[150G104/111[2G[1G ✓ podspec: disables service links if set[K
[0m[1G   podspec: overrides restartPolicy default of 'Always'[K[150G105/111[2G[1G ✓ podspec: overrides restartPolicy default of 'Always'[K
[0m[1G   podspec: sets fsGroupChangePolicy if the policy contains fsGroup[K[150G106/111[2G[1G ✓ podspec: sets fsGroupChangePolicy if the policy contains fsGroup[K
[0m[1G   podspec: overrides the default terminationGracePeriodSeconds[K[150G107/111[2G[1G ✓ podspec: overrides the default terminationGracePeriodSeconds[K
[0m[1G   podspec: helpful output when livenessProbe is removed[K[150G108/111[2G[1G ✓ podspec: helpful output when livenessProbe is removed[K
[0m[1G   podspec: helpful output when readinessProbe is removed[K[150G109/111[2G[1G ✓ podspec: helpful output when readinessProbe is removed[K
[0m[34;1mtest_statefulsets.bats
[0m[1G   statefulsets: outputs a template[K[150G110/111[2G[1G ✓ statefulsets: outputs a template[K
[0m[1G   statefulsets: matches expected output[K[150G111/111[2G[1G ✓ statefulsets: matches expected output[K
[0m[32;1m
111 tests, 0 failures, 5 skipped
[0m
[1m[3m%[23m[1m[0m                                                                                                                                                             k..t/helm-charts\]7;file://negroni/Users/chris.reisor/git/helm-charts\[0m[23m[24m[J[01;32mchris.reisor@negroni[00m [01;34mgit/helm-charts[00m [33m(INFRASEC-4257-affinity-and-topology) [00m[00m[1m»[0m [K[?1h=[6 q[?2004h
bck-i-search: _[KM[62Cg pus[4mh[24m[1B[69Dh_M[66C     [24m [1B[69D_ M[61C[H[J[0m[23m[24m[J[01;32mchris.reisor@negroni[00m [01;34mgit/helm-charts[00m [33m(INFRASEC-4257-affinity-and-topology) [00m[00m[1m»[0m [K
bck-i-search: _[KM[62Cg pus[4mh[24m[1B[69Dh_M[66Cuv ru[24mn github_org_stats.py --[4mhe[24mlp #--org provi-engineering --[1B[123De_M[89C[1C[4me[4ml[24m[1B[93Dl_M[88C[8P[24Coutput stats_failed_repos.csv --repos AdHaus HappyHourCustomerSkuMessageCreatorLambda HappyHourDistributorSelectorLambda HappyHourHistoricPricePersistorLambda ResturantMenuWebCrawler Semantic-UI Semantic-UI-React Terroir ZipToZoneFileCreator analytics analytics-draft api-listener argocd-orb asset_sync auth0 awsbastion-infra backbone-on-rails backup_dns bar-tab barback bartab beacon beacon_eks bevPOS bmg-bevsites bmg-bevsites-fedex-api bmg-eorders bmg-ets bmg-nysla bmg-subscription bootlegger bootlegger-bakeoff bootlegger-webhook-lambda-authorizer bootlegger-worker boozechoose bottle-shots bottler bottling-plant bouncer boxes brewery brewery_consumer buymore cheers cheers-backend cheers-frontend ci_metrics cicerone-lib cicerone-state-machines cluster-canary configtest-app configtest-config craft crm-sync crowdstrike-image-puller crowdstrike-terraform data_science_research datadog-terraform datawarehouse_migration delayed_job devmachine devops-onboarding disburse distiller distillery dockerfiles dockerized-beacon downstream dpinsert e2e_pilot ec2runner eks-upgrade-pipeline entity-matching-docker epicwin experian finix fizz-mobile-app fizzbook forklift forklift-lambda gh-admin-automation githooks glue-patcher happy-hour happy-hour-validation-service helm-charts_old [4mh[4melm[24m-deployments heroku-buildpack-ruby heroku-shared-postgres imperva-serverswap ingresstest interview-questions jenkins-kube-test jenkins-local jenkinsdeployer josefine kafka_api kyverno-policies license-parser liquid-analytics-sandbox loadtest looker mcgruff meltano mixologist mycoolworkload node-socket-wrap nysla nysla-maintenance onestackutilities pallet pallet_eks palletwebhooks payments-postman-collections pg_jbuilder pos-integrations post-office-api post-office-worker proof-read prosecco provi-ecs-events provi-eks provi-eks-workloads provi-imperva-client provi-scheduler-partner-batch-sf-api provi-sftp-scheduler-app provi-tradegecko provi_retailer_viz punchout-simulator puppeteer-heroku-buildpack qa-automation rails_phone react-native-config react-native-cookies recommendation-engine retailers_address_matching_lambdas rspec-retry rubybuilder sandbox sandbox-golang sauce sevenfiftydaily sfcore-ui siphond siphond-config skel slackcommands snowflake-flyway sns-to-slack-lambda-function sommelier sommelier-config speedrail-datafiles speedrail-dev-tools speedrail-ui state-manager state-manager-scripts sumologic_terraform supplier-service templates terraform-eks-lens victualler wine-cellar-validator wine-cellar-valildator[K
[K
bck-i-search: helm_[K[9A[9A[77C[4mh[4me[4ml[4mm[4m [24mrollback --help[K[1Bbck-i-search: helm _[K[1B[K[1B[K[1B[K[1B[K[1B[K[1B[K[1B[K[1B[K[1B[K[1B[K[1B[K[1B[K[1B[K[1B[K[1B[K[1B[K[1B[K[18A[77C[24mh[24me[24ml[24mm[24m [1Bfailing bck-i-search: helm t_M[48C[1B[49De_M[47C[1B[48Dm_M[46C[1B[47Dp_M[45C[1B[46Dl_M[44C[1B[45Da_M[43C[1B[44Dt_M[42C[1B[43De_M[41C                    [1B[KM[77C[1Bbck-i-search: _[KM[62Cmake tes[4mt[24m[1B[72Dt_M[69C[4mt[4me[24ms[24mt[1B[71De_M[65Ccat n[24mo[24mdepools/[4mtem[24mplates/default_v1.yaml| pbcopy[1B[108Dm_M[73C[2C[4mm[4mp[24m[1B[78Dp_M[72C[3C[4mp[4ml[24m[1B[78Dl_M[71C[4C[4ml[4ma[24m[1B[78Da_M[70C[5C[4ma[4mt[24m[1B[78Dt_M[69C[6C[4mt[4me[24m[1B[78De_M[68C[24mt[24me[24mm[24mp[24ml[24ma[24mt[24me[1Bfailing bck-i-search: template _M[59C[14D                                               [1B[KM[77Chhelm template -f [?2004l[1B[1m[3m%[23m[1m[0m                                                                                                                                                             k..t/helm-charts\]7;file://negroni/Users/chris.reisor/git/helm-charts\[0m[23m[24m[J[01;32mchris.reisor@negroni[00m [01;34mgit/helm-charts[00m [33m(INFRASEC-4257-affinity-and-topology) [00m[00m[1m»[0m [K[74C[01;31m130 ↵[00m[79D[?1h=[6 q[?2004h
bck-i-search: _[KM[62Cg pus[4mh[24m[1B[69Dh_M[66Cuv ru[24mn github_org_stats.py --[4mhe[24mlp #--org provi-engineering --[1B[123De_M[89C[1C[4me[4ml[24m[1B[93Dl_M[88C[8P[24Coutput stats_failed_repos.csv --repos AdHaus HappyHourCustomerSkuMessageCreatorLambda HappyHourDistributorSelectorLambda HappyHourHistoricPricePersistorLambda ResturantMenuWebCrawler Semantic-UI Semantic-UI-React Terroir ZipToZoneFileCreator analytics analytics-draft api-listener argocd-orb asset_sync auth0 awsbastion-infra backbone-on-rails backup_dns bar-tab barback bartab beacon beacon_eks bevPOS bmg-bevsites bmg-bevsites-fedex-api bmg-eorders bmg-ets bmg-nysla bmg-subscription bootlegger bootlegger-bakeoff bootlegger-webhook-lambda-authorizer bootlegger-worker boozechoose bottle-shots bottler bottling-plant bouncer boxes brewery brewery_consumer buymore cheers cheers-backend cheers-frontend ci_metrics cicerone-lib cicerone-state-machines cluster-canary configtest-app configtest-config craft crm-sync crowdstrike-image-puller crowdstrike-terraform data_science_research datadog-terraform datawarehouse_migration delayed_job devmachine devops-onboarding disburse distiller distillery dockerfiles dockerized-beacon downstream dpinsert e2e_pilot ec2runner eks-upgrade-pipeline entity-matching-docker epicwin experian finix fizz-mobile-app fizzbook forklift forklift-lambda gh-admin-automation githooks glue-patcher happy-hour happy-hour-validation-service helm-charts_old [4mh[4melm[24m-deployments heroku-buildpack-ruby heroku-shared-postgres imperva-serverswap ingresstest interview-questions jenkins-kube-test jenkins-local jenkinsdeployer josefine kafka_api kyverno-policies license-parser liquid-analytics-sandbox loadtest looker mcgruff meltano mixologist mycoolworkload node-socket-wrap nysla nysla-maintenance onestackutilities pallet pallet_eks palletwebhooks payments-postman-collections pg_jbuilder pos-integrations post-office-api post-office-worker proof-read prosecco provi-ecs-events provi-eks provi-eks-workloads provi-imperva-client provi-scheduler-partner-batch-sf-api provi-sftp-scheduler-app provi-tradegecko provi_retailer_viz punchout-simulator puppeteer-heroku-buildpack qa-automation rails_phone react-native-config react-native-cookies recommendation-engine retailers_address_matching_lambdas rspec-retry rubybuilder sandbox sandbox-golang sauce sevenfiftydaily sfcore-ui siphond siphond-config skel slackcommands snowflake-flyway sns-to-slack-lambda-function sommelier sommelier-config speedrail-datafiles speedrail-dev-tools speedrail-ui state-manager state-manager-scripts sumologic_terraform supplier-service templates terraform-eks-lens victualler wine-cellar-validator wine-cellar-valildator[K
[K
bck-i-search: helm_[K[9A[9A[77C[4mh[4me[4ml[4mm[4m [24mrollback --help[K[54C[01;31m130 ↵[00m[1Bbck-i-search: helm _[K[1B[K[1B[K[1B[K[1B[K[1B[K[1B[K[1B[K[1B[K[1B[K[1B[K[1B[K[1B[K[1B[K[1B[K[1B[K[1B[K[1B[K[18A[77C[24mh[24me[24ml[24mm[24m [1Bfailing bck-i-search: helm t_M[48C[1B[49De_M[47C[1B[48Dp_M[46C[1B[47Dl_M[45C[1B[46Da_M[44C[1B[45Dg_M[43C[1B[44De_M[42C[1B[44D_ M[42C[1B[45D_ M[43C                    [1B[KM[77Chhhelm templ[?2004l[1B[1m[3m%[23m[1m[0m                                                                                                                                                             ^Lk..t/helm-charts\]7;file://negroni/Users/chris.reisor/git/helm-charts\[0m[23m[24m[J[01;32mchris.reisor@negroni[00m [01;34mgit/helm-charts[00m [33m(INFRASEC-4257-affinity-and-topology) [00m[00m[1m»[0m [K[74C[01;31m130 ↵[00m[79D[?1h=[6 q[?2004h[H[J[0m[23m[24m[J[01;32mchris.reisor@negroni[00m [01;34mgit/helm-charts[00m [33m(INFRASEC-4257-affinity-and-topology) [00m[00m[1m»[0m [K[74C[01;31m130 ↵[00m[79Dhhtelm   h hlem  h helm template -f test/fixtures[1m/[0m[0m/affinity[1m/[0m[0m/values-
[J[0mvalues-anti-affinity-disabled.yaml   [Jvalues-anti-affinity-overrides.yaml  [Jvalues-basic.yaml                  [JM[0m[23m[24m[0m[77Chelm template -f test/fixtures/affinity/values-[K[27C[01;31m130 ↵[00m[0m[32Daff
[JM[127Cin     
[J[J[0mvalues-anti-affinity-disabled.yaml   [Jvalues-anti-affinity-overrides.yaml  [Jvalues-basic.yaml                  [JM[0m[23m[24m[0m[77Chelm template -f test/fixtures/affinity/values-[K[27C[01;31m130 ↵[00m[0m[32Dan
[JM[126Cti-affinity-disabled.yaml[1m [0m[K[0m test/ [Kffixtures[1m/[0m[0m/affinity[1m/[0m[0m [?1l>[0 q[?2004l
[Jkhelm\---
# Source: my-cool-app/templates/microservice.yaml.tpl
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  annotations:
    provi.repository: https://github.com/example/repo
    provi.slack: my-cool-team
  labels:
    app: web
    app.kubernetes.io/name: dummy
    chart: my-cool-app
    chartVersion: 1.0.0
    team: cool-team
spec:
  replicas: 3
  selector:
    matchLabels:
      selector: my-cool-app-deployment-web
  template:
    metadata:
      annotations:
        provi.repository: https://github.com/example/repo
        provi.slack: my-cool-team
      labels:
        selector: my-cool-app-deployment-web
        app: web
        app.kubernetes.io/name: dummy
        chart: my-cool-app
        chartVersion: 1.0.0
        team: cool-team
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app.kubernetes.io/name: "dummy"
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app.kubernetes.io/name: "dummy"
      automountServiceAccountToken: false
      tolerations:
        - key: "spot"
          operator: "Exists"
          effect: "NoSchedule"
      restartPolicy: Always
      terminationGracePeriodSeconds: 30
      containers:
        - name: app
          image: docker.io/image:abcd1234
          imagePullPolicy: Always
          securityContext:
            runAsNonRoot: false
          env:
            - name: RACK_ENV
              value: "production"
            - name: RAILS_ENV
              value: "production"
          envFrom:
            - secretRef:
                name: dummy
          livenessProbe:
            initialDelaySeconds: 0
            periodSeconds: 5
            timeoutSeconds: 1
            failureThreshold: 5
            successThreshold: 1
            httpGet:
              path: /
              port: 8080
          resources:
            limits:
              memory: 256Mi
              ephemeral-storage: 200Mi
            requests:
              cpu: 250m
              memory: 256Mi
              ephemeral-storage: 200Mi
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: foo
                operator: In
                values:
                - bar
              - key: type
                operator: In
                values:
                - testaffinity
[1m[3m%[23m[1m[0m                                                                                                                                                             k..t/helm-charts\]7;file://negroni/Users/chris.reisor/git/helm-charts\[0m[23m[24m[J[01;32mchris.reisor@negroni[00m [01;34mgit/helm-charts[00m [33m(INFRASEC-4257-affinity-and-topology) [00m[00m[1m»[0m [K[?1h=[6 q[?2004h[H[J[0m[23m[24m[J[01;32mchris.reisor@negroni[00m [01;34mgit/helm-charts[00m [33m(INFRASEC-4257-affinity-and-topology) [00m[00m[1m»[0m [K[2 qhelm template -f test/fixtures/affinity/values-anti-affinity-disabled.yaml test/fixtures/affinity[K[?1l>[0 q[?2004l
khelm\---
# Source: my-cool-app/templates/microservice.yaml.tpl
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  annotations:
    provi.repository: https://github.com/example/repo
    provi.slack: my-cool-team
  labels:
    app: web
    app.kubernetes.io/name: dummy
    chart: my-cool-app
    chartVersion: 1.0.0
    team: cool-team
spec:
  replicas: 3
  selector:
    matchLabels:
      selector: my-cool-app-deployment-web
  template:
    metadata:
      annotations:
        provi.repository: https://github.com/example/repo
        provi.slack: my-cool-team
      labels:
        selector: my-cool-app-deployment-web
        app: web
        app.kubernetes.io/name: dummy
        chart: my-cool-app
        chartVersion: 1.0.0
        team: cool-team
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app.kubernetes.io/name: "dummy"
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app.kubernetes.io/name: "dummy"
      automountServiceAccountToken: false
      tolerations:
        - key: "spot"
          operator: "Exists"
          effect: "NoSchedule"
      restartPolicy: Always
      terminationGracePeriodSeconds: 30
      containers:
        - name: app
          image: docker.io/image:abcd1234
          imagePullPolicy: Always
          securityContext:
            runAsNonRoot: false
          env:
            - name: RACK_ENV
              value: "production"
            - name: RAILS_ENV
              value: "production"
          envFrom:
            - secretRef:
                name: dummy
          livenessProbe:
            initialDelaySeconds: 0
            periodSeconds: 5
            timeoutSeconds: 1
            failureThreshold: 5
            successThreshold: 1
            httpGet:
              path: /
              port: 8080
          resources:
            limits:
              memory: 256Mi
              ephemeral-storage: 200Mi
            requests:
              cpu: 250m
              memory: 256Mi
              ephemeral-storage: 200Mi
[1m[3m%[23m[1m[0m                                                                                                                                                             k..t/helm-charts\]7;file://negroni/Users/chris.reisor/git/helm-charts\[0m[23m[24m[J[01;32mchris.reisor@negroni[00m [01;34mgit/helm-charts[00m [33m(INFRASEC-4257-affinity-and-topology) [00m[00m[1m»[0m [K[?1h=[6 q[?2004h[2 qhelm template -f test/fixtures/affinity/values-anti-affinity-disabled.yaml test/fixtures/affinity[K[?1l>[0 q[?2004l
khelm\---
# Source: my-cool-app/templates/microservice.yaml.tpl
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  annotations:
    provi.repository: https://github.com/example/repo
    provi.slack: my-cool-team
  labels:
    app: web
    app.kubernetes.io/name: dummy
    chart: my-cool-app
    chartVersion: 1.0.0
    team: cool-team
spec:
  replicas: 3
  selector:
    matchLabels:
      selector: my-cool-app-deployment-web
  template:
    metadata:
      annotations:
        provi.repository: https://github.com/example/repo
        provi.slack: my-cool-team
      labels:
        selector: my-cool-app-deployment-web
        app: web
        app.kubernetes.io/name: dummy
        chart: my-cool-app
        chartVersion: 1.0.0
        team: cool-team
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app.kubernetes.io/name: "dummy"
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app.kubernetes.io/name: "dummy"
      automountServiceAccountToken: false
      tolerations:
        - key: "spot"
          operator: "Exists"
          effect: "NoSchedule"
      restartPolicy: Always
      terminationGracePeriodSeconds: 30
      containers:
        - name: app
          image: docker.io/image:abcd1234
          imagePullPolicy: Always
          securityContext:
            runAsNonRoot: false
          env:
            - name: RACK_ENV
              value: "production"
            - name: RAILS_ENV
              value: "production"
          envFrom:
            - secretRef:
                name: dummy
          livenessProbe:
            initialDelaySeconds: 0
            periodSeconds: 5
            timeoutSeconds: 1
            failureThreshold: 5
            successThreshold: 1
            httpGet:
              path: /
              port: 8080
          resources:
            limits:
              memory: 256Mi
              ephemeral-storage: 200Mi
            requests:
              cpu: 250m
              memory: 256Mi
              ephemeral-storage: 200Mi
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: karpenter.sh/controller
                operator: NotIn
                values:
                - "true"
[1m[3m%[23m[1m[0m                                                                                                                                                             k..t/helm-charts\]7;file://negroni/Users/chris.reisor/git/helm-charts\[0m[23m[24m[J[01;32mchris.reisor@negroni[00m [01;34mgit/helm-charts[00m [33m(INFRASEC-4257-affinity-and-topology) [00m[00m[1m»[0m [K[?1h=[6 q[?2004h[2 q[6 qTTAG=affinity make test[?1l>[0 q[?2004l
kmake\BATSLIB_TEMP_PRESERVE_ON_FAILURE=1 AWS_PROFILE= test/bats/bin/bats --filter-tags tag:affinity test/
[34;1mtest_pod_affinity.bats
[0m[1G   affinity: outputs a template[K[154G1/4[2G[1G ✓ affinity: outputs a template[K
[0m[1G   affinity: matches expected output[K[154G2/4[2G[1G ✓ affinity: matches expected output[K
[0m[1G   affinity: allows overriding the anti-affinity label[K[154G3/4[2G[1G ✓ affinity: allows overriding the anti-affinity label[K
[0m[1G   affinity: allows disabling automatic anti-affinity[K[154G4/4[2G[1G ✓ affinity: allows disabling automatic anti-affinity[K
[0m[32;1m
4 tests, 0 failures
[0m
[1m[3m%[23m[1m[0m                                                                                                                                                             k..t/helm-charts\]7;file://negroni/Users/chris.reisor/git/helm-charts\[0m[23m[24m[J[01;32mchris.reisor@negroni[00m [01;34mgit/helm-charts[00m [33m(INFRASEC-4257-affinity-and-topology) [00m[00m[1m»[0m [K[?1h=[6 q[?2004hgg d[?1l>[0 q[?2004l
kg\git: 'd' is not a git command. See 'git --help'.

The most similar commands are
	diff
	add
[1m[3m%[23m[1m[0m                                                                                                                                                             gk..t/helm-charts\]7;file://negroni/Users/chris.reisor/git/helm-charts\[0m[23m[24m[J[01;32mchris.reisor@negroni[00m [01;34mgit/helm-charts[00m [33m(INFRASEC-4257-affinity-and-topology) [00m[00m[1m»[0m [K[76C[01;31m1 ↵[00m[79D[?1h=[6 q[?2004hggd[?1l>[0 q[?2004l
kgd\[?1h=[1mdiff --git a/CHANGELOG.md b/CHANGELOG.md[m[m
[1mindex 3cc89d0..eedd8de 100644[m[m
[1m--- a/CHANGELOG.md[m[m
[1m+++ b/CHANGELOG.md[m[m
[36m@@ -7,11 +7,11 @@[m [mand this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0[m[m
 [m[m
 ## [Unreleased][m[m
 [m[m
[31m-## [1.9.0] - 2025-12-17[m[m
[32m+[m[32m## [1.9.0] - 2025-12-18[m[m
 [m[m
 ### Added[m[m
 [m[m
[31m-- Pods now include a default `podAntiAffinity` targeting `karpenter.sh/controller: "true"`, with new `antiAffinityLabel` and `antiAffinityDisabled` controls[m [31m plus support for merging with caller-provided affinity rules.[m[m
[32m+[m[32m- Pods now include a default `nodeAffinity` to ensure pods do not get scheduled on nodes labeled `karpenter.sh/controller: "true"`, with new `antiAffinityLa[m [32m[m[32mbel` and `antiAffinityDisabled` controls plus support for merging with caller-provided affinity rules.[m[m
 - Replaced the legacy `pod.topologySpreadConstraints.matchLabels` defaults with `pod.defaultTopologySpreadConstraints`, added a configurable `whenUnsatisfia[m ble`, and allow callers to provide full `topologySpreadConstraints` lists with validation for required fields.[m[m
 - Includes `CONTRIBUTING.md` doc for help on creating patch releases for the 1.8.x series, which is required until all apps are deployed to new clusters.[m[m
 [m[m
[1mdiff --git a/charts/common/templates/_pod_affinity.yaml.tpl b/charts/common/templates/_pod_affinity.yaml.tpl[m[m
[1mindex 7e85a8e..0b04423 100644[m[m
[1m--- a/charts/common/templates/_pod_affinity.yaml.tpl[m[m
[1m+++ b/charts/common/templates/_pod_affinity.yaml.tpl[m[m
[36m@@ -24,28 +24,32 @@[m[m
 {{- else if $rawAffinity }}[m[m
   {{- fail "pod.affinity must be provided as a map" }}[m[m
 {{- end }}[m[m
[31m-{{- $antiAffinityDisabled := default false .pod.antiAffinityDisabled }}[m[m
[31m-{{- if not $antiAffinityDisabled }}[m[m
[31m-  {{- $labelConfig := .pod.antiAffinityLabel | default (dict "karpenter.sh/controller" "true") }}[m[m
[32m+[m[32m{{- $nodeAffinityDisabled := default false .pod.antiAffinityDisabled }}[m[m
[32m+[m[32m{{- if not $nodeAffinityDisabled }}[m[m
[32m+[m[32m  {{- $labelConfig := coalesce .pod.nodeAffinityLabel .pod.antiAffinityLabel (dict "karpenter.sh/controller" "true") }}[m[m
   {{- $matchExpressions := list }}[m[m
   {{- range $labelKey, $labelValue := $labelConfig }}[m[m
     {{- if ne $labelValue nil }}[m[m
[31m-      {{- $matchExpressions = append $matchExpressions (dict "key" $labelKey "operator" "In" "values" (list (printf "%v" $labelValue))) }}[m[m
[32m+[m[32m      {{- $matchExpressions = append $matchExpressions (dict "key" $labelKey "operator" "NotIn" "values" (list (printf "%v" $labelValue))) }}[m[m
:[K[K     {{- end }}[m[m
   {{- end }}[m[m
   {{- if gt (len $matchExpressions) 0 }}[m[m
[31m-    {{- $term := dict "labelSelector" (dict "matchExpressions" $matchExpressions) "topologyKey" "kubernetes.io/hostname" }}[m[m
[31m-    {{- $podAntiAffinity := dict }}[m[m
[31m-    {{- if hasKey $affinity "podAntiAffinity" }}[m[m
[31m-      {{- $podAntiAffinity = deepCopy (get $affinity "podAntiAffinity") }}[m[m
[32m+[m[32m    {{- $nodeAffinity := dict }}[m[m
[32m+[m[32m    {{- if hasKey $affinity "nodeAffinity" }}[m[m
[32m+[m[32m      {{- $nodeAffinity = deepCopy (get $affinity "nodeAffinity") }}[m[m
     {{- end }}[m[m
[31m-    {{- $required := list }}[m[m
[31m-    {{- if hasKey $podAntiAffinity "requiredDuringSchedulingIgnoredDuringExecution" }}[m[m
[31m-      {{- $required = deepCopy (get $podAntiAffinity "requiredDuringSchedulingIgnoredDuringExecution") }}[m[m
[32m+[m[32m    {{- $required := dict }}[m[m
[32m+[m[32m    {{- if hasKey $nodeAffinity "requiredDuringSchedulingIgnoredDuringExecution" }}[m[m
[32m+[m[32m      {{- $required = deepCopy (get $nodeAffinity "requiredDuringSchedulingIgnoredDuringExecution") }}[m[m
     {{- end }}[m[m
[31m-    {{- $required = append $required $term }}[m[m
[31m-    {{- $_ := set $podAntiAffinity "requiredDuringSchedulingIgnoredDuringExecution" $required }}[m[m
[31m-    {{- $_ := set $affinity "podAntiAffinity" $podAntiAffinity }}[m[m
[32m+[m[32m    {{- $nodeSelectorTerms := list }}[m[m
[32m+[m[32m    {{- if hasKey $required "nodeSelectorTerms" }}[m[m
[32m+[m[32m      {{- $nodeSelectorTerms = deepCopy (get $required "nodeSelectorTerms") }}[m[m
[32m+[m[32m    {{- end }}[m[m
[32m+[m[32m    {{- $nodeSelectorTerms = append $nodeSelectorTerms (dict "matchExpressions" $matchExpressions) }}[m[m
[32m+[m[32m    {{- $_ := set $required "nodeSelectorTerms" $nodeSelectorTerms }}[m[m
[32m+[m[32m    {{- $_ := set $nodeAffinity "requiredDuringSchedulingIgnoredDuringExecution" $required }}[m[m
[32m+[m[32m    {{- $_ := set $affinity "nodeAffinity" $nodeAffinity }}[m[m
   {{- end }}[m[m
 {{- end }}[m[m
 {{- if gt (len $affinity) 0 }}[m[m
[1mdiff --git a/scripts/update-fixture-charts.sh b/scripts/update-fixture-charts.sh[m[m
[1mindex 2181a6e..e0af0e6 100755[m[m
[1m--- a/scripts/update-fixture-charts.sh[m[m
[1m+++ b/scripts/update-fixture-charts.sh[m[m
[36m@@ -1,80 +1,1396 @@[m[m
[31m-#!/usr/bin/env bash[m[m
[31m-[m[m
[31m-initial_errexit_state=$(set -o | awk '$1=="errexit" {print $2}')[m[m
:[K[K[31m-initial_pipefail_state=$(set -o | awk '$1=="pipefail" {print $2}')[m[m
[31m-initial_nounset_state=$(set -o | awk '$1=="nounset" {print $2}')[m[m
[31m-[m[m
[31m-set -o errexit[m[m
[31m-set -o pipefail[m[m
[31m-set -o nounset[m[m
[31m-[m[m
[31m-restore_shellopts() {[m[m
[31m-  if [[ "$initial_errexit_state" == "off" ]]; then[m[m
[31m-    set +e[m[m
[31m-  else[m[m
[31m-    set -e[m[m
[31m-  fi[m[m
[31m-[m[m
[31m-  if [[ "$initial_pipefail_state" == "off" ]]; then[m[m
[31m-    set +o pipefail[m[m
[31m-  else[m[m
[31m-    set -o pipefail[m[m
[31m-  fi[m[m
[31m-[m[m
[31m-  if [[ "$initial_nounset_state" == "off" ]]; then[m[m
[31m-    set +u[m[m
[31m-  else[m[m
[31m-    set -u[m[m
[31m-  fi[m[m
[31m-}[m[m
[31m-trap restore_shellopts EXIT[m[m
[31m-[m[m
[31m-if [[ $# -ne 1 ]]; then[m[m
[31m-[m[m
[31m-  echo "Usage: $0 <common_chart_version>" >&2[m[m
[31m-  exit 1[m[m
[31m-fi[m[m
[31m-[m[m
[31m-if ! command -v helm >/dev/null 2>&1; then[m[m
[31m-  echo "Error: helm is not installed or not in PATH" >&2[m[m
[31m-  exit 1[m[m
[31m-fi[m[m
[31m-[m[m
[31m-COMMON_VERSION="$1"[m[m
:[K[K[31m-FIXTURES_ROOT="test/fixtures"[m[m
[31m-[m[m
[31m-if [[ ! -d "$FIXTURES_ROOT" ]]; then[m[m
[31m-  echo "Error: $FIXTURES_ROOT directory not found" >&2[m[m
[31m-  exit 1[m[m
[31m-fi[m[m
[31m-[m[m
[31m-for chart_dir in "$FIXTURES_ROOT"/*/; do[m[m
[31m-  [[ -d "$chart_dir" ]] || continue[m[m
[31m-[m[m
[31m-  chart_file="${chart_dir}Chart.yaml"[m[m
[31m-  lock_file="${chart_dir}Chart.lock"[m[m
[31m-[m[m
[31m-  # Remove legacy symlinks so we can write real files[m[m
[31m-  if [[ -L "$chart_file" ]]; then[m[m
[31m-    rm "$chart_file"[m[m
[31m-  fi[m[m
[31m-  if [[ -L "$lock_file" ]]; then[m[m
[31m-    rm "$lock_file"[m[m
[31m-  fi[m[m
[31m-[m[m
[31m-  cat > "$chart_file" <<EOF[m[m
[31m-apiVersion: v2[m[m
[31m-name: my-cool-app[m[m
[31m-description: Defaults chart for testing[m[m
[31m-type: application[m[m
[31m-version: 1.0.0[m[m
[31m-dependencies:[m[m
[31m-  - name: common[m[m
[31m-    repository: file://../../../charts/common[m[m
[31m-    version: "$COMMON_VERSION"[m[m
[31m-EOF[m[m
[31m-[m[m
[31m-  echo "Running helm dependency update in ${chart_dir}"[m[m
[31m-  # Equivalent to 'helm dep up' in modern Helm (aka 'helm up')[m[m
[31m-  (cd "$chart_dir" && helm dependency update)[m[m
[31m-done[m[m
[32m+[m[32mScript started on Thu Dec 18 15:52:53 2025[m[m
[32m+[m[32m[1m[3m%[23m[1m[0m                                                                                                                                                           [m [32m[m[32m[1m[3m[23m[1m[0m [3m^M[23m [3m^M[23m..t/helm-chartsile://negroni/Users/chris.reisor/git/helm-charts[3m^M[23m[0m[23m[24m[01;32mchris.reisor@negroni[00m [01;34mgit/helm-charts[00m [33m(INFRASEC-4257-affinity-and-topology) [00m[00m[1m»[0m [1mg[0md[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32mgd[3m^M[23m[1mdiff --git a/CHANGELOG.md b/CHANGELOG.md[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex 3cc89d0..eedd8de 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/CHANGELOG.md[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/CHANGELOG.md[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -7,11 +7,11 @@[m [mand this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m [m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m ## [Unreleased][m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m [m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-## [1.9.0] - 2025-12-17[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m## [1.9.0] - 2025-12-18[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m [m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m ### Added[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m [m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-- Pods now include a default `podAntiAffinity` targeting `karpenter.sh/controller: "true"`, with new `antiAffinityLabel` and `antiAffinityDisabled` control[m [32m[m[32m[31ms[m[31m plus support for merging with caller-provided affinity rules.[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m- Pods now include a default `nodeAffinity` to ensure pods do not get scheduled on nodes labeled `karpenter.sh/controller: "true"`, with new `antiAffinityL[m [32m[m[32m[32m[m[32ma[m[32m[m[32mbel` and `antiAffinityDisabled` controls plus support for merging with caller-provided affinity rules.[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m - Replaced the legacy `pod.topologySpreadConstraints.matchLabels` defaults with `pod.defaultTopologySpreadConstraints`, added a configurable `whenUnsatisfi[m [32m[m[32ma[mble`, and allow callers to provide full `topologySpreadConstraints` lists with validation for required fields.[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m - Includes `CONTRIBUTING.md` doc for help on creating patch releases for the 1.8.x series, which is required until all apps are deployed to new clusters.[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m [m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/charts/common/templates/_pod_affinity.yaml.tpl b/charts/common/templates/_pod_affinity.yaml.tpl[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex 7e85a8e..0b04423 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/charts/common/templates/_pod_affinity.yaml.tpl[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/charts/common/templates/_pod_affinity.yaml.tpl[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -24,28 +24,32 @@[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m {{- else if $rawAffinity }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   {{- fail "pod.affinity must be provided as a map" }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m {{- end }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-{{- $antiAffinityDisabled := default false .pod.antiAffinityDisabled }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-{{- if not $antiAffinityDisabled }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  {{- $labelConfig := .pod.antiAffinityLabel | default (dict "karpenter.sh/controller" "true") }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m{{- $nodeAffinityDisabled := default false .pod.antiAffinityDisabled }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m{{- if not $nodeAffinityDisabled }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m  {{- $labelConfig := coalesce .pod.nodeAffinityLabel .pod.antiAffinityLabel (dict "karpenter.sh/controller" "true") }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   {{- $matchExpressions := list }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   {{- range $labelKey, $labelValue := $labelConfig }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m     {{- if ne $labelValue nil }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-      {{- $matchExpressions = append $matchExpressions (dict "key" $labelKey "operator" "In" "values" (list (printf "%v" $labelValue))) }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m      {{- $matchExpressions = append $matchExpressions (dict "key" $labelKey "operator" "NotIn" "values" (list (printf "%v" $labelValue))) }}[m[m[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m:[3m^M[23m     {{- end }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   {{- end }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   {{- if gt (len $matchExpressions) 0 }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    {{- $term := dict "labelSelector" (dict "matchExpressions" $matchExpressions) "topologyKey" "kubernetes.io/hostname" }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    {{- $podAntiAffinity := dict }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    {{- if hasKey $affinity "podAntiAffinity" }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-      {{- $podAntiAffinity = deepCopy (get $affinity "podAntiAffinity") }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    {{- $nodeAffinity := dict }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    {{- if hasKey $affinity "nodeAffinity" }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m      {{- $nodeAffinity = deepCopy (get $affinity "nodeAffinity") }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m     {{- end }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    {{- $required := list }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    {{- if hasKey $podAntiAffinity "requiredDuringSchedulingIgnoredDuringExecution" }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-      {{- $required = deepCopy (get $podAntiAffinity "requiredDuringSchedulingIgnoredDuringExecution") }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    {{- $required := dict }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    {{- if hasKey $nodeAffinity "requiredDuringSchedulingIgnoredDuringExecution" }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m      {{- $required = deepCopy (get $nodeAffinity "requiredDuringSchedulingIgnoredDuringExecution") }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m     {{- end }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    {{- $required = append $required $term }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    {{- $_ := set $podAntiAffinity "requiredDuringSchedulingIgnoredDuringExecution" $required }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    {{- $_ := set $affinity "podAntiAffinity" $podAntiAffinity }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    {{- $nodeSelectorTerms := list }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    {{- if hasKey $required "nodeSelectorTerms" }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m      {{- $nodeSelectorTerms = deepCopy (get $required "nodeSelectorTerms") }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    {{- end }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    {{- $nodeSelectorTerms = append $nodeSelectorTerms (dict "matchExpressions" $matchExpressions) }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    {{- $_ := set $required "nodeSelectorTerms" $nodeSelectorTerms }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    {{- $_ := set $nodeAffinity "requiredDuringSchedulingIgnoredDuringExecution" $required }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    {{- $_ := set $affinity "nodeAffinity" $nodeAffinity }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   {{- end }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m {{- end }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m {{- if gt (len $affinity) 0 }}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/scripts/update-fixture-charts.sh b/scripts/update-fixture-charts.sh[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex 2181a6e..fb7721a 100755[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/scripts/update-fixture-charts.sh[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/scripts/update-fixture-charts.sh[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -1,80 +1 @@[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-#!/usr/bin/env bash[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-initial_errexit_state=$(set -o | awk '$1=="errexit" {print $2}')[m[m[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m:[3m^M[23m[31m-initial_pipefail_state=$(set -o | awk '$1=="pipefail" {print $2}')[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-initial_nounset_state=$(set -o | awk '$1=="nounset" {print $2}')[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-set -o errexit[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-set -o pipefail[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-set -o nounset[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-restore_shellopts() {[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  if [[ "$initial_errexit_state" == "off" ]]; then[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    set +e[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  else[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    set -e[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  fi[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  if [[ "$initial_pipefail_state" == "off" ]]; then[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    set +o pipefail[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  else[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    set -o pipefail[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  fi[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  if [[ "$initial_nounset_state" == "off" ]]; then[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    set +u[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  else[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    set -u[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  fi[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-}[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-trap restore_shellopts EXIT[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-if [[ $# -ne 1 ]]; then[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  echo "Usage: $0 <common_chart_version>" >&2[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  exit 1[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-fi[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-if ! command -v helm >/dev/null 2>&1; then[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  echo "Error: helm is not installed or not in PATH" >&2[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  exit 1[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-fi[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-COMMON_VERSION="$1"[m[m[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m:[3m^M[23m[31m-FIXTURES_ROOT="test/fixtures"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-if [[ ! -d "$FIXTURES_ROOT" ]]; then[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  echo "Error: $FIXTURES_ROOT directory not found" >&2[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  exit 1[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-fi[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-for chart_dir in "$FIXTURES_ROOT"/*/; do[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  [[ -d "$chart_dir" ]] || continue[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  chart_file="${chart_dir}Chart.yaml"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  lock_file="${chart_dir}Chart.lock"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  # Remove legacy symlinks so we can write real files[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  if [[ -L "$chart_file" ]]; then[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    rm "$chart_file"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  fi[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  if [[ -L "$lock_file" ]]; then[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    rm "$lock_file"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  fi[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  cat > "$chart_file" <<EOF[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-apiVersion: v2[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-name: my-cool-app[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-description: Defaults chart for testing[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-type: application[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-version: 1.0.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    version: "$COMMON_VERSION"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-EOF[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  echo "Running helm dependency update in ${chart_dir}"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  # Equivalent to 'helm dep up' in modern Helm (aka 'helm up')[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  (cd "$chart_dir" && helm dependency update)[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-done[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mScript started on Thu Dec 18 15:52:53 2025[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/expected_output/affinity.yaml b/test/expected_output/affinity.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex 9d45871..b46075b 100644[m[m[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m:[3m^M[23m[1m--- a/test/expected_output/affinity.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/expected_output/affinity.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -95,12 +95,8 @@[m [mspec:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 operator: In[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 values:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 - testaffinity[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-        podAntiAffinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-          requiredDuringSchedulingIgnoredDuringExecution:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-          - labelSelector:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-              matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m            - matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m               - key: karpenter.sh/controller[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-                operator: In[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m                operator: NotIn[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 values:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 - "true"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-            topologyKey: kubernetes.io/hostname[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/expected_output/autoscaler.yaml b/test/expected_output/autoscaler.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex 9777b6b..caab7a4 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/expected_output/autoscaler.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/expected_output/autoscaler.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -82,15 +82,14 @@[m [mspec:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m               memory: 256Mi[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m               ephemeral-storage: 200Mi[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m       affinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-        podAntiAffinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m        nodeAffinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m           requiredDuringSchedulingIgnoredDuringExecution:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-          - labelSelector:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-              matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m            nodeSelectorTerms:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m            - matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m               - key: karpenter.sh/controller[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-                operator: In[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m                operator: NotIn[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 values:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 - "true"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-            topologyKey: kubernetes.io/hostname[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m ---[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m # Source: my-cool-app/templates/microservice.yaml.tpl[m[m[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m:[3m^M[23m apiVersion: autoscaling/v2[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/expected_output/containers-basic.yaml b/test/expected_output/containers-basic.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex 54a668f..09510e2 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/expected_output/containers-basic.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/expected_output/containers-basic.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -121,12 +121,8 @@[m [mspec:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 operator: In[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 values:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 - karpenter[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-        podAntiAffinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-          requiredDuringSchedulingIgnoredDuringExecution:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-          - labelSelector:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-              matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m            - matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m               - key: karpenter.sh/controller[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-                operator: In[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m                operator: NotIn[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 values:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 - "true"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-            topologyKey: kubernetes.io/hostname[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/expected_output/cronjobs-global-serviceaccount.yaml b/test/expected_output/cronjobs-global-serviceaccount.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex fef5b8b..4410545 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/expected_output/cronjobs-global-serviceaccount.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/expected_output/cronjobs-global-serviceaccount.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -69,12 +69,11 @@[m [mspec:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                   cpu: 100m[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                   memory: 256Mi[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m           affinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-            podAntiAffinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m            nodeAffinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m               requiredDuringSchedulingIgnoredDuringExecution:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-              - labelSelector:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-                  matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m                nodeSelectorTerms:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m                - matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                   - key: karpenter.sh/controller[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-                    operator: In[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m                    operator: NotIn[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                     values:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                     - "true"[m[m[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m:[3m^M[23m[31m-                topologyKey: kubernetes.io/hostname[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/expected_output/cronjobs-serviceaccount.yaml b/test/expected_output/cronjobs-serviceaccount.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex 0d4c84a..c970af0 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/expected_output/cronjobs-serviceaccount.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/expected_output/cronjobs-serviceaccount.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -73,12 +73,11 @@[m [mspec:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                   cpu: 100m[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                   memory: 256Mi[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m           affinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-            podAntiAffinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m            nodeAffinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m               requiredDuringSchedulingIgnoredDuringExecution:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-              - labelSelector:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-                  matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m                nodeSelectorTerms:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m                - matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                   - key: karpenter.sh/controller[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-                    operator: In[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m                    operator: NotIn[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                     values:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                     - "true"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-                topologyKey: kubernetes.io/hostname[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/expected_output/cronjobs.yaml b/test/expected_output/cronjobs.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex bd18369..03d5ebe 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/expected_output/cronjobs.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/expected_output/cronjobs.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -61,12 +61,11 @@[m [mspec:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                   cpu: 100m[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                   memory: 256Mi[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m           affinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-            podAntiAffinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m            nodeAffinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m               requiredDuringSchedulingIgnoredDuringExecution:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-              - labelSelector:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-                  matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m                nodeSelectorTerms:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m                - matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                   - key: karpenter.sh/controller[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-                    operator: In[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m                    operator: NotIn[m[m[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m:[3m^M[23m                     values:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                     - "true"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-                topologyKey: kubernetes.io/hostname[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/expected_output/deployments-selector.yaml b/test/expected_output/deployments-selector.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex 4fc50b8..becd9cc 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/expected_output/deployments-selector.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/expected_output/deployments-selector.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -121,15 +121,11 @@[m [mspec:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 operator: In[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 values:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 - karpenter[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-        podAntiAffinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-          requiredDuringSchedulingIgnoredDuringExecution:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-          - labelSelector:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-              matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m            - matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m               - key: karpenter.sh/controller[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-                operator: In[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m                operator: NotIn[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 values:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 - "true"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-            topologyKey: kubernetes.io/hostname[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m ---[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m # Source: my-cool-app/templates/microservice.yaml.tpl[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m apiVersion: autoscaling/v2[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/expected_output/deployments.yaml b/test/expected_output/deployments.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex 46d1e76..b6fc98a 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/expected_output/deployments.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/expected_output/deployments.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -127,15 +127,11 @@[m [mspec:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 operator: In[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 values:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 - karpenter[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-        podAntiAffinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-          requiredDuringSchedulingIgnoredDuringExecution:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-          - labelSelector:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-              matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m            - matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m               - key: karpenter.sh/controller[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-                operator: In[m[m[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m:[3m^M[23m[32m+[m[32m                operator: NotIn[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 values:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 - "true"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-            topologyKey: kubernetes.io/hostname[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m ---[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m # Source: my-cool-app/templates/microservice.yaml.tpl[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m apiVersion: autoscaling/v2[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/expected_output/jobs.yaml b/test/expected_output/jobs.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex d50a43b..e3748b3 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/expected_output/jobs.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/expected_output/jobs.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -54,12 +54,11 @@[m [mspec:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m               cpu: 100m[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m               memory: 256Mi[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m       affinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-        podAntiAffinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m        nodeAffinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m           requiredDuringSchedulingIgnoredDuringExecution:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-          - labelSelector:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-              matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m            nodeSelectorTerms:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m            - matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m               - key: karpenter.sh/controller[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-                operator: In[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m                operator: NotIn[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 values:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 - "true"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-            topologyKey: kubernetes.io/hostname[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/expected_output/microservice.yaml b/test/expected_output/microservice.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex e769301..4fb3136 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/expected_output/microservice.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/expected_output/microservice.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -177,15 +177,11 @@[m [mspec:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 operator: In[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 values:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 - karpenter[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-        podAntiAffinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-          requiredDuringSchedulingIgnoredDuringExecution:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-          - labelSelector:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-              matchExpressions:[m[m[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m:[3m^M[23m[32m+[m[32m            - matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m               - key: karpenter.sh/controller[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-                operator: In[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m                operator: NotIn[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 values:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 - "true"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-            topologyKey: kubernetes.io/hostname[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m ---[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m # Source: my-cool-app/templates/microservice.yaml.tpl[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m apiVersion: autoscaling/v2[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -286,15 +282,14 @@[m [mspec:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m             - mountPath: /data[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m               name: data[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m       affinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-        podAntiAffinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m        nodeAffinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m           requiredDuringSchedulingIgnoredDuringExecution:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-          - labelSelector:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-              matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m            nodeSelectorTerms:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m            - matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m               - key: karpenter.sh/controller[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-                operator: In[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m                operator: NotIn[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 values:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 - "true"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-            topologyKey: kubernetes.io/hostname[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   volumeClaimTemplates:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m     - metadata:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m         name: data[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -371,15 +366,14 @@[m [mspec:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                   cpu: 100m[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                   memory: 256Mi[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m           affinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-            podAntiAffinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m            nodeAffinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m               requiredDuringSchedulingIgnoredDuringExecution:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-              - labelSelector:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-                  matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m                nodeSelectorTerms:[m[m[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m:[3m^M[23m[32m+[m[32m                - matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                   - key: karpenter.sh/controller[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-                    operator: In[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m                    operator: NotIn[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                     values:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                     - "true"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-                topologyKey: kubernetes.io/hostname[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m ---[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m # Source: my-cool-app/templates/microservice.yaml.tpl[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m apiVersion: networking.k8s.io/v1[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -487,12 +481,11 @@[m [mspec:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m               cpu: 100m[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m               memory: 256Mi[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m       affinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-        podAntiAffinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m        nodeAffinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m           requiredDuringSchedulingIgnoredDuringExecution:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-          - labelSelector:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-              matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m            nodeSelectorTerms:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m            - matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m               - key: karpenter.sh/controller[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-                operator: In[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m                operator: NotIn[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 values:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 - "true"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-            topologyKey: kubernetes.io/hostname[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/expected_output/podspec-basic.yaml b/test/expected_output/podspec-basic.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex f851914..ca6b55c 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/expected_output/podspec-basic.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/expected_output/podspec-basic.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -127,15 +127,11 @@[m [mspec:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 operator: In[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 values:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 - karpenter[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-        podAntiAffinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-          requiredDuringSchedulingIgnoredDuringExecution:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-          - labelSelector:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-              matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m            - matchExpressions:[m[m[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m:[3m^M[23m               - key: karpenter.sh/controller[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-                operator: In[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m                operator: NotIn[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 values:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 - "true"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-            topologyKey: kubernetes.io/hostname[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m ---[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m # Source: my-cool-app/templates/microservice.yaml.tpl[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m apiVersion: autoscaling/v2[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/expected_output/podspec_output.yaml b/test/expected_output/podspec_output.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex f851914..ca6b55c 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/expected_output/podspec_output.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/expected_output/podspec_output.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -127,15 +127,11 @@[m [mspec:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 operator: In[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 values:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 - karpenter[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-        podAntiAffinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-          requiredDuringSchedulingIgnoredDuringExecution:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-          - labelSelector:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-              matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m            - matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m               - key: karpenter.sh/controller[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-                operator: In[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m                operator: NotIn[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 values:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 - "true"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-            topologyKey: kubernetes.io/hostname[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m ---[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m # Source: my-cool-app/templates/microservice.yaml.tpl[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m apiVersion: autoscaling/v2[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/expected_output/statefulsets.yaml b/test/expected_output/statefulsets.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex 29f250c..add1569 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/expected_output/statefulsets.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/expected_output/statefulsets.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -106,15 +106,14 @@[m [mspec:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m             - mountPath: /data[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m               name: data[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m       affinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-        podAntiAffinity:[m[m[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m:[3m^M[23m[32m+[m[32m        nodeAffinity:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m           requiredDuringSchedulingIgnoredDuringExecution:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-          - labelSelector:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-              matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m            nodeSelectorTerms:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m            - matchExpressions:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m               - key: karpenter.sh/controller[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-                operator: In[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m                operator: NotIn[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 values:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m                 - "true"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-            topologyKey: kubernetes.io/hostname[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   volumeClaimTemplates:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m     - metadata:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m         name: data[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/affinity/Chart.lock b/test/fixtures/affinity/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex 11c073e..150a626 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/affinity/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/affinity/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -1,6 +1,6 @@[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  version: 1.9.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-generated: "2025-12-17T15:09:26.365997-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m  version: 1.10.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mgenerated: "2025-12-18T15:48:26.804161-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/affinity/Chart.yaml b/test/fixtures/affinity/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex a340089..3930d4f 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/affinity/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/affinity/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m     repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    version: "1.9.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    version: "1.10.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/autoscaler/Chart.lock b/test/fixtures/autoscaler/Chart.lock[m[m[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m:[3m^M[23m[1mindex 419ecd6..d0076a4 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/autoscaler/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/autoscaler/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -1,6 +1,6 @@[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  version: 1.9.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-generated: "2025-12-17T15:09:27.105674-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m  version: 1.10.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mgenerated: "2025-12-18T15:48:27.507813-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/autoscaler/Chart.yaml b/test/fixtures/autoscaler/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex a340089..3930d4f 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/autoscaler/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/autoscaler/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m     repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    version: "1.9.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    version: "1.10.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/clusterexternalsecret/Chart.lock b/test/fixtures/clusterexternalsecret/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex 4bc1611..f59001e 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/clusterexternalsecret/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/clusterexternalsecret/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -1,6 +1,6 @@[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  version: 1.9.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-generated: "2025-12-17T15:09:29.144067-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m  version: 1.10.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mgenerated: "2025-12-18T15:48:29.001689-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/clusterexternalsecret/Chart.yaml b/test/fixtures/clusterexternalsecret/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex a340089..3930d4f 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/clusterexternalsecret/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m:[3m^M[23m[1m+++ b/test/fixtures/clusterexternalsecret/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m     repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    version: "1.9.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    version: "1.10.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/configmaps/Chart.lock b/test/fixtures/configmaps/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex 383ed3b..089e894 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/configmaps/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/configmaps/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -1,6 +1,6 @@[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  version: 1.9.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-generated: "2025-12-17T15:09:30.263648-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m  version: 1.10.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mgenerated: "2025-12-18T15:48:29.692511-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/configmaps/Chart.yaml b/test/fixtures/configmaps/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex a340089..3930d4f 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/configmaps/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/configmaps/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m     repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    version: "1.9.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    version: "1.10.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/containers/Chart.lock b/test/fixtures/containers/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex fc0b43f..e385b7c 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/containers/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/containers/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -1,6 +1,6 @@[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  version: 1.9.0[m[m[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m:[3m^M[23m[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-generated: "2025-12-17T15:09:31.391356-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m  version: 1.10.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mgenerated: "2025-12-18T15:48:30.41571-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/containers/Chart.yaml b/test/fixtures/containers/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex a340089..3930d4f 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/containers/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/containers/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m     repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    version: "1.9.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    version: "1.10.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/cronjobs/Chart.lock b/test/fixtures/cronjobs/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex 081fe8b..12fdb2a 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/cronjobs/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/cronjobs/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -1,6 +1,6 @@[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  version: 1.9.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-generated: "2025-12-17T15:09:32.450577-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m  version: 1.10.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mgenerated: "2025-12-18T15:48:31.352985-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/cronjobs/Chart.yaml b/test/fixtures/cronjobs/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex a340089..3930d4f 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/cronjobs/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/cronjobs/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m     repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    version: "1.9.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    version: "1.10.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/deployments/Chart.lock b/test/fixtures/deployments/Chart.lock[m[m[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m:[3m^M[23m[1mindex 7ff4ddb..bc38e20 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/deployments/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/deployments/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -1,6 +1,6 @@[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  version: 1.9.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-generated: "2025-12-17T15:09:38.012485-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m  version: 1.10.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mgenerated: "2025-12-18T15:48:32.086635-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/deployments/Chart.yaml b/test/fixtures/deployments/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex a340089..3930d4f 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/deployments/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/deployments/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m     repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    version: "1.9.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    version: "1.10.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/ingresses/Chart.lock b/test/fixtures/ingresses/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex 667c567..c657dbe 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/ingresses/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/ingresses/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -1,6 +1,6 @@[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  version: 1.9.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-generated: "2025-12-17T15:09:39.098876-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m  version: 1.10.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mgenerated: "2025-12-18T15:48:32.804286-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/ingresses/Chart.yaml b/test/fixtures/ingresses/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex a340089..3930d4f 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/ingresses/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m:[3m^M[23m[1m+++ b/test/fixtures/ingresses/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m     repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    version: "1.9.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    version: "1.10.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/jobs/Chart.lock b/test/fixtures/jobs/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex 56db834..421b54a 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/jobs/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/jobs/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -1,6 +1,6 @@[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  version: 1.9.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-generated: "2025-12-17T15:09:40.153238-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m  version: 1.10.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mgenerated: "2025-12-18T15:48:33.78433-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/jobs/Chart.yaml b/test/fixtures/jobs/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex a340089..3930d4f 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/jobs/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/jobs/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m     repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    version: "1.9.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    version: "1.10.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/microservice/Chart.lock b/test/fixtures/microservice/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex 175e535..5e09d6a 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/microservice/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/microservice/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -1,6 +1,6 @@[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  version: 1.9.0[m[m[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m:[3m^M[23m[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-generated: "2025-12-17T15:09:41.172052-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m  version: 1.10.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mgenerated: "2025-12-18T15:48:34.458044-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/microservice/Chart.yaml b/test/fixtures/microservice/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex a340089..3930d4f 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/microservice/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/microservice/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m     repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    version: "1.9.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    version: "1.10.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/podspec/Chart.lock b/test/fixtures/podspec/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex 81d141e..fe1822a 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/podspec/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/podspec/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -1,6 +1,6 @@[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  version: 1.9.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-generated: "2025-12-17T15:09:42.257485-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m  version: 1.10.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mgenerated: "2025-12-18T15:48:35.155465-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/podspec/Chart.yaml b/test/fixtures/podspec/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex a340089..3930d4f 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/podspec/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/podspec/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m     repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    version: "1.9.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    version: "1.10.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/statefulsets/Chart.lock b/test/fixtures/statefulsets/Chart.lock[m[m[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m:[3m^M[23m[1mindex 972d85f..e0ee5a1 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/statefulsets/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/statefulsets/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -1,6 +1,6 @@[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  version: 1.9.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-generated: "2025-12-17T15:09:43.332944-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m  version: 1.10.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mgenerated: "2025-12-18T15:48:35.830031-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/statefulsets/Chart.yaml b/test/fixtures/statefulsets/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex a340089..3930d4f 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/statefulsets/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/statefulsets/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m     repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    version: "1.9.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    version: "1.10.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/test_cronjobs.bats b/test/test_cronjobs.bats[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex ba9641f..718d4a0 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/test_cronjobs.bats[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/test_cronjobs.bats[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -19,7 +19,7 @@[m [mteardown() {[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m        assert_output --partial 'test.override.annotation: hello-override-world'[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   assert_output --partial 'testOverrideLabel: hello-override-world'[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   assert_output --partial 'name: test-cronjobs'[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  assert_output --partial 'podAntiAffinity'[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m  assert_output --partial 'nodeAffinity'[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   assert_output --partial 'schedule: "0 * * * *"'[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m }[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m [m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/test_jobs.bats b/test/test_jobs.bats[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex 66a463b..b2b3dce 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/test_jobs.bats[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/test_jobs.bats[m[m[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m:[3m^M[23m[36m@@ -16,7 +16,7 @@[m [mteardown() {[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   run helm template -f test/fixtures/jobs/values-basic.yaml test/fixtures/jobs/[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   assert_output --partial 'kind: Job'[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   assert_output --partial 'helm.sh/hook: pre-install,pre-upgrade'[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  assert_output --partial 'podAntiAffinity'[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m  assert_output --partial 'nodeAffinity'[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m }[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m [m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m # bats test_tags=tag:basic[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/test_pod_affinity.bats b/test/test_pod_affinity.bats[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex 2d3e846..4b9e0b3 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/test_pod_affinity.bats[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/test_pod_affinity.bats[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -36,5 +36,5 @@[m [mteardown() {[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m # bats test_tags=tag:affinity-disabled[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m @test "affinity: allows disabling automatic anti-affinity" {[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   run helm template -f test/fixtures/affinity/values-anti-affinity-disabled.yaml test/fixtures/affinity/[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  refute_output --partial 'podAntiAffinity'[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m  refute_output --partial 'karpenter.sh/controller'[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m }[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[3m(END)[23m[3m^M^G^M[23m[3m(END)[23m[3m^M^M[23m[3m(END)[23m[3m^M^M[23m[3m(END)[23m[3m^M^M[23m[3m(END)[23m[3m^M^G^M[23m[3m(END)[23m[3m^M^M[23m[3m(END)[23m[3m^M^M[23m[3m(END)[23m[3m^M^M[23m[3m(END)[23m[3m^M^M[23m[3m(END)[23m[3m^M^M[23m[3m(END)[23m[3m^M^M[23m[3m(END)[23m[3m^M^M[23m[3m(END)[23m[3m^M[23m   - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/statefulsets/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/statefulsets/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex a340089..3930d4f 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/statefulsets/Chart.yaml b/test/fixtures/statefulsets/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mgenerated: "2025-12-18T15:48:35.830031-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m  version: 1.10.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-generated: "2025-12-17T15:09:43.332944-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  version: 1.9.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -1,6 +1,6 @@[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/statefulsets/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/statefulsets/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex 972d85f..e0ee5a1 100644[m[m[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m[1mdiff --git a/test/fixtures/statefulsets/Chart.lock b/test/fixtures/statefulsets/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    version: "1.10.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    version: "1.9.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m     repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/podspec/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/podspec/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex a340089..3930d4f 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/podspec/Chart.yaml b/test/fixtures/podspec/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mgenerated: "2025-12-18T15:48:35.155465-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m  version: 1.10.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-generated: "2025-12-17T15:09:42.257485-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  version: 1.9.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[3m^M[23m:[3m^M[23m[36m@@ -1,6 +1,6 @@[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/podspec/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/podspec/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex 81d141e..fe1822a 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/podspec/Chart.lock b/test/fixtures/podspec/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    version: "1.10.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    version: "1.9.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m     repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/microservice/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/microservice/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex a340089..3930d4f 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/microservice/Chart.yaml b/test/fixtures/microservice/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mgenerated: "2025-12-18T15:48:34.458044-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m  version: 1.10.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-generated: "2025-12-17T15:09:41.172052-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m[31m-  version: 1.9.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -1,6 +1,6 @@[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/microservice/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/microservice/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex 175e535..5e09d6a 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/microservice/Chart.lock b/test/fixtures/microservice/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    version: "1.10.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    version: "1.9.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m     repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/jobs/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/jobs/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex a340089..3930d4f 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/jobs/Chart.yaml b/test/fixtures/jobs/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mgenerated: "2025-12-18T15:48:33.78433-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[3m^M[23m:[3m^M[23m[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m  version: 1.10.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-generated: "2025-12-17T15:09:40.153238-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  version: 1.9.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -1,6 +1,6 @@[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/jobs/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/jobs/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex 56db834..421b54a 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/jobs/Chart.lock b/test/fixtures/jobs/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    version: "1.10.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    version: "1.9.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m     repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/ingresses/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m[1m--- a/test/fixtures/ingresses/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex a340089..3930d4f 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/ingresses/Chart.yaml b/test/fixtures/ingresses/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mgenerated: "2025-12-18T15:48:32.804286-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m  version: 1.10.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-generated: "2025-12-17T15:09:39.098876-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  version: 1.9.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -1,6 +1,6 @@[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/ingresses/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/ingresses/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex 667c567..c657dbe 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/ingresses/Chart.lock b/test/fixtures/ingresses/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    version: "1.10.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    version: "1.9.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m     repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[3m^M[23m:[3m^M[23m   - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/deployments/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/deployments/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex a340089..3930d4f 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/deployments/Chart.yaml b/test/fixtures/deployments/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mgenerated: "2025-12-18T15:48:32.086635-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m  version: 1.10.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-generated: "2025-12-17T15:09:38.012485-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  version: 1.9.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -1,6 +1,6 @@[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/deployments/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/deployments/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex 7ff4ddb..bc38e20 100644[m[m[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m[1mdiff --git a/test/fixtures/deployments/Chart.lock b/test/fixtures/deployments/Chart.lock[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m    version: "1.10.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-    version: "1.9.0"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m     repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m+++ b/test/fixtures/cronjobs/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m--- a/test/fixtures/cronjobs/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mindex a340089..3930d4f 100644[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1mdiff --git a/test/fixtures/cronjobs/Chart.yaml b/test/fixtures/cronjobs/Chart.yaml[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mgenerated: "2025-12-18T15:48:31.352985-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[32m+[m[32m  version: 1.10.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-generated: "2025-12-17T15:09:32.450577-06:00"[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[31m-  version: 1.9.0[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m   repository: file://../../../charts/common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m - name: common[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m dependencies:[m[m[m[41m[3m^M[23m[m[m
[32m+[m[32m[3m^M[23m:[3m^M[23m[1m[3m%[23m[1m[0m                                                                                                                                                      [m [32m[m[32m[1m[3m[23m[1m[0m      [3m^M[23m [3m^M[23m..t/helm-chartsile://negroni/Users/chris.reisor/git/helm-charts[3m^M[23m[0m[23m[24m[01;32mchris.reisor@negroni[00m [01;34mgit/helm-charts[00m [33m(INFRASEC-4257-affinity-and-topology) [00m[00m[1m»[0m [1mm[0make[m [32m[m[32m[1m[3m[23m[1m[0m[0m[23m[24m[01;32m[00m[01;34m[00m[33m[00m[00m[1m[0m test[m[41m[3m^M[23m[m[m
[32m+[m[32mmakeBATSLIB_TEMP_PRESERVE_ON_FAILURE=1 AWS_PROFILE= test/bats/bin/bats --filter-tags tag:all test/[m[41m[3m^M[23m[m[m
[32m+[m[32m[34;1mtest_autoscaler.bats[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   autoscaler: outputs a template  1/111 ✓ autoscaler: outputs a template[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   autoscaler: matches expected output  2/111 ✓ autoscaler: matches expected output[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   autoscaler: if a minReplicas value is not provided, a defualt is used  3/111 ✓ autoscaler: if a minReplicas value is not provided, a defualt is used[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   autoscaler: if a maxReplicas value is not provided, a defualt is used  4/111 ✓ autoscaler: if a maxReplicas value is not provided, a defualt is used[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   autoscaler: overrides the averageUtilization value if provided  5/111 ✓ autoscaler: overrides the averageUtilization value if provided[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   autoscaler: cretes a memory resource utilization target if provided  6/111 ✓ autoscaler: cretes a memory resource utilization target if provided[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m[34;1mtest_clusterexternalsecret.bats[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   clusterexternalsecret: outputs a template  7/111 ✓ clusterexternalsecret: outputs a template[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   clusterexternalsecret: matches expected output  8/111 ✓ clusterexternalsecret: matches expected output[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   clusterexternalsecret: allows overriding apiVersion  9/111 ✓ clusterexternalsecret: allows overriding apiVersion[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m[34;1mtest_configmaps.bats[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   configmaps: outputs a template 10/111 ✓ configmaps: outputs a template[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   configmaps: matches expected output 11/111 ✓ configmaps: matches expected output[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   configmaps: file templating works 12/111 ✓ configmaps: file templating works[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   configmaps: inline templating works 13/111 ✓ configmaps: inline templating works[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m[0m   configmaps: multiple templates works 14/111 ✓ configmaps: multiple templates works[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   configmaps: inline multiple templates works 15/111 ✓ configmaps: inline multiple templates works[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   configmaps: dumps contents of a file 16/111 ✓ configmaps: dumps contents of a file[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   configmaps: dumps contents of a json file 17/111 ✓ configmaps: dumps contents of a json file[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   configmaps: dumps contents of a yaml file 18/111 ✓ configmaps: dumps contents of a yaml file[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m[34;1mtest_containers.bats[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   containers: outputs a template 19/111 ✓ containers: outputs a template[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   containers: matches expected output 20/111 ✓ containers: matches expected output[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   containers: fails when containers are specified as a list 21/111 ✓ containers: fails when containers are specified as a list[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   containers: fails when initContainers have no resources 22/111 ✓ containers: fails when initContainers have no resources[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   containers: fails when initContainers are specified as a map 23/111 ✓ containers: fails when initContainers are specified as a map[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   containers: fails when no image is specified 24/111 ✓ containers: fails when no image is specified[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   containers: fails when no livenessProbe is specified 25/111 ✓ containers: fails when no livenessProbe is specified[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   containers: does not include livenessProbe if disabled 26/111 ✓ containers: does not include livenessProbe if disabled[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   containers: overrides livenessProbe defaults 27/111 ✓ containers: overrides livenessProbe defaults[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   containers: fails when no readinessProbe is specified 28/111 ✓ containers: fails when no readinessProbe is specified[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   containers: does not include readinessProbe if disabled 29/111 ✓ containers: does not include readinessProbe if disabled[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   containers: overrides readinessProbe defaults 30/111 ✓ containers: overrides readinessProbe defaults[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   containers: fails when no resources are specified 31/111 ✓ containers: fails when no resources are specified[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   containers: includes CLUSTER_NAME env var if gitops bridge specifies it in spec 32/111 ✓ containers: includes CLUSTER_NAME env var if gitops bridge speci[m [32m[m[32m[0mfies it in spec[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m[34;1mtest_cronjobs.bats[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   cronjobs: outputs a template 33/111 ✓ cronjobs: outputs a template[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   cronjobs: matches expected output 34/111 ✓ cronjobs: matches expected output[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   cronjobs: includes service account if specified in the global section 35/111 ✓ cronjobs: includes service account if specified in the global section[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   cronjobs: includes service account if specified 36/111 ✓ cronjobs: includes service account if specified[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   cronjobs: suspends job if disabled is true 37/111 ✓ cronjobs: suspends job if disabled is true[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   cronjobs: overrides default concurrencyPolicy 38/111 ✓ cronjobs: overrides default concurrencyPolicy[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   cronjobs: overrides default failedJobsHistoryLimit 39/111 ✓ cronjobs: overrides default failedJobsHistoryLimit[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   cronjobs: overrides default successfulJobsHistoryLimit 40/111 ✓ cronjobs: overrides default successfulJobsHistoryLimit[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   cronjobs: adds startingDeadlineSeconds if defined 41/111 ✓ cronjobs: adds startingDeadlineSeconds if defined[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   cronjobs: fails when no scheudle is defined 42/111 ✓ cronjobs: fails when no scheudle is defined[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   cronjobs: includes timeZone if specified 43/111 ✓ cronjobs: includes timeZone if specified[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m[34;1mtest_deployments.bats[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   deployments: outputs a template 44/111 ✓ deployments: outputs a template[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   deployments: matches expected output 45/111 ✓ deployments: matches expected output[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   deployments: specify the selector 46/111 ✓ deployments: specify the selector[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   deployments: if there is no global serviceAccount, uses the one in the deployment 47/111 - deployments: if there is no global serviceAccount, uses the on[m [32m[m[32m[0me in the deployment (skipped: this should work, but it doesn't (see also the skipped cronjobs test))[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   deployments: adds serviceAccount role if specified 48/111 ✓ deployments: adds serviceAccount role if specified[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m[0m   deployments: forces type to string when awsAccountId is unquoted 49/111 ✓ deployments: forces type to string when awsAccountId is unquoted[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   deployments: renders ClusterExternalSecret if secrets are included 50/111 ✓ deployments: renders ClusterExternalSecret if secrets are included[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   deployments: renders podDisruptionBudget if included 51/111 ✓ deployments: renders podDisruptionBudget if included[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   deployments: renders podDisruptionBudget with maxUnavailable 52/111 ✓ deployments: renders podDisruptionBudget with maxUnavailable[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   deployments: renders podDisruptionBudget with minAvailable as a percentage 53/111 ✓ deployments: renders podDisruptionBudget with minAvailable as a perce[m [32m[m[32m[0mntage[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   deployments: ensures a separate document between all deployments when PDBs are defined 54/111 ✓ deployments: ensures a separate document between all depl[m [32m[m[32m[0moyments when PDBs are defined[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m[34;1mtest_ingresses.bats[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   oauth: outputs a template with auth annotations 55/111 ✓ oauth: outputs a template with auth annotations[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   ouath: matches expected output 56/111 ✓ ouath: matches expected output[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   nodns: outputs a template with no external-dns annotation 57/111 ✓ nodns: outputs a template with no external-dns annotation[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   nodns: matches expected output 58/111 ✓ nodns: matches expected output[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   basicauth: outputs a template with no external-dns annotation 59/111 ✓ basicauth: outputs a template with no external-dns annotation[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   basicauth: matches expected output 60/111 ✓ basicauth: matches expected output[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   nginx-external: outputs a template with an ingress class name called nginx 61/111 ✓ nginx-external: outputs a template with an ingress class name called [m [32m[m[32m[0mnginx[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   nginx-external: matches expected output 62/111 ✓ nginx-external: matches expected output[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   nginx-ingress: fails if service is not specified 63/111 ✓ nginx-ingress: fails if service is not specified[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   basicauth: uses appDomain and rootDomain to construct a hostname if none specified 64/111 ✓ basicauth: uses appDomain and rootDomain to construct a hostn[m [32m[m[32m[0mame if none specified[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   alb-internal: matches expected output 65/111 ✓ alb-internal: matches expected output[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   alb-external: sets scheme 66/111 ✓ alb-external: sets scheme[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   alb-scheme-error: ensures a scheme is set 67/111 ✓ alb-scheme-error: ensures a scheme is set[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   alb-certarn-error: ensures a certificateArn is set 68/111 ✓ alb-certarn-error: ensures a certificateArn is set[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   gitops-bridge: if Values has a spec field (usually from Gitops Bridge), ensure annotations are set 69/111 ✓ gitops-bridge: if Values has a spec field (us[m [32m[m[32m[0mually from Gitops Bridge), ensure annotations are set[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   default-alb: if no ingressClass is set, default to alb 70/111 ✓ default-alb: if no ingressClass is set, default to alb[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   alb-imperva: sets imperva-related annotations and scheme 71/111 ✓ alb-imperva: sets imperva-related annotations and scheme[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   alb-imperva-multiple-hostnames: sets imperva-related annotations and scheme with multiple hostnames 72/111 ✓ alb-imperva-multiple-hostnames: sets imperva[m [32m[m[32m[0m-related annotations and scheme with multiple hostnames[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   alb-imperva-internal-scheme: fails if the scheme is internal 73/111 ✓ alb-imperva-internal-scheme: fails if the scheme is internal[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   alb-healthcheck-port: sets healthcheck-port annotation if specified 74/111 ✓ alb-healthcheck-port: sets healthcheck-port annotation if specified[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   alb-healthcheck-protocol: sets healthcheck-protocl annotation if specified 75/111 ✓ alb-healthcheck-protocol: sets healthcheck-protocl annotation if spec[m [32m[m[32m[0mified[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   alb-aliases: sets alb host header annotations with hostnameAliases 76/111 ✓ alb-aliases: sets alb host header annotations with hostnameAliases[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   www-redirect: creates annotations to redirect base domain to www 77/111 ✓ www-redirect: creates annotations to redirect base domain to www[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m[34;1mtest_jobs.bats[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   jobs: outputs a template 78/111 ✓ jobs: outputs a template[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   jobs: matches expected output 79/111 ✓ jobs: matches expected output[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m[0m   jobs: backoffLimit gets set as expected 80/111 ✓ jobs: backoffLimit gets set as expected[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   jobs: completions gets set as expected 81/111 ✓ jobs: completions gets set as expected[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   jobs: parallelism gets set as expected 82/111 ✓ jobs: parallelism gets set as expected[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   jobs: activeDeadlineSeconds gets set as expected 83/111 ✓ jobs: activeDeadlineSeconds gets set as expected[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   jobs: restartPolicy gets overridden 84/111 ✓ jobs: restartPolicy gets overridden[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   jobs: livenessProbe and readinessProbe get overridden 85/111 ✓ jobs: livenessProbe and readinessProbe get overridden[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   jobs: uses job serviceAccount if there is no global one 86/111 - jobs: uses job serviceAccount if there is no global one (skipped: this should work, but [m [32m[m[32m[0mit doesn't (see skipped test in cronjobs and deployments tests))[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m[34;1mtest_microservice.bats[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   microservice: outputs a template 87/111 ✓ microservice: outputs a template[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   microservice: matches expected output 88/111 ✓ microservice: matches expected output[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   microservice: fails when no global section is defined 89/111 ✓ microservice: fails when no global section is defined[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   microservice: fails when no global labels are defined 90/111 ✓ microservice: fails when no global labels are defined[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m[34;1mtest_pod_affinity.bats[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   affinity: outputs a template 91/111 ✓ affinity: outputs a template[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   affinity: matches expected output 92/111 ✓ affinity: matches expected output[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   affinity: allows overriding the anti-affinity label 93/111 ✓ affinity: allows overriding the anti-affinity label[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   affinity: allows disabling automatic anti-affinity 94/111 ✓ affinity: allows disabling automatic anti-affinity[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m[34;1mtest_podspec.bats[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   podspec: outputs a template 95/111 ✓ podspec: outputs a template[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   podspec: matches expected output 96/111 ✓ podspec: matches expected output[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   podspec: allows overriding topologySpreadConstraints 97/111 ✓ podspec: allows overriding topologySpreadConstraints[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   podspec: default topologySpreadConstraints can override whenUnsatisfiable 98/111 ✓ podspec: default topologySpreadConstraints can override whenUnsatisfia[m [32m[m[32m[0mble[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   podspec: legacy topologySpreadConstraints syntax fails 99/111 ✓ podspec: legacy topologySpreadConstraints syntax fails[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   podspec: specify the selector100/111 - podspec: specify the selector (skipped: this should work, but it doesn't -- in the future, look into lines 13-19 i[m [32m[m[32m[0mn _pod_spec.yaml.tpl)[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   podspec: if there is no global serviceAccount, uses the one in the deployment101/111 - podspec: if there is no global serviceAccount, uses the one in the[m [32m[m[32m[0m deployment (skipped: this should work, but it doesn't (see also the skipped cronjobs test))[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   podspec: includes imagePullSecrets if there's a imagePullSecretsName102/111 ✓ podspec: includes imagePullSecrets if there's a imagePullSecretsName[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   podspec: overrides serviceaccount set in pod103/111 - podspec: overrides serviceaccount set in pod (skipped: more problematic serviceAccount logic)[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   podspec: disables service links if set104/111 ✓ podspec: disables service links if set[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   podspec: overrides restartPolicy default of 'Always'105/111 ✓ podspec: overrides restartPolicy default of 'Always'[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   podspec: sets fsGroupChangePolicy if the policy contains fsGroup106/111 ✓ podspec: sets fsGroupChangePolicy if the policy contains fsGroup[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   podspec: overrides the default terminationGracePeriodSeconds107/111 ✓ podspec: overrides the default terminationGracePeriodSeconds[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   podspec: helpful output when livenessProbe is removed108/111 ✓ podspec: helpful output when livenessProbe is removed[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   podspec: helpful output when readinessProbe is removed109/111 ✓ podspec: helpful output when readinessProbe is removed[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m[34;1mtest_statefulsets.bats[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   statefulsets: outputs a template110/111 ✓ statefulsets: outputs a template[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m   statefulsets: matches expected output111/111 ✓ statefulsets: matches expected output[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m[0m[32;1m[m[41m[3m^M[23m[m[m
[32m+[m[32m111 tests, 0 failures, 5 skipped[m[41m[3m^M[23m[m[m
[32m+[m[32m[0m[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m[3m%[23m[1m[0m                                                                                                                                                           [m [32m[m[32m[1m[3m[23m[1m[0m [3m^M[23m [3m^M[23m..t/helm-chartsile://negroni/Users/chris.reisor/git/helm-charts[3m^M[23m[0m[23m[24m[01;32mchris.reisor@negroni[00m [01;34mgit/helm-charts[00m [33m(INFRASEC-4257-affinity-and-topology) [00m[00m[1m»[0m [m[41m[3m^M[23m[m[m
[32m+[m[32mbck-i-search: _g pus[4mh[24m[3m^H^H^H[23m     [24m _ [3m^G^G[23m[0m[23m[24m[01;32mchris.reisor@negroni[00m [01;34mgit/helm-charts[00m [33m(INFRASEC-4257-affinity-and-topology) [00m[00m[1m»[0m [m[41m[3m^M[23m[m[m
[32m+[m[32mbck-i-search: _g pus[4mh[24m[3m^H^H^H[23muv ru[24mn github_org_stats.py --[4mhe[24mlp #--org provi-engineering --e_[4me[4ml[24ml_output stats_failed_repos.csv --repos AdHaus HappyHourCustomer[m [32m[m[32m[4m[24m[24m[4m[24m[4m[4m[24mSkuMessageCreatorLambda HappyHourDistributorSelectorLambda HappyHourHistoricPricePersistorLambda ResturantMenuWebCrawler Semantic-UI Semantic-UI-React Terroi[m [32m[m[32m[4m[24m[24m[4m[24m[4m[4m[24mr ZipToZoneFileCreator analytics analytics-draft api-listener argocd-orb asset_sync auth0 awsbastion-infra backbone-on-rails backup_dns bar-tab barback barta[m [32m[m[32m[4m[24m[24m[4m[24m[4m[4m[24mb beacon beacon_eks bevPOS bmg-bevsites bmg-bevsites-fedex-api bmg-eorders bmg-ets bmg-nysla bmg-subscription bootlegger bootlegger-bakeoff bootlegger-webhoo[m [32m[m[32m[4m[24m[24m[4m[24m[4m[4m[24mk-lambda-authorizer bootlegger-worker boozechoose bottle-shots bottler bottling-plant bouncer boxes brewery brewery_consumer buymore cheers cheers-backend ch[m [32m[m[32m[4m[24m[24m[4m[24m[4m[4m[24meers-frontend ci_metrics cicerone-lib cicerone-state-machines cluster-canary configtest-app configtest-config craft crm-sync crowdstrike-image-puller crowdst[m [32m[m[32m[4m[24m[24m[4m[24m[4m[4m[24mrike-terraform data_science_research datadog-terraform datawarehouse_migration delayed_job devmachine devops-onboarding disburse distiller distillery dockerf[m [32m[m[32m[4m[24m[24m[4m[24m[4m[4m[24miles dockerized-beacon downstream dpinsert e2e_pilot ec2runner eks-upgrade-pipeline entity-matching-docker epicwin experian finix fizz-mobile-app fizzbook fo[m [32m[m[32m[4m[24m[24m[4m[24m[4m[4m[24mrklift forklift-lambda gh-admin-automation githooks glue-patcher happy-hour happy-hour-validation-service helm-charts_old [4mh[4melm[24m-deployments heroku-buildpack-r[m [32m[m[32m[4m[24m[24m[4m[24m[4m[4m[24m[4m[4m[24muby heroku-shared-postgres imperva-serverswap ingresstest interview-questions jenkins-kube-test jenkins-local jenkinsdeployer josefine kafka_api kyverno-poli[m [32m[m[32m[4m[24mu[24m[4m[24m[4m[4m[24m[4m[4m[24mcies license-parser liquid-analytics-sandbox loadtest looker mcgruff meltano mixologist mycoolworkload node-socket-wrap nysla nysla-maintenance onestackutili[m [32m[m[32m[4m[24mu[24m[4m[24m[4m[4m[24m[4m[4m[24mties pallet pallet_eks palletwebhooks payments-postman-collections pg_jbuilder pos-integrations post-office-api post-office-worker proof-read prosecco provi-[m [32m[m[32m[4m[24mu[24m[4m[24m[4m[4m[24m[4m[4m[24mecs-events provi-eks provi-eks-workloads provi-imperva-client provi-scheduler-partner-batch-sf-api provi-sftp-scheduler-app provi-tradegecko provi_retailer_v[m [32m[m[32m[4m[24mu[24m[4m[24m[4m[4m[24m[4m[4m[24miz punchout-simulator puppeteer-heroku-buildpack qa-automation rails_phone react-native-config react-native-cookies recommendation-engine retailers_address_m[m [32m[m[32m[4m[24mu[24m[4m[24m[4m[4m[24m[4m[4m[24matching_lambdas rspec-retry rubybuilder sandbox sandbox-golang sauce sevenfiftydaily sfcore-ui siphond siphond-config skel slackcommands snowflake-flyway sns[m [32m[m[32m[4m[24mu[24m[4m[24m[4m[4m[24m[4m[4m[24m-to-slack-lambda-function sommelier sommelier-config speedrail-datafiles speedrail-dev-tools speedrail-ui state-manager state-manager-scripts sumologic_terra[m [32m[m[32m[4m[24mu[24m[4m[24m[4m[4m[24m[4m[4m[24mform supplier-service templates terraform-eks-lens victualler wine-cellar-validator wine-cellar-valildator[m[41m[3m^M[23m[m[m
[32m+[m[32m[m[41m[3m^M[23m[m[m
[32m+[m[32mbck-i-search: helm_[3m^M[23m[4mh[4me[4ml[4mm[4m [24mrollback --help[3m^M[23mbck-i-search: helm _[3m^M^G[23m[24mh[24me[24ml[24mm[24m [3m^M[23mfailing bck-i-search: helm t_e_m_p_l_a_t_e_[3m^G[23m                    [3m^M^M[23mbck-i-search:[m [32m[m[32m[4m[4m[4m[4m[4m[24m[24m[24m[24m[24m[24m _make tes[4mt[24m[3m^H[23m[4mt[4me[24ms[24m[3m^H^H[23mcat n[24mo[24mdepools/[4mtem[24mplates/default_v1.yaml| pbcopym_[4mm[4mp[24mp_[4mp[4ml[24ml_[4ml[4ma[24ma_[4ma[4mt[24mt_[4mt[4me[24me_[3m^G[23m[24mt[24me[24mm[24mp[24ml[24ma[24mt[24me[3m^M[23mfailing bck-i-search: template _[3m^G[23m                       [m [32m[m[32m[4m[4m[4m[4m[4m[24m[24m[24m[24m[24m[24m[4m[24m[4m[4m[24m[24mc[24m[24m[4m[24m[4m[4m[24m[4m[4m[24m[4m[4m[24m[4m[4m[24m[4m[4m[24m[24m[24m[24m[24m[24m[24m[24m[24m                        [3m^M[23m[1mh[0melm template -f [3m^M[23m[1m[3m%[23m[1m[0m                                                                                                               [m [32m[m[32m[4m[4m[4m[4m[4m[24m[24m[24m[24m[24m[24m[4m[24m[4m[4m[24m[24mc[24m[24m[4m[24m[4m[4m[24m[4m[4m[24m[4m[4m[24m[4m[4m[24m[4m[4m[24m[24m[24m[24m[24m[24m[24m[24m[24m[1m[3m[23m[1m[0m                                             [3m^M[23m [3m^M[23m..t/helm-chartsile://negroni/Users/chris.reisor/git/helm-charts[3m^M[23m[0m[23m[24m[01;32mchris.reisor@negroni[00m [01;34mgit/helm-charts[00m [33m(INFR[m [32m[m[32m[4m[4m[4m[4m[4m[24m[24m[24m[24m[24m[24m[4m[24m[4m[4m[24m[24mc[24m[24m[4m[24m[4m[4m[24m[4m[4m[24m[4m[4m[24m[4m[4m[24m[4m[4m[24m[24m[24m[24m[24m[24m[24m[24m[24m[1m[3m[23m[1m[0m[0m[23m[24m[01;32m[00m[01;34m[00m[33mASEC-4257-affinity-and-topology) [00m[00m[1m»[0m [01;31m130 ↵[00m[m[41m[3m^M[23m[m[m
[32m+[m[32mbck-i-search: _g pus[4mh[24m[3m^H^H^H[23muv ru[24mn github_org_stats.py --[4mhe[24mlp #--org provi-engineering --e_[4me[4ml[24ml_output stats_failed_repos.csv --repos AdHaus HappyHourCustomerS[m [32m[m[32m[4m[24m[24m[4m[24m[4m[4m[24mkuMessageCreatorLambda HappyHourDistributorSelectorLambda HappyHourHistoricPricePersistorLambda ResturantMenuWebCrawler Semantic-UI Semantic-UI-React Terroir[m [32m[m[32m[4m[24m[24m[4m[24m[4m[4m[24m ZipToZoneFileCreator analytics analytics-draft api-listener argocd-orb asset_sync auth0 awsbastion-infra backbone-on-rails backup_dns bar-tab barback bartab[m [32m[m[32m[4m[24m[24m[4m[24m[4m[4m[24m beacon beacon_eks bevPOS bmg-bevsites bmg-bevsites-fedex-api bmg-eorders bmg-ets bmg-nysla bmg-subscription bootlegger bootlegger-bakeoff bootlegger-webhook[m [32m[m[32m[4m[24m[24m[4m[24m[4m[4m[24m-lambda-authorizer bootlegger-worker boozechoose bottle-shots bottler bottling-plant bouncer boxes brewery brewery_consumer buymore cheers cheers-backend che[m [32m[m[32m[4m[24m[24m[4m[24m[4m[4m[24mers-frontend ci_metrics cicerone-lib cicerone-state-machines cluster-canary configtest-app configtest-config craft crm-sync crowdstrike-image-puller crowdstr[m [32m[m[32m[4m[24m[24m[4m[24m[4m[4m[24mike-terraform data_science_research datadog-terraform datawarehouse_migration delayed_job devmachine devops-onboarding disburse distiller distillery dockerfi[m [32m[m[32m[4m[24m[24m[4m[24m[4m[4m[24mles dockerized-beacon downstream dpinsert e2e_pilot ec2runner eks-upgrade-pipeline entity-matching-docker epicwin experian finix fizz-mobile-app fizzbook for[m [32m[m[32m[4m[24m[24m[4m[24m[4m[4m[24mklift forklift-lambda gh-admin-automation githooks glue-patcher happy-hour happy-hour-validation-service helm-charts_old [4mh[4melm[24m-deployments heroku-buildpack-ru[m [32m[m[32m[4m[24m[24m[4m[24m[4m[4m[24m[4m[4m[24mby heroku-shared-postgres imperva-serverswap ingresstest interview-questions jenkins-kube-test jenkins-local jenkinsdeployer josefine kafka_api kyverno-polic[m [32m[m[32m[4m[24mu[24m[4m[24m[4m[4m[24m[4m[4m[24mies license-parser liquid-analytics-sandbox loadtest looker mcgruff meltano mixologist mycoolworkload node-socket-wrap nysla nysla-maintenance onestackutilit[m :[K[K[32m[m[32m[4m[24mu[24m[4m[24m[4m[4m[24m[4m[4m[24mies pallet pallet_eks palletwebhooks payments-postman-collections pg_jbuilder pos-integrations post-office-api post-office-worker proof-read prosecco provi-e[m [32m[m[32m[4m[24mu[24m[4m[24m[4m[4m[24m[4m[4m[24mcs-events provi-eks provi-eks-workloads provi-imperva-client provi-scheduler-partner-batch-sf-api provi-sftp-scheduler-app provi-tradegecko provi_retailer_vi[m [32m[m[32m[4m[24mu[24m[4m[24m[4m[4m[24m[4m[4m[24mz punchout-simulator puppeteer-heroku-buildpack qa-automation rails_phone react-native-config react-native-cookies recommendation-engine retailers_address_ma[m [32m[m[32m[4m[24mu[24m[4m[24m[4m[4m[24m[4m[4m[24mtching_lambdas rspec-retry rubybuilder sandbox sandbox-golang sauce sevenfiftydaily sfcore-ui siphond siphond-config skel slackcommands snowflake-flyway sns-[m [32m[m[32m[4m[24mu[24m[4m[24m[4m[4m[24m[4m[4m[24mto-slack-lambda-function sommelier sommelier-config speedrail-datafiles speedrail-dev-tools speedrail-ui state-manager state-manager-scripts sumologic_terraf[m [32m[m[32m[4m[24mu[24m[4m[24m[4m[4m[24m[4m[4m[24morm supplier-service templates terraform-eks-lens victualler wine-cellar-validator wine-cellar-valildator[m[41m[3m^M[23m[m[m
[32m+[m[32m[m[41m[3m^M[23m[m[m
[32m+[m[32mbck-i-search: helm_[3m^M[23m[4mh[4me[4ml[4mm[4m [24mrollback --help[01;31m130 ↵[00m[3m^M[23mbck-i-search: helm _[3m^M^G[23m[24mh[24me[24ml[24mm[24m [3m^M[23mfailing bck-i-search: helm t_e_p_l_a_g_e__ _ [3m^G[23m                    [3m^M[23m[1mh[0mhelm te[m [32m[m[32m[4m[4m[4m[4m[4m[24m[01;31m[00m[24m[24m[24m[24m[24mmpl[3m^M[23m[1m[3m%[23m[1m[0m                                                                                                                                                       [m [32m[m[32m[4m[4m[4m[4m[4m[24m[01;31m[00m[24m[24m[24m[24m[24m[1m[3m[23m[1m[0m     [3m^M[23m [3m^M[23m^L..t/helm-chartsile://negroni/Users/chris.reisor/git/helm-charts[3m^M[23m[0m[23m[24m[01;32mchris.reisor@negroni[00m [01;34mgit/helm-charts[00m [33m(INFRASEC-4257-affinity-and-topology) [00m[00m[1m»[0m [01;31m130[m [32m[m[32m[4m[4m[4m[4m[4m[24m[01;31m[00m[24m[24m[24m[24m[24m[1m[3m[23m[1m[0m[0m[23m[24m[01;32m[00m[01;34m[00m[33m[00m[00m[1m[0m[01;31m ↵[00m[0m[23m[24m[01;32mchris.reisor@negroni[00m [01;34mgit/helm-charts[00m [33m(INFRASEC-4257-affinity-and-topology) [00m[00m[1m»[0m [01;31m130 ↵[00m[1mh[0melm template -f test/fixtures[1m/[0m[3m^H[23m[0m/affinity[1m/[0m[3m^H[23m[0m/values-[3m^G[23m[m[41m[3m^M[23m[m[m
[32m+[m[32m[0mvalues-anti-affinity-disabled.yaml   values-anti-affinity-overrides.yaml  values-basic.yaml                  [0m[23m[24m[0m[3m^M[23mhelm template -f test/fixtures/affinity/value[m [32m[m[32m[0m[0m[23m[24m[0ms-[01;31m130 ↵[00m[0maff[3m^G[23m[m[41m[3m^M[23m[m[m
[32m+[m[32min[3m^G^H^H[23m [3m^H^H^H[23m [3m^H^H^G[23m[m[41m[3m^M[23m[m[m
[32m+[m[32m[0mvalues-anti-affinity-disabled.yaml   values-anti-affinity-overrides.yaml  values-basic.yaml                  [0m[23m[24m[0m[3m^M[23mhelm template -f test/fixtures/affinity/value[m [32m[m[32m[0m[0m[23m[24m[0ms-[01;31m130 ↵[00m[0man[m[41m[3m^M[23m[m[m
[32m+[m[32mti-affinity-disabled.yaml[1m [0m[3m^H[23m[0m test/ [3m^M[23mf[3m^M[23mfixtures[1m/[0m[3m^H[23m[0m/affinity[1m/[0m[3m^H[23m[0m[m[41m[3m^M[23m[m[m
[32m+[m[32mhelm---[m[41m[3m^M[23m[m[m
[32m+[m[32m# Source: my-cool-app/templates/microservice.yaml.tpl[m[41m[3m^M[23m[m[m
[32m+[m[32mapiVersion: apps/v1[m[41m[3m^M[23m[m[m
[32m+[m[32mkind: Deployment[m[41m[3m^M[23m[m[m
[32m+[m[32mmetadata:[m[41m[3m^M[23m[m[m
[32m+[m[32m  name: web[m[41m[3m^M[23m[m[m
[32m+[m[32m  annotations:[m[41m[3m^M[23m[m[m
[32m+[m[32m    provi.repository: https://github.com/example/repo[m[41m[3m^M[23m[m[m
[32m+[m[32m    provi.slack: my-cool-team[m[41m[3m^M[23m[m[m
[32m+[m[32m  labels:[m[41m[3m^M[23m[m[m
[32m+[m[32m    app: web[m[41m[3m^M[23m[m[m
[32m+[m[32m    app.kubernetes.io/name: dummy[m[41m[3m^M[23m[m[m
[32m+[m[32m    chart: my-cool-app[m[41m[3m^M[23m[m[m
[32m+[m[32m    chartVersion: 1.0.0[m[41m[3m^M[23m[m[m
[32m+[m[32m    team: cool-team[m[41m[3m^M[23m[m[m
[32m+[m[32mspec:[m[41m[3m^M[23m[m[m
[32m+[m[32m  replicas: 3[m[41m[3m^M[23m[m[m
[32m+[m[32m  selector:[m[41m[3m^M[23m[m[m
[32m+[m[32m    matchLabels:[m[41m[3m^M[23m[m[m
[32m+[m[32m      selector: my-cool-app-deployment-web[m[41m[3m^M[23m[m[m
[32m+[m[32m  template:[m[41m[3m^M[23m[m[m
[32m+[m[32m    metadata:[m[41m[3m^M[23m[m[m
[32m+[m[32m      annotations:[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m        provi.repository: https://github.com/example/repo[m[41m[3m^M[23m[m[m
[32m+[m[32m        provi.slack: my-cool-team[m[41m[3m^M[23m[m[m
[32m+[m[32m      labels:[m[41m[3m^M[23m[m[m
[32m+[m[32m        selector: my-cool-app-deployment-web[m[41m[3m^M[23m[m[m
[32m+[m[32m        app: web[m[41m[3m^M[23m[m[m
[32m+[m[32m        app.kubernetes.io/name: dummy[m[41m[3m^M[23m[m[m
[32m+[m[32m        chart: my-cool-app[m[41m[3m^M[23m[m[m
[32m+[m[32m        chartVersion: 1.0.0[m[41m[3m^M[23m[m[m
[32m+[m[32m        team: cool-team[m[41m[3m^M[23m[m[m
[32m+[m[32m    spec:[m[41m[3m^M[23m[m[m
[32m+[m[32m      topologySpreadConstraints:[m[41m[3m^M[23m[m[m
[32m+[m[32m      - maxSkew: 1[m[41m[3m^M[23m[m[m
[32m+[m[32m        topologyKey: topology.kubernetes.io/zone[m[41m[3m^M[23m[m[m
[32m+[m[32m        whenUnsatisfiable: DoNotSchedule[m[41m[3m^M[23m[m[m
[32m+[m[32m        labelSelector:[m[41m[3m^M[23m[m[m
[32m+[m[32m          matchLabels:[m[41m[3m^M[23m[m[m
[32m+[m[32m            app.kubernetes.io/name: "dummy"[m[41m[3m^M[23m[m[m
[32m+[m[32m      - maxSkew: 1[m[41m[3m^M[23m[m[m
[32m+[m[32m        topologyKey: kubernetes.io/hostname[m[41m[3m^M[23m[m[m
[32m+[m[32m        whenUnsatisfiable: DoNotSchedule[m[41m[3m^M[23m[m[m
[32m+[m[32m        labelSelector:[m[41m[3m^M[23m[m[m
[32m+[m[32m          matchLabels:[m[41m[3m^M[23m[m[m
[32m+[m[32m            app.kubernetes.io/name: "dummy"[m[41m[3m^M[23m[m[m
[32m+[m[32m      automountServiceAccountToken: false[m[41m[3m^M[23m[m[m
[32m+[m[32m      tolerations:[m[41m[3m^M[23m[m[m
[32m+[m[32m        - key: "spot"[m[41m[3m^M[23m[m[m
[32m+[m[32m          operator: "Exists"[m[41m[3m^M[23m[m[m
[32m+[m[32m          effect: "NoSchedule"[m[41m[3m^M[23m[m[m
[32m+[m[32m      restartPolicy: Always[m[41m[3m^M[23m[m[m
[32m+[m[32m      terminationGracePeriodSeconds: 30[m[41m[3m^M[23m[m[m
[32m+[m[32m      containers:[m[41m[3m^M[23m[m[m
[32m+[m[32m        - name: app[m[41m[3m^M[23m[m[m
[32m+[m[32m          image: docker.io/image:abcd1234[m[41m[3m^M[23m[m[m
[32m+[m[32m          imagePullPolicy: Always[m[41m[3m^M[23m[m[m
[32m+[m[32m          securityContext:[m[41m[3m^M[23m[m[m
[32m+[m[32m            runAsNonRoot: false[m[41m[3m^M[23m[m[m
[32m+[m[32m          env:[m[41m[3m^M[23m[m[m
[32m+[m[32m            - name: RACK_ENV[m[41m[3m^M[23m[m[m
[32m+[m[32m              value: "production"[m[41m[3m^M[23m[m[m
[32m+[m[32m            - name: RAILS_ENV[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m              value: "production"[m[41m[3m^M[23m[m[m
[32m+[m[32m          envFrom:[m[41m[3m^M[23m[m[m
[32m+[m[32m            - secretRef:[m[41m[3m^M[23m[m[m
[32m+[m[32m                name: dummy[m[41m[3m^M[23m[m[m
[32m+[m[32m          livenessProbe:[m[41m[3m^M[23m[m[m
[32m+[m[32m            initialDelaySeconds: 0[m[41m[3m^M[23m[m[m
[32m+[m[32m            periodSeconds: 5[m[41m[3m^M[23m[m[m
[32m+[m[32m            timeoutSeconds: 1[m[41m[3m^M[23m[m[m
[32m+[m[32m            failureThreshold: 5[m[41m[3m^M[23m[m[m
[32m+[m[32m            successThreshold: 1[m[41m[3m^M[23m[m[m
[32m+[m[32m            httpGet:[m[41m[3m^M[23m[m[m
[32m+[m[32m              path: /[m[41m[3m^M[23m[m[m
[32m+[m[32m              port: 8080[m[41m[3m^M[23m[m[m
[32m+[m[32m          resources:[m[41m[3m^M[23m[m[m
[32m+[m[32m            limits:[m[41m[3m^M[23m[m[m
[32m+[m[32m              memory: 256Mi[m[41m[3m^M[23m[m[m
[32m+[m[32m              ephemeral-storage: 200Mi[m[41m[3m^M[23m[m[m
[32m+[m[32m            requests:[m[41m[3m^M[23m[m[m
[32m+[m[32m              cpu: 250m[m[41m[3m^M[23m[m[m
[32m+[m[32m              memory: 256Mi[m[41m[3m^M[23m[m[m
[32m+[m[32m              ephemeral-storage: 200Mi[m[41m[3m^M[23m[m[m
[32m+[m[32m      affinity:[m[41m[3m^M[23m[m[m
[32m+[m[32m        nodeAffinity:[m[41m[3m^M[23m[m[m
[32m+[m[32m          requiredDuringSchedulingIgnoredDuringExecution:[m[41m[3m^M[23m[m[m
[32m+[m[32m            nodeSelectorTerms:[m[41m[3m^M[23m[m[m
[32m+[m[32m            - matchExpressions:[m[41m[3m^M[23m[m[m
[32m+[m[32m              - key: foo[m[41m[3m^M[23m[m[m
[32m+[m[32m                operator: In[m[41m[3m^M[23m[m[m
[32m+[m[32m                values:[m[41m[3m^M[23m[m[m
[32m+[m[32m                - bar[m[41m[3m^M[23m[m[m
[32m+[m[32m              - key: type[m[41m[3m^M[23m[m[m
[32m+[m[32m                operator: In[m[41m[3m^M[23m[m[m
[32m+[m[32m                values:[m[41m[3m^M[23m[m[m
[32m+[m[32m                - testaffinity[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m[3m%[23m[1m[0m                                                                                                                                                           [m [32m[m[32m[1m[3m[23m[1m[0m [3m^M[23m [3m^M[23m..t/helm-chartsile://negroni/Users/chris.reisor/git/helm-charts[3m^M[23m[0m[23m[24m[01;32mchris.reisor@negroni[00m [01;34mgit/helm-charts[00m [33m(INFRASEC-4257-affinity-and-topology) [00m[00m[1m»[0m [0m[23m[24m[01;32mchris.rei[m [32m[m[32m[1m[3m[23m[1m[0m[0m[23m[24m[01;32m[00m[01;34m[00m[33m[00m[00m[1m[0m[0m[23m[24m[01;32msor@negroni[00m [01;34mgit/helm-charts[00m [33m(INFRASEC-4257-affinity-and-topology) [00m[00m[1m»[0m helm template -f test/fixtures/affinity/values-anti-affinity-disabled.yaml test/fixtures/[m [32m[m[32m[1m[3m[23m[1m[0m[0m[23m[24m[01;32m[00m[01;34m[00m[33m[00m[00m[1m[0m[0m[23m[24m[01;32m[00m[01;34m[00m[33m[00m[00m[1m[0maffinit[m[41m[3m^M[23m[m[m
[32m+[m[32mhelm---[m[41m[3m^M[23m[m[m
[32m+[m[32m# Source: my-cool-app/templates/microservice.yaml.tpl[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32mapiVersion: apps/v1[m[41m[3m^M[23m[m[m
[32m+[m[32mkind: Deployment[m[41m[3m^M[23m[m[m
[32m+[m[32mmetadata:[m[41m[3m^M[23m[m[m
[32m+[m[32m  name: web[m[41m[3m^M[23m[m[m
[32m+[m[32m  annotations:[m[41m[3m^M[23m[m[m
[32m+[m[32m    provi.repository: https://github.com/example/repo[m[41m[3m^M[23m[m[m
[32m+[m[32m    provi.slack: my-cool-team[m[41m[3m^M[23m[m[m
[32m+[m[32m  labels:[m[41m[3m^M[23m[m[m
[32m+[m[32m    app: web[m[41m[3m^M[23m[m[m
[32m+[m[32m    app.kubernetes.io/name: dummy[m[41m[3m^M[23m[m[m
[32m+[m[32m    chart: my-cool-app[m[41m[3m^M[23m[m[m
[32m+[m[32m    chartVersion: 1.0.0[m[41m[3m^M[23m[m[m
[32m+[m[32m    team: cool-team[m[41m[3m^M[23m[m[m
[32m+[m[32mspec:[m[41m[3m^M[23m[m[m
[32m+[m[32m  replicas: 3[m[41m[3m^M[23m[m[m
[32m+[m[32m  selector:[m[41m[3m^M[23m[m[m
[32m+[m[32m    matchLabels:[m[41m[3m^M[23m[m[m
[32m+[m[32m      selector: my-cool-app-deployment-web[m[41m[3m^M[23m[m[m
[32m+[m[32m  template:[m[41m[3m^M[23m[m[m
[32m+[m[32m    metadata:[m[41m[3m^M[23m[m[m
[32m+[m[32m      annotations:[m[41m[3m^M[23m[m[m
[32m+[m[32m        provi.repository: https://github.com/example/repo[m[41m[3m^M[23m[m[m
[32m+[m[32m        provi.slack: my-cool-team[m[41m[3m^M[23m[m[m
[32m+[m[32m      labels:[m[41m[3m^M[23m[m[m
[32m+[m[32m        selector: my-cool-app-deployment-web[m[41m[3m^M[23m[m[m
[32m+[m[32m        app: web[m[41m[3m^M[23m[m[m
[32m+[m[32m        app.kubernetes.io/name: dummy[m[41m[3m^M[23m[m[m
[32m+[m[32m        chart: my-cool-app[m[41m[3m^M[23m[m[m
[32m+[m[32m        chartVersion: 1.0.0[m[41m[3m^M[23m[m[m
[32m+[m[32m        team: cool-team[m[41m[3m^M[23m[m[m
[32m+[m[32m    spec:[m[41m[3m^M[23m[m[m
[32m+[m[32m      topologySpreadConstraints:[m[41m[3m^M[23m[m[m
[32m+[m[32m      - maxSkew: 1[m[41m[3m^M[23m[m[m
[32m+[m[32m        topologyKey: topology.kubernetes.io/zone[m[41m[3m^M[23m[m[m
[32m+[m[32m        whenUnsatisfiable: DoNotSchedule[m[41m[3m^M[23m[m[m
[32m+[m[32m        labelSelector:[m[41m[3m^M[23m[m[m
[32m+[m[32m          matchLabels:[m[41m[3m^M[23m[m[m
[32m+[m[32m            app.kubernetes.io/name: "dummy"[m[41m[3m^M[23m[m[m
[32m+[m[32m      - maxSkew: 1[m[41m[3m^M[23m[m[m
[32m+[m[32m        topologyKey: kubernetes.io/hostname[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m        whenUnsatisfiable: DoNotSchedule[m[41m[3m^M[23m[m[m
[32m+[m[32m        labelSelector:[m[41m[3m^M[23m[m[m
[32m+[m[32m          matchLabels:[m[41m[3m^M[23m[m[m
[32m+[m[32m            app.kubernetes.io/name: "dummy"[m[41m[3m^M[23m[m[m
[32m+[m[32m      automountServiceAccountToken: false[m[41m[3m^M[23m[m[m
[32m+[m[32m      tolerations:[m[41m[3m^M[23m[m[m
[32m+[m[32m        - key: "spot"[m[41m[3m^M[23m[m[m
[32m+[m[32m          operator: "Exists"[m[41m[3m^M[23m[m[m
[32m+[m[32m          effect: "NoSchedule"[m[41m[3m^M[23m[m[m
[32m+[m[32m      restartPolicy: Always[m[41m[3m^M[23m[m[m
[32m+[m[32m      terminationGracePeriodSeconds: 30[m[41m[3m^M[23m[m[m
[32m+[m[32m      containers:[m[41m[3m^M[23m[m[m
[32m+[m[32m        - name: app[m[41m[3m^M[23m[m[m
[32m+[m[32m          image: docker.io/image:abcd1234[m[41m[3m^M[23m[m[m
[32m+[m[32m          imagePullPolicy: Always[m[41m[3m^M[23m[m[m
[32m+[m[32m          securityContext:[m[41m[3m^M[23m[m[m
[32m+[m[32m            runAsNonRoot: false[m[41m[3m^M[23m[m[m
[32m+[m[32m          env:[m[41m[3m^M[23m[m[m
[32m+[m[32m            - name: RACK_ENV[m[41m[3m^M[23m[m[m
[32m+[m[32m              value: "production"[m[41m[3m^M[23m[m[m
[32m+[m[32m            - name: RAILS_ENV[m[41m[3m^M[23m[m[m
[32m+[m[32m              value: "production"[m[41m[3m^M[23m[m[m
[32m+[m[32m          envFrom:[m[41m[3m^M[23m[m[m
[32m+[m[32m            - secretRef:[m[41m[3m^M[23m[m[m
[32m+[m[32m                name: dummy[m[41m[3m^M[23m[m[m
[32m+[m[32m          livenessProbe:[m[41m[3m^M[23m[m[m
[32m+[m[32m            initialDelaySeconds: 0[m[41m[3m^M[23m[m[m
[32m+[m[32m            periodSeconds: 5[m[41m[3m^M[23m[m[m
[32m+[m[32m            timeoutSeconds: 1[m[41m[3m^M[23m[m[m
[32m+[m[32m            failureThreshold: 5[m[41m[3m^M[23m[m[m
[32m+[m[32m            successThreshold: 1[m[41m[3m^M[23m[m[m
[32m+[m[32m            httpGet:[m[41m[3m^M[23m[m[m
[32m+[m[32m              path: /[m[41m[3m^M[23m[m[m
[32m+[m[32m              port: 8080[m[41m[3m^M[23m[m[m
[32m+[m[32m          resources:[m[41m[3m^M[23m[m[m
[32m+[m[32m            limits:[m[41m[3m^M[23m[m[m
[32m+[m[32m              memory: 256Mi[m[41m[3m^M[23m[m[m
[32m+[m[32m              ephemeral-storage: 200Mi[m[41m[3m^M[23m[m[m
[32m+[m[32m            requests:[m[41m[3m^M[23m[m[m
[32m+[m[32m              cpu: 250m[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m              memory: 256Mi[m[41m[3m^M[23m[m[m
[32m+[m[32m              ephemeral-storage: 200Mi[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m[3m%[23m[1m[0m                                                                                                                                                           [m [32m[m[32m[1m[3m[23m[1m[0m [3m^M[23m [3m^M[23m..t/helm-chartsile://negroni/Users/chris.reisor/git/helm-charts[3m^M[23m[0m[23m[24m[01;32mchris.reisor@negroni[00m [01;34mgit/helm-charts[00m [33m(INFRASEC-4257-affinity-and-topology) [00m[00m[1m»[0m helm temp[m [32m[m[32m[1m[3m[23m[1m[0m[0m[23m[24m[01;32m[00m[01;34m[00m[33m[00m[00m[1m[0mlate -f test/fixtures/affinity/values-anti-affinity-disabled.yaml test/fixtures/affinit[m[41m[3m^M[23m[m[m
[32m+[m[32mhelm---[m[41m[3m^M[23m[m[m
[32m+[m[32m# Source: my-cool-app/templates/microservice.yaml.tpl[m[41m[3m^M[23m[m[m
[32m+[m[32mapiVersion: apps/v1[m[41m[3m^M[23m[m[m
[32m+[m[32mkind: Deployment[m[41m[3m^M[23m[m[m
[32m+[m[32mmetadata:[m[41m[3m^M[23m[m[m
[32m+[m[32m  name: web[m[41m[3m^M[23m[m[m
[32m+[m[32m  annotations:[m[41m[3m^M[23m[m[m
[32m+[m[32m    provi.repository: https://github.com/example/repo[m[41m[3m^M[23m[m[m
[32m+[m[32m    provi.slack: my-cool-team[m[41m[3m^M[23m[m[m
[32m+[m[32m  labels:[m[41m[3m^M[23m[m[m
[32m+[m[32m    app: web[m[41m[3m^M[23m[m[m
[32m+[m[32m    app.kubernetes.io/name: dummy[m[41m[3m^M[23m[m[m
[32m+[m[32m    chart: my-cool-app[m[41m[3m^M[23m[m[m
[32m+[m[32m    chartVersion: 1.0.0[m[41m[3m^M[23m[m[m
[32m+[m[32m    team: cool-team[m[41m[3m^M[23m[m[m
[32m+[m[32mspec:[m[41m[3m^M[23m[m[m
[32m+[m[32m  replicas: 3[m[41m[3m^M[23m[m[m
[32m+[m[32m  selector:[m[41m[3m^M[23m[m[m
[32m+[m[32m    matchLabels:[m[41m[3m^M[23m[m[m
[32m+[m[32m      selector: my-cool-app-deployment-web[m[41m[3m^M[23m[m[m
[32m+[m[32m  template:[m[41m[3m^M[23m[m[m
[32m+[m[32m    metadata:[m[41m[3m^M[23m[m[m
[32m+[m[32m      annotations:[m[41m[3m^M[23m[m[m
[32m+[m[32m        provi.repository: https://github.com/example/repo[m[41m[3m^M[23m[m[m
[32m+[m[32m        provi.slack: my-cool-team[m[41m[3m^M[23m[m[m
[32m+[m[32m      labels:[m[41m[3m^M[23m[m[m
[32m+[m[32m        selector: my-cool-app-deployment-web[m[41m[3m^M[23m[m[m
[32m+[m[32m        app: web[m[41m[3m^M[23m[m[m
[32m+[m[32m        app.kubernetes.io/name: dummy[m[41m[3m^M[23m[m[m
[32m+[m[32m        chart: my-cool-app[m[41m[3m^M[23m[m[m
[32m+[m[32m        chartVersion: 1.0.0[m[41m[3m^M[23m[m[m
[32m+[m[32m        team: cool-team[m[41m[3m^M[23m[m[m
[32m+[m[32m    spec:[m[41m[3m^M[23m[m[m
[32m+[m[32m      topologySpreadConstraints:[m[41m[3m^M[23m[m[m
[32m+[m[32m      - maxSkew: 1[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m        topologyKey: topology.kubernetes.io/zone[m[41m[3m^M[23m[m[m
[32m+[m[32m        whenUnsatisfiable: DoNotSchedule[m[41m[3m^M[23m[m[m
[32m+[m[32m        labelSelector:[m[41m[3m^M[23m[m[m
[32m+[m[32m          matchLabels:[m[41m[3m^M[23m[m[m
[32m+[m[32m            app.kubernetes.io/name: "dummy"[m[41m[3m^M[23m[m[m
[32m+[m[32m      - maxSkew: 1[m[41m[3m^M[23m[m[m
[32m+[m[32m        topologyKey: kubernetes.io/hostname[m[41m[3m^M[23m[m[m
[32m+[m[32m        whenUnsatisfiable: DoNotSchedule[m[41m[3m^M[23m[m[m
[32m+[m[32m        labelSelector:[m[41m[3m^M[23m[m[m
[32m+[m[32m          matchLabels:[m[41m[3m^M[23m[m[m
[32m+[m[32m            app.kubernetes.io/name: "dummy"[m[41m[3m^M[23m[m[m
[32m+[m[32m      automountServiceAccountToken: false[m[41m[3m^M[23m[m[m
[32m+[m[32m      tolerations:[m[41m[3m^M[23m[m[m
[32m+[m[32m        - key: "spot"[m[41m[3m^M[23m[m[m
[32m+[m[32m          operator: "Exists"[m[41m[3m^M[23m[m[m
[32m+[m[32m          effect: "NoSchedule"[m[41m[3m^M[23m[m[m
[32m+[m[32m      restartPolicy: Always[m[41m[3m^M[23m[m[m
[32m+[m[32m      terminationGracePeriodSeconds: 30[m[41m[3m^M[23m[m[m
[32m+[m[32m      containers:[m[41m[3m^M[23m[m[m
[32m+[m[32m        - name: app[m[41m[3m^M[23m[m[m
[32m+[m[32m          image: docker.io/image:abcd1234[m[41m[3m^M[23m[m[m
[32m+[m[32m          imagePullPolicy: Always[m[41m[3m^M[23m[m[m
[32m+[m[32m          securityContext:[m[41m[3m^M[23m[m[m
[32m+[m[32m            runAsNonRoot: false[m[41m[3m^M[23m[m[m
[32m+[m[32m          env:[m[41m[3m^M[23m[m[m
[32m+[m[32m            - name: RACK_ENV[m[41m[3m^M[23m[m[m
[32m+[m[32m              value: "production"[m[41m[3m^M[23m[m[m
[32m+[m[32m            - name: RAILS_ENV[m[41m[3m^M[23m[m[m
[32m+[m[32m              value: "production"[m[41m[3m^M[23m[m[m
[32m+[m[32m          envFrom:[m[41m[3m^M[23m[m[m
[32m+[m[32m            - secretRef:[m[41m[3m^M[23m[m[m
[32m+[m[32m                name: dummy[m[41m[3m^M[23m[m[m
[32m+[m[32m          livenessProbe:[m[41m[3m^M[23m[m[m
[32m+[m[32m            initialDelaySeconds: 0[m[41m[3m^M[23m[m[m
[32m+[m[32m            periodSeconds: 5[m[41m[3m^M[23m[m[m
[32m+[m[32m            timeoutSeconds: 1[m[41m[3m^M[23m[m[m
[32m+[m[32m            failureThreshold: 5[m[41m[3m^M[23m[m[m
[32m+[m[32m            successThreshold: 1[m[41m[3m^M[23m[m[m
[32m+[m[32m            httpGet:[m[41m[3m^M[23m[m[m
[32m+[m[32m              path: /[m[41m[3m^M[23m[m[m
:[K[K[32m+[m[32m              port: 8080[m[41m[3m^M[23m[m[m
[32m+[m[32m          resources:[m[41m[3m^M[23m[m[m
[32m+[m[32m            limits:[m[41m[3m^M[23m[m[m
[32m+[m[32m              memory: 256Mi[m[41m[3m^M[23m[m[m
[32m+[m[32m              ephemeral-storage: 200Mi[m[41m[3m^M[23m[m[m
[32m+[m[32m            requests:[m[41m[3m^M[23m[m[m
[32m+[m[32m              cpu: 250m[m[41m[3m^M[23m[m[m
[32m+[m[32m              memory: 256Mi[m[41m[3m^M[23m[m[m
[32m+[m[32m              ephemeral-storage: 200Mi[m[41m[3m^M[23m[m[m
[32m+[m[32m      affinity:[m[41m[3m^M[23m[m[m
[32m+[m[32m        nodeAffinity:[m[41m[3m^M[23m[m[m
[32m+[m[32m          requiredDuringSchedulingIgnoredDuringExecution:[m[41m[3m^M[23m[m[m
[32m+[m[32m            nodeSelectorTerms:[m[41m[3m^M[23m[m[m
[32m+[m[32m            - matchExpressions:[m[41m[3m^M[23m[m[m
[32m+[m[32m              - key: karpenter.sh/controller[m[41m[3m^M[23m[m[m
[32m+[m[32m                operator: NotIn[m[41m[3m^M[23m[m[m
[32m+[m[32m                values:[m[41m[3m^M[23m[m[m
[32m+[m[32m                - "true"[m[41m[3m^M[23m[m[m
[32m+[m[32m[1m[3m%[23m[1m[0m                                                                                                                                                           [m [32m[m[32m[1m[3m[23m[1m[0m [3m^M[23m [3m^M[23m..t/helm-chartsile://negroni/Users/chris.reisor/git/helm-charts[3m^M[23m[0m[23m[24m[01;32mchris.reisor@negroni[00m [01;34mgit/helm-charts[00m [33m(INFRASEC-4257-affinity-and-topology) [00m[00m[1m»[0m [3m^G[23m[m[m
\ No newline at end of file[m[m
[1mdiff --git a/test/expected_output/affinity.yaml b/test/expected_output/affinity.yaml[m[m
[1mindex 9d45871..b46075b 100644[m[m
[1m--- a/test/expected_output/affinity.yaml[m[m
[1m+++ b/test/expected_output/affinity.yaml[m[m
[36m@@ -95,12 +95,8 @@[m [mspec:[m[m
                 operator: In[m[m
                 values:[m[m
                 - testaffinity[m[m
[31m-        podAntiAffinity:[m[m
[31m-          requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-          - labelSelector:[m[m
[31m-              matchExpressions:[m[m
[32m+[m[32m            - matchExpressions:[m[m
               - key: karpenter.sh/controller[m[m
[31m-                operator: In[m[m
[32m+[m[32m                operator: NotIn[m[m
                 values:[m[m
                 - "true"[m[m
[31m-            topologyKey: kubernetes.io/hostname[m[m
:[K[K[1mdiff --git a/test/expected_output/autoscaler.yaml b/test/expected_output/autoscaler.yaml[m[m
[1mindex 9777b6b..caab7a4 100644[m[m
[1m--- a/test/expected_output/autoscaler.yaml[m[m
[1m+++ b/test/expected_output/autoscaler.yaml[m[m
[36m@@ -82,15 +82,14 @@[m [mspec:[m[m
               memory: 256Mi[m[m
               ephemeral-storage: 200Mi[m[m
       affinity:[m[m
[31m-        podAntiAffinity:[m[m
[32m+[m[32m        nodeAffinity:[m[m
           requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-          - labelSelector:[m[m
[31m-              matchExpressions:[m[m
[32m+[m[32m            nodeSelectorTerms:[m[m
[32m+[m[32m            - matchExpressions:[m[m
               - key: karpenter.sh/controller[m[m
[31m-                operator: In[m[m
[32m+[m[32m                operator: NotIn[m[m
                 values:[m[m
                 - "true"[m[m
[31m-            topologyKey: kubernetes.io/hostname[m[m
 ---[m[m
 # Source: my-cool-app/templates/microservice.yaml.tpl[m[m
 apiVersion: autoscaling/v2[m[m
[1mdiff --git a/test/expected_output/containers-basic.yaml b/test/expected_output/containers-basic.yaml[m[m
[1mindex 54a668f..09510e2 100644[m[m
[1m--- a/test/expected_output/containers-basic.yaml[m[m
[1m+++ b/test/expected_output/containers-basic.yaml[m[m
[36m@@ -121,12 +121,8 @@[m [mspec:[m[m
                 operator: In[m[m
                 values:[m[m
                 - karpenter[m[m
[31m-        podAntiAffinity:[m[m
[31m-          requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-          - labelSelector:[m[m
[31m-              matchExpressions:[m[m
[32m+[m[32m            - matchExpressions:[m[m
               - key: karpenter.sh/controller[m[m
[31m-                operator: In[m[m
[32m+[m[32m                operator: NotIn[m[m
:[K[K                 values:[m[m
                 - "true"[m[m
[31m-            topologyKey: kubernetes.io/hostname[m[m
[1mdiff --git a/test/expected_output/cronjobs-global-serviceaccount.yaml b/test/expected_output/cronjobs-global-serviceaccount.yaml[m[m
[1mindex fef5b8b..4410545 100644[m[m
[1m--- a/test/expected_output/cronjobs-global-serviceaccount.yaml[m[m
[1m+++ b/test/expected_output/cronjobs-global-serviceaccount.yaml[m[m
[36m@@ -69,12 +69,11 @@[m [mspec:[m[m
                   cpu: 100m[m[m
                   memory: 256Mi[m[m
           affinity:[m[m
[31m-            podAntiAffinity:[m[m
[32m+[m[32m            nodeAffinity:[m[m
               requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-              - labelSelector:[m[m
[31m-                  matchExpressions:[m[m
[32m+[m[32m                nodeSelectorTerms:[m[m
[32m+[m[32m                - matchExpressions:[m[m
                   - key: karpenter.sh/controller[m[m
[31m-                    operator: In[m[m
[32m+[m[32m                    operator: NotIn[m[m
                     values:[m[m
                     - "true"[m[m
[31m-                topologyKey: kubernetes.io/hostname[m[m
[1mdiff --git a/test/expected_output/cronjobs-serviceaccount.yaml b/test/expected_output/cronjobs-serviceaccount.yaml[m[m
[1mindex 0d4c84a..c970af0 100644[m[m
[1m--- a/test/expected_output/cronjobs-serviceaccount.yaml[m[m
[1m+++ b/test/expected_output/cronjobs-serviceaccount.yaml[m[m
[36m@@ -73,12 +73,11 @@[m [mspec:[m[m
                   cpu: 100m[m[m
                   memory: 256Mi[m[m
           affinity:[m[m
[31m-            podAntiAffinity:[m[m
[32m+[m[32m            nodeAffinity:[m[m
               requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-              - labelSelector:[m[m
[31m-                  matchExpressions:[m[m
[32m+[m[32m                nodeSelectorTerms:[m[m
[32m+[m[32m                - matchExpressions:[m[m
                   - key: karpenter.sh/controller[m[m
:[K[K[31m-                    operator: In[m[m
[32m+[m[32m                    operator: NotIn[m[m
                     values:[m[m
                     - "true"[m[m
[31m-                topologyKey: kubernetes.io/hostname[m[m
[1mdiff --git a/test/expected_output/cronjobs.yaml b/test/expected_output/cronjobs.yaml[m[m
[1mindex bd18369..03d5ebe 100644[m[m
[1m--- a/test/expected_output/cronjobs.yaml[m[m
[1m+++ b/test/expected_output/cronjobs.yaml[m[m
[36m@@ -61,12 +61,11 @@[m [mspec:[m[m
                   cpu: 100m[m[m
                   memory: 256Mi[m[m
           affinity:[m[m
[31m-            podAntiAffinity:[m[m
[32m+[m[32m            nodeAffinity:[m[m
               requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-              - labelSelector:[m[m
[31m-                  matchExpressions:[m[m
[32m+[m[32m                nodeSelectorTerms:[m[m
[32m+[m[32m                - matchExpressions:[m[m
                   - key: karpenter.sh/controller[m[m
[31m-                    operator: In[m[m
[32m+[m[32m                    operator: NotIn[m[m
                     values:[m[m
                     - "true"[m[m
[31m-                topologyKey: kubernetes.io/hostname[m[m
[1mdiff --git a/test/expected_output/deployments-selector.yaml b/test/expected_output/deployments-selector.yaml[m[m
[1mindex 4fc50b8..becd9cc 100644[m[m
[1m--- a/test/expected_output/deployments-selector.yaml[m[m
[1m+++ b/test/expected_output/deployments-selector.yaml[m[m
[36m@@ -121,15 +121,11 @@[m [mspec:[m[m
                 operator: In[m[m
                 values:[m[m
                 - karpenter[m[m
[31m-        podAntiAffinity:[m[m
[31m-          requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-          - labelSelector:[m[m
[31m-              matchExpressions:[m[m
[32m+[m[32m            - matchExpressions:[m[m
               - key: karpenter.sh/controller[m[m
:[K[K[31m-                operator: In[m[m
[32m+[m[32m                operator: NotIn[m[m
                 values:[m[m
                 - "true"[m[m
[31m-            topologyKey: kubernetes.io/hostname[m[m
 ---[m[m
 # Source: my-cool-app/templates/microservice.yaml.tpl[m[m
 apiVersion: autoscaling/v2[m[m
[1mdiff --git a/test/expected_output/deployments.yaml b/test/expected_output/deployments.yaml[m[m
[1mindex 46d1e76..b6fc98a 100644[m[m
[1m--- a/test/expected_output/deployments.yaml[m[m
[1m+++ b/test/expected_output/deployments.yaml[m[m
[36m@@ -127,15 +127,11 @@[m [mspec:[m[m
                 operator: In[m[m
                 values:[m[m
                 - karpenter[m[m
[31m-        podAntiAffinity:[m[m
[31m-          requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-          - labelSelector:[m[m
[31m-              matchExpressions:[m[m
[32m+[m[32m            - matchExpressions:[m[m
               - key: karpenter.sh/controller[m[m
[31m-                operator: In[m[m
[32m+[m[32m                operator: NotIn[m[m
                 values:[m[m
                 - "true"[m[m
[31m-            topologyKey: kubernetes.io/hostname[m[m
 ---[m[m
 # Source: my-cool-app/templates/microservice.yaml.tpl[m[m
 apiVersion: autoscaling/v2[m[m
[1mdiff --git a/test/expected_output/jobs.yaml b/test/expected_output/jobs.yaml[m[m
[1mindex d50a43b..e3748b3 100644[m[m
[1m--- a/test/expected_output/jobs.yaml[m[m
[1m+++ b/test/expected_output/jobs.yaml[m[m
[36m@@ -54,12 +54,11 @@[m [mspec:[m[m
               cpu: 100m[m[m
               memory: 256Mi[m[m
       affinity:[m[m
[31m-        podAntiAffinity:[m[m
[32m+[m[32m        nodeAffinity:[m[m
:[K[K           requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-          - labelSelector:[m[m
[31m-              matchExpressions:[m[m
[32m+[m[32m            nodeSelectorTerms:[m[m
[32m+[m[32m            - matchExpressions:[m[m
               - key: karpenter.sh/controller[m[m
[31m-                operator: In[m[m
[32m+[m[32m                operator: NotIn[m[m
                 values:[m[m
                 - "true"[m[m
[31m-            topologyKey: kubernetes.io/hostname[m[m
[1mdiff --git a/test/expected_output/microservice.yaml b/test/expected_output/microservice.yaml[m[m
[1mindex e769301..4fb3136 100644[m[m
[1m--- a/test/expected_output/microservice.yaml[m[m
[1m+++ b/test/expected_output/microservice.yaml[m[m
[36m@@ -177,15 +177,11 @@[m [mspec:[m[m
                 operator: In[m[m
                 values:[m[m
                 - karpenter[m[m
[31m-        podAntiAffinity:[m[m
[31m-          requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-          - labelSelector:[m[m
[31m-              matchExpressions:[m[m
[32m+[m[32m            - matchExpressions:[m[m
               - key: karpenter.sh/controller[m[m
[31m-                operator: In[m[m
[32m+[m[32m                operator: NotIn[m[m
                 values:[m[m
                 - "true"[m[m
[31m-            topologyKey: kubernetes.io/hostname[m[m
 ---[m[m
 # Source: my-cool-app/templates/microservice.yaml.tpl[m[m
 apiVersion: autoscaling/v2[m[m
[36m@@ -286,15 +282,14 @@[m [mspec:[m[m
             - mountPath: /data[m[m
               name: data[m[m
       affinity:[m[m
[31m-        podAntiAffinity:[m[m
[32m+[m[32m        nodeAffinity:[m[m
           requiredDuringSchedulingIgnoredDuringExecution:[m[m
:[K[K[31m-          - labelSelector:[m[m
[31m-              matchExpressions:[m[m
[32m+[m[32m            nodeSelectorTerms:[m[m
[32m+[m[32m            - matchExpressions:[m[m
               - key: karpenter.sh/controller[m[m
[31m-                operator: In[m[m
[32m+[m[32m                operator: NotIn[m[m
                 values:[m[m
                 - "true"[m[m
[31m-            topologyKey: kubernetes.io/hostname[m[m
   volumeClaimTemplates:[m[m
     - metadata:[m[m
         name: data[m[m
[36m@@ -371,15 +366,14 @@[m [mspec:[m[m
                   cpu: 100m[m[m
                   memory: 256Mi[m[m
           affinity:[m[m
[31m-            podAntiAffinity:[m[m
[32m+[m[32m            nodeAffinity:[m[m
               requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-              - labelSelector:[m[m
[31m-                  matchExpressions:[m[m
[32m+[m[32m                nodeSelectorTerms:[m[m
[32m+[m[32m                - matchExpressions:[m[m
                   - key: karpenter.sh/controller[m[m
[31m-                    operator: In[m[m
[32m+[m[32m                    operator: NotIn[m[m
                     values:[m[m
                     - "true"[m[m
[31m-                topologyKey: kubernetes.io/hostname[m[m
 ---[m[m
 # Source: my-cool-app/templates/microservice.yaml.tpl[m[m
 apiVersion: networking.k8s.io/v1[m[m
[36m@@ -487,12 +481,11 @@[m [mspec:[m[m
               cpu: 100m[m[m
               memory: 256Mi[m[m
       affinity:[m[m
[31m-        podAntiAffinity:[m[m
[32m+[m[32m        nodeAffinity:[m[m
           requiredDuringSchedulingIgnoredDuringExecution:[m[m
:[K[K[31m-          - labelSelector:[m[m
[31m-              matchExpressions:[m[m
[32m+[m[32m            nodeSelectorTerms:[m[m
[32m+[m[32m            - matchExpressions:[m[m
               - key: karpenter.sh/controller[m[m
[31m-                operator: In[m[m
[32m+[m[32m                operator: NotIn[m[m
                 values:[m[m
                 - "true"[m[m
[31m-            topologyKey: kubernetes.io/hostname[m[m
[1mdiff --git a/test/expected_output/podspec-basic.yaml b/test/expected_output/podspec-basic.yaml[m[m
[1mindex f851914..ca6b55c 100644[m[m
[1m--- a/test/expected_output/podspec-basic.yaml[m[m
[1m+++ b/test/expected_output/podspec-basic.yaml[m[m
[36m@@ -127,15 +127,11 @@[m [mspec:[m[m
                 operator: In[m[m
                 values:[m[m
                 - karpenter[m[m
[31m-        podAntiAffinity:[m[m
[31m-          requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-          - labelSelector:[m[m
[31m-              matchExpressions:[m[m
[32m+[m[32m            - matchExpressions:[m[m
               - key: karpenter.sh/controller[m[m
[31m-                operator: In[m[m
[32m+[m[32m                operator: NotIn[m[m
                 values:[m[m
                 - "true"[m[m
[31m-            topologyKey: kubernetes.io/hostname[m[m
 ---[m[m
 # Source: my-cool-app/templates/microservice.yaml.tpl[m[m
 apiVersion: autoscaling/v2[m[m
[1mdiff --git a/test/expected_output/podspec_output.yaml b/test/expected_output/podspec_output.yaml[m[m
[1mindex f851914..ca6b55c 100644[m[m
[1m--- a/test/expected_output/podspec_output.yaml[m[m
[1m+++ b/test/expected_output/podspec_output.yaml[m[m
[36m@@ -127,15 +127,11 @@[m [mspec:[m[m
                 operator: In[m[m
                 values:[m[m
                 - karpenter[m[m
:[K[K[31m-        podAntiAffinity:[m[m
[31m-          requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-          - labelSelector:[m[m
[31m-              matchExpressions:[m[m
[32m+[m[32m            - matchExpressions:[m[m
               - key: karpenter.sh/controller[m[m
[31m-                operator: In[m[m
[32m+[m[32m                operator: NotIn[m[m
                 values:[m[m
                 - "true"[m[m
[31m-            topologyKey: kubernetes.io/hostname[m[m
 ---[m[m
 # Source: my-cool-app/templates/microservice.yaml.tpl[m[m
 apiVersion: autoscaling/v2[m[m
[1mdiff --git a/test/expected_output/statefulsets.yaml b/test/expected_output/statefulsets.yaml[m[m
[1mindex 29f250c..add1569 100644[m[m
[1m--- a/test/expected_output/statefulsets.yaml[m[m
[1m+++ b/test/expected_output/statefulsets.yaml[m[m
[36m@@ -106,15 +106,14 @@[m [mspec:[m[m
             - mountPath: /data[m[m
               name: data[m[m
       affinity:[m[m
[31m-        podAntiAffinity:[m[m
[32m+[m[32m        nodeAffinity:[m[m
           requiredDuringSchedulingIgnoredDuringExecution:[m[m
[31m-          - labelSelector:[m[m
[31m-              matchExpressions:[m[m
[32m+[m[32m            nodeSelectorTerms:[m[m
[32m+[m[32m            - matchExpressions:[m[m
               - key: karpenter.sh/controller[m[m
[31m-                operator: In[m[m
[32m+[m[32m                operator: NotIn[m[m
                 values:[m[m
                 - "true"[m[m
[31m-            topologyKey: kubernetes.io/hostname[m[m
   volumeClaimTemplates:[m[m
     - metadata:[m[m
         name: data[m[m
[1mdiff --git a/test/fixtures/affinity/Chart.lock b/test/fixtures/affinity/Chart.lock[m[m
[1mindex 11c073e..150a626 100644[m[m
:[K[K[1m--- a/test/fixtures/affinity/Chart.lock[m[m
[1m+++ b/test/fixtures/affinity/Chart.lock[m[m
[36m@@ -1,6 +1,6 @@[m[m
 dependencies:[m[m
 - name: common[m[m
   repository: file://../../../charts/common[m[m
[31m-  version: 1.9.0[m[m
[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[31m-generated: "2025-12-17T15:09:26.365997-06:00"[m[m
[32m+[m[32m  version: 1.10.0[m[m
[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[32m+[m[32mgenerated: "2025-12-18T15:48:26.804161-06:00"[m[m
[1mdiff --git a/test/fixtures/affinity/Chart.yaml b/test/fixtures/affinity/Chart.yaml[m[m
[1mindex a340089..3930d4f 100644[m[m
[1m--- a/test/fixtures/affinity/Chart.yaml[m[m
[1m+++ b/test/fixtures/affinity/Chart.yaml[m[m
[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
 dependencies:[m[m
   - name: common[m[m
     repository: file://../../../charts/common[m[m
[31m-    version: "1.9.0"[m[m
[32m+[m[32m    version: "1.10.0"[m[m
[1mdiff --git a/test/fixtures/autoscaler/Chart.lock b/test/fixtures/autoscaler/Chart.lock[m[m
[1mindex 419ecd6..d0076a4 100644[m[m
[1m--- a/test/fixtures/autoscaler/Chart.lock[m[m
[1m+++ b/test/fixtures/autoscaler/Chart.lock[m[m
[36m@@ -1,6 +1,6 @@[m[m
 dependencies:[m[m
 - name: common[m[m
   repository: file://../../../charts/common[m[m
[31m-  version: 1.9.0[m[m
[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[31m-generated: "2025-12-17T15:09:27.105674-06:00"[m[m
[32m+[m[32m  version: 1.10.0[m[m
[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[32m+[m[32mgenerated: "2025-12-18T15:48:27.507813-06:00"[m[m
[1mdiff --git a/test/fixtures/autoscaler/Chart.yaml b/test/fixtures/autoscaler/Chart.yaml[m[m
[1mindex a340089..3930d4f 100644[m[m
[1m--- a/test/fixtures/autoscaler/Chart.yaml[m[m
[1m+++ b/test/fixtures/autoscaler/Chart.yaml[m[m
:[K[K[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
 dependencies:[m[m
   - name: common[m[m
     repository: file://../../../charts/common[m[m
[31m-    version: "1.9.0"[m[m
[32m+[m[32m    version: "1.10.0"[m[m
[1mdiff --git a/test/fixtures/clusterexternalsecret/Chart.lock b/test/fixtures/clusterexternalsecret/Chart.lock[m[m
[1mindex 4bc1611..f59001e 100644[m[m
[1m--- a/test/fixtures/clusterexternalsecret/Chart.lock[m[m
[1m+++ b/test/fixtures/clusterexternalsecret/Chart.lock[m[m
[36m@@ -1,6 +1,6 @@[m[m
 dependencies:[m[m
 - name: common[m[m
   repository: file://../../../charts/common[m[m
[31m-  version: 1.9.0[m[m
[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[31m-generated: "2025-12-17T15:09:29.144067-06:00"[m[m
[32m+[m[32m  version: 1.10.0[m[m
[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[32m+[m[32mgenerated: "2025-12-18T15:48:29.001689-06:00"[m[m
[1mdiff --git a/test/fixtures/clusterexternalsecret/Chart.yaml b/test/fixtures/clusterexternalsecret/Chart.yaml[m[m
[1mindex a340089..3930d4f 100644[m[m
[1m--- a/test/fixtures/clusterexternalsecret/Chart.yaml[m[m
[1m+++ b/test/fixtures/clusterexternalsecret/Chart.yaml[m[m
[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
 dependencies:[m[m
   - name: common[m[m
     repository: file://../../../charts/common[m[m
[31m-    version: "1.9.0"[m[m
[32m+[m[32m    version: "1.10.0"[m[m
[1mdiff --git a/test/fixtures/configmaps/Chart.lock b/test/fixtures/configmaps/Chart.lock[m[m
[1mindex 383ed3b..089e894 100644[m[m
[1m--- a/test/fixtures/configmaps/Chart.lock[m[m
[1m+++ b/test/fixtures/configmaps/Chart.lock[m[m
[36m@@ -1,6 +1,6 @@[m[m
 dependencies:[m[m
 - name: common[m[m
   repository: file://../../../charts/common[m[m
[31m-  version: 1.9.0[m[m
[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
:[K[K[31m-generated: "2025-12-17T15:09:30.263648-06:00"[m[m
[32m+[m[32m  version: 1.10.0[m[m
[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[32m+[m[32mgenerated: "2025-12-18T15:48:29.692511-06:00"[m[m
[1mdiff --git a/test/fixtures/configmaps/Chart.yaml b/test/fixtures/configmaps/Chart.yaml[m[m
[1mindex a340089..3930d4f 100644[m[m
[1m--- a/test/fixtures/configmaps/Chart.yaml[m[m
[1m+++ b/test/fixtures/configmaps/Chart.yaml[m[m
[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
 dependencies:[m[m
   - name: common[m[m
     repository: file://../../../charts/common[m[m
[31m-    version: "1.9.0"[m[m
[32m+[m[32m    version: "1.10.0"[m[m
[1mdiff --git a/test/fixtures/containers/Chart.lock b/test/fixtures/containers/Chart.lock[m[m
[1mindex fc0b43f..e385b7c 100644[m[m
[1m--- a/test/fixtures/containers/Chart.lock[m[m
[1m+++ b/test/fixtures/containers/Chart.lock[m[m
[36m@@ -1,6 +1,6 @@[m[m
 dependencies:[m[m
 - name: common[m[m
   repository: file://../../../charts/common[m[m
[31m-  version: 1.9.0[m[m
[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[31m-generated: "2025-12-17T15:09:31.391356-06:00"[m[m
[32m+[m[32m  version: 1.10.0[m[m
[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[32m+[m[32mgenerated: "2025-12-18T15:48:30.41571-06:00"[m[m
[1mdiff --git a/test/fixtures/containers/Chart.yaml b/test/fixtures/containers/Chart.yaml[m[m
[1mindex a340089..3930d4f 100644[m[m
[1m--- a/test/fixtures/containers/Chart.yaml[m[m
[1m+++ b/test/fixtures/containers/Chart.yaml[m[m
[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
 dependencies:[m[m
   - name: common[m[m
     repository: file://../../../charts/common[m[m
[31m-    version: "1.9.0"[m[m
[32m+[m[32m    version: "1.10.0"[m[m
[1mdiff --git a/test/fixtures/cronjobs/Chart.lock b/test/fixtures/cronjobs/Chart.lock[m[m
[1mindex 081fe8b..12fdb2a 100644[m[m
:[K[K[1m--- a/test/fixtures/cronjobs/Chart.lock[m[m
[1m+++ b/test/fixtures/cronjobs/Chart.lock[m[m
[36m@@ -1,6 +1,6 @@[m[m
 dependencies:[m[m
 - name: common[m[m
   repository: file://../../../charts/common[m[m
[31m-  version: 1.9.0[m[m
[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[31m-generated: "2025-12-17T15:09:32.450577-06:00"[m[m
[32m+[m[32m  version: 1.10.0[m[m
[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[32m+[m[32mgenerated: "2025-12-18T15:48:31.352985-06:00"[m[m
[1mdiff --git a/test/fixtures/cronjobs/Chart.yaml b/test/fixtures/cronjobs/Chart.yaml[m[m
[1mindex a340089..3930d4f 100644[m[m
[1m--- a/test/fixtures/cronjobs/Chart.yaml[m[m
[1m+++ b/test/fixtures/cronjobs/Chart.yaml[m[m
[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
 dependencies:[m[m
   - name: common[m[m
     repository: file://../../../charts/common[m[m
[31m-    version: "1.9.0"[m[m
[32m+[m[32m    version: "1.10.0"[m[m
[1mdiff --git a/test/fixtures/deployments/Chart.lock b/test/fixtures/deployments/Chart.lock[m[m
[1mindex 7ff4ddb..bc38e20 100644[m[m
[1m--- a/test/fixtures/deployments/Chart.lock[m[m
[1m+++ b/test/fixtures/deployments/Chart.lock[m[m
[36m@@ -1,6 +1,6 @@[m[m
 dependencies:[m[m
 - name: common[m[m
   repository: file://../../../charts/common[m[m
[31m-  version: 1.9.0[m[m
[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[31m-generated: "2025-12-17T15:09:38.012485-06:00"[m[m
[32m+[m[32m  version: 1.10.0[m[m
[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[32m+[m[32mgenerated: "2025-12-18T15:48:32.086635-06:00"[m[m
[1mdiff --git a/test/fixtures/deployments/Chart.yaml b/test/fixtures/deployments/Chart.yaml[m[m
[1mindex a340089..3930d4f 100644[m[m
[1m--- a/test/fixtures/deployments/Chart.yaml[m[m
[1m+++ b/test/fixtures/deployments/Chart.yaml[m[m
:[K[K[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
 dependencies:[m[m
   - name: common[m[m
     repository: file://../../../charts/common[m[m
[31m-    version: "1.9.0"[m[m
[32m+[m[32m    version: "1.10.0"[m[m
[1mdiff --git a/test/fixtures/ingresses/Chart.lock b/test/fixtures/ingresses/Chart.lock[m[m
[1mindex 667c567..c657dbe 100644[m[m
[1m--- a/test/fixtures/ingresses/Chart.lock[m[m
[1m+++ b/test/fixtures/ingresses/Chart.lock[m[m
[36m@@ -1,6 +1,6 @@[m[m
 dependencies:[m[m
 - name: common[m[m
   repository: file://../../../charts/common[m[m
[31m-  version: 1.9.0[m[m
[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[31m-generated: "2025-12-17T15:09:39.098876-06:00"[m[m
[32m+[m[32m  version: 1.10.0[m[m
[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[32m+[m[32mgenerated: "2025-12-18T15:48:32.804286-06:00"[m[m
[1mdiff --git a/test/fixtures/ingresses/Chart.yaml b/test/fixtures/ingresses/Chart.yaml[m[m
[1mindex a340089..3930d4f 100644[m[m
[1m--- a/test/fixtures/ingresses/Chart.yaml[m[m
[1m+++ b/test/fixtures/ingresses/Chart.yaml[m[m
[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
 dependencies:[m[m
   - name: common[m[m
     repository: file://../../../charts/common[m[m
[31m-    version: "1.9.0"[m[m
[32m+[m[32m    version: "1.10.0"[m[m
[1mdiff --git a/test/fixtures/jobs/Chart.lock b/test/fixtures/jobs/Chart.lock[m[m
[1mindex 56db834..421b54a 100644[m[m
[1m--- a/test/fixtures/jobs/Chart.lock[m[m
[1m+++ b/test/fixtures/jobs/Chart.lock[m[m
[36m@@ -1,6 +1,6 @@[m[m
 dependencies:[m[m
 - name: common[m[m
   repository: file://../../../charts/common[m[m
[31m-  version: 1.9.0[m[m
[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
:[K[K[31m-generated: "2025-12-17T15:09:40.153238-06:00"[m[m
[32m+[m[32m  version: 1.10.0[m[m
[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[32m+[m[32mgenerated: "2025-12-18T15:48:33.78433-06:00"[m[m
[1mdiff --git a/test/fixtures/jobs/Chart.yaml b/test/fixtures/jobs/Chart.yaml[m[m
[1mindex a340089..3930d4f 100644[m[m
[1m--- a/test/fixtures/jobs/Chart.yaml[m[m
[1m+++ b/test/fixtures/jobs/Chart.yaml[m[m
[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
 dependencies:[m[m
   - name: common[m[m
     repository: file://../../../charts/common[m[m
[31m-    version: "1.9.0"[m[m
[32m+[m[32m    version: "1.10.0"[m[m
[1mdiff --git a/test/fixtures/microservice/Chart.lock b/test/fixtures/microservice/Chart.lock[m[m
[1mindex 175e535..5e09d6a 100644[m[m
[1m--- a/test/fixtures/microservice/Chart.lock[m[m
[1m+++ b/test/fixtures/microservice/Chart.lock[m[m
[36m@@ -1,6 +1,6 @@[m[m
 dependencies:[m[m
 - name: common[m[m
   repository: file://../../../charts/common[m[m
[31m-  version: 1.9.0[m[m
[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[31m-generated: "2025-12-17T15:09:41.172052-06:00"[m[m
[32m+[m[32m  version: 1.10.0[m[m
[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[32m+[m[32mgenerated: "2025-12-18T15:48:34.458044-06:00"[m[m
[1mdiff --git a/test/fixtures/microservice/Chart.yaml b/test/fixtures/microservice/Chart.yaml[m[m
[1mindex a340089..3930d4f 100644[m[m
[1m--- a/test/fixtures/microservice/Chart.yaml[m[m
[1m+++ b/test/fixtures/microservice/Chart.yaml[m[m
[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
 dependencies:[m[m
   - name: common[m[m
     repository: file://../../../charts/common[m[m
[31m-    version: "1.9.0"[m[m
[32m+[m[32m    version: "1.10.0"[m[m
[1mdiff --git a/test/fixtures/podspec/Chart.lock b/test/fixtures/podspec/Chart.lock[m[m
[1mindex 81d141e..fe1822a 100644[m[m
:[K[K[1m--- a/test/fixtures/podspec/Chart.lock[m[m
[1m+++ b/test/fixtures/podspec/Chart.lock[m[m
[36m@@ -1,6 +1,6 @@[m[m
 dependencies:[m[m
 - name: common[m[m
   repository: file://../../../charts/common[m[m
[31m-  version: 1.9.0[m[m
[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[31m-generated: "2025-12-17T15:09:42.257485-06:00"[m[m
[32m+[m[32m  version: 1.10.0[m[m
[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[32m+[m[32mgenerated: "2025-12-18T15:48:35.155465-06:00"[m[m
[1mdiff --git a/test/fixtures/podspec/Chart.yaml b/test/fixtures/podspec/Chart.yaml[m[m
[1mindex a340089..3930d4f 100644[m[m
[1m--- a/test/fixtures/podspec/Chart.yaml[m[m
[1m+++ b/test/fixtures/podspec/Chart.yaml[m[m
[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
 dependencies:[m[m
   - name: common[m[m
     repository: file://../../../charts/common[m[m
[31m-    version: "1.9.0"[m[m
[32m+[m[32m    version: "1.10.0"[m[m
[1mdiff --git a/test/fixtures/statefulsets/Chart.lock b/test/fixtures/statefulsets/Chart.lock[m[m
[1mindex 972d85f..e0ee5a1 100644[m[m
[1m--- a/test/fixtures/statefulsets/Chart.lock[m[m
[1m+++ b/test/fixtures/statefulsets/Chart.lock[m[m
[36m@@ -1,6 +1,6 @@[m[m
 dependencies:[m[m
 - name: common[m[m
   repository: file://../../../charts/common[m[m
[31m-  version: 1.9.0[m[m
[31m-digest: sha256:74278d15611c70195c1a255ab006528cd5c30713379dadcaf9cc27a2d7a0b2e0[m[m
[31m-generated: "2025-12-17T15:09:43.332944-06:00"[m[m
[32m+[m[32m  version: 1.10.0[m[m
[32m+[m[32mdigest: sha256:e9e4798e002a9cffd33fdedbf4fea98b02de5627832f1ad08778045da446307c[m[m
[32m+[m[32mgenerated: "2025-12-18T15:48:35.830031-06:00"[m[m
[1mdiff --git a/test/fixtures/statefulsets/Chart.yaml b/test/fixtures/statefulsets/Chart.yaml[m[m
[1mindex a340089..3930d4f 100644[m[m
[1m--- a/test/fixtures/statefulsets/Chart.yaml[m[m
[1m+++ b/test/fixtures/statefulsets/Chart.yaml[m[m
:[K[K[36m@@ -6,4 +6,4 @@[m [mversion: 1.0.0[m[m
 dependencies:[m[m
   - name: common[m[m
     repository: file://../../../charts/common[m[m
[31m-    version: "1.9.0"[m[m
[32m+[m[32m    version: "1.10.0"[m[m
[1mdiff --git a/test/test_cronjobs.bats b/test/test_cronjobs.bats[m[m
[1mindex ba9641f..718d4a0 100644[m[m
[1m--- a/test/test_cronjobs.bats[m[m
[1m+++ b/test/test_cronjobs.bats[m[m
[36m@@ -19,7 +19,7 @@[m [mteardown() {[m[m
        assert_output --partial 'test.override.annotation: hello-override-world'[m[m
   assert_output --partial 'testOverrideLabel: hello-override-world'[m[m
   assert_output --partial 'name: test-cronjobs'[m[m
[31m-  assert_output --partial 'podAntiAffinity'[m[m
[32m+[m[32m  assert_output --partial 'nodeAffinity'[m[m
   assert_output --partial 'schedule: "0 * * * *"'[m[m
 }[m[m
 [m[m
[1mdiff --git a/test/test_jobs.bats b/test/test_jobs.bats[m[m
[1mindex 66a463b..b2b3dce 100644[m[m
[1m--- a/test/test_jobs.bats[m[m
[1m+++ b/test/test_jobs.bats[m[m
[36m@@ -16,7 +16,7 @@[m [mteardown() {[m[m
   run helm template -f test/fixtures/jobs/values-basic.yaml test/fixtures/jobs/[m[m
   assert_output --partial 'kind: Job'[m[m
   assert_output --partial 'helm.sh/hook: pre-install,pre-upgrade'[m[m
[31m-  assert_output --partial 'podAntiAffinity'[m[m
[32m+[m[32m  assert_output --partial 'nodeAffinity'[m[m
 }[m[m
 [m[m
 # bats test_tags=tag:basic[m[m
[1mdiff --git a/test/test_pod_affinity.bats b/test/test_pod_affinity.bats[m[m
[1mindex 2d3e846..4b9e0b3 100644[m[m
[1m--- a/test/test_pod_affinity.bats[m[m
[1m+++ b/test/test_pod_affinity.bats[m[m
[36m@@ -36,5 +36,5 @@[m [mteardown() {[m[m
 # bats test_tags=tag:affinity-disabled[m[m
 @test "affinity: allows disabling automatic anti-affinity" {[m[m
   run helm template -f test/fixtures/affinity/values-anti-affinity-disabled.yaml test/fixtures/affinity/[m[m
:[K[K[31m-  refute_output --partial 'podAntiAffinity'[m[m
[32m+[m[32m  refute_output --partial 'karpenter.sh/controller'[m[m
 }[m[m
[3m(END)[23m[K[K[K[3m(END)[23m[K[K[K[3m(END)[23m[K[K[K[3m(END)[23m[K[K[K[3m(END)[23m[K[K[?1l>[1m[3m%[23m[1m[0m                                                                                                                                                             k..t/helm-charts\]7;file://negroni/Users/chris.reisor/git/helm-charts\[0m[23m[24m[J[01;32mchris.reisor@negroni[00m [01;34mgit/helm-charts[00m [33m(INFRASEC-4257-affinity-and-topology) [00m[00m[1m»[0m [K[?1h=[6 q[?2004h