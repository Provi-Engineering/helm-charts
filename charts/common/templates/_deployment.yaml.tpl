{{- define "common.kubernetes.deployment" -}}
{{- $chart := deepCopy .Chart }}

{{- with .deployments }}
{{- range $deploymentName, $deploymentDetails := . }}

{{- $global := deepCopy $.global }}
{{- $_ :=  set $global.labels "app" $deploymentName }}
{{- $selector := default (printf "%v-deployment-%v" $chart.Name $deploymentName) $deploymentDetails.selector }}

{{- with $deploymentDetails.service }}
{{ include "common.kubernetes.service" (dict "name" $deploymentName "global" $global "selector" $selector "service" .) }}
{{- end }}

{{- if not $global.serviceAccount }}
{{- with $deploymentDetails.serviceAccount }}
{{ include "common.kubernetes.serviceaccount" (dict "global" $global "selector" $selector "serviceAccount" .) }}
{{- end }}
{{- end }}

{{- with $deploymentDetails.autoscaling }}
{{ include "common.kubernetes.podautoscaler" (dict "global" $global "selector" $deploymentName "autoscaling" .) }}
{{- end }}

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $deploymentName }}
  annotations:
    {{- include "common.helper.annotations" (dict "global" $global.annotations "override" $deploymentDetails.annotations) | nindent 4}}
  labels:
    {{- include "common.helper.labels" (dict "global" $global.labels "override" $deploymentDetails.labels) | nindent 4}}
spec:
  replicas: {{ required (printf "You must set a replicas count for deployment [%s]" $deploymentName ) $deploymentDetails.replicas }}
  selector:
    matchLabels:
      selector: {{ $selector }}
  {{- with $deploymentDetails.strategy }}
  strategy:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  template:
    {{- include "common.kubernetes.podtemplatespec" (dict "root" $.root "global" $global "selector" $selector "chart" $chart "pod" $deploymentDetails.pod "serviceAccount" $deploymentDetails.serviceAccount) | nindent 4 }}
{{- end }}
{{- end }}
{{- end }}
