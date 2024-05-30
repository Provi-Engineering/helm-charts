{{- define "common.kubernetes.job" -}}
{{- $chart := .Chart }}

{{- with .jobs }}
{{- range $jobName, $jobDetails := . }}

{{- $global := deepCopy $.global }}
{{- $_ :=  set $global.labels "app" $jobName }}
{{- $selector := printf "%v-job-%v" $chart.Name $jobName }}

{{- if not $global.serviceAccount }}
{{- with $jobDetails.serviceAccount }}
{{ include "common.kubernetes.serviceaccount" (dict "global" $global "selector" $selector "serviceAccount" .) }}
{{- end }}
{{- end }}

---
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ $jobName }}
  annotations:
    {{- include "common.helper.annotations" (dict "global" $global.annotations "override" $jobDetails.annotations) | nindent 4 }}
  labels:
    {{- include "common.helper.labels" (dict "global" $global.labels "override" $jobDetails.labels) | nindent 4 }}
spec:
  {{- include "common.kubernetes.base.job" (dict "root" $.root "global" $global "selector" $selector "chart" $chart "job" $jobDetails "serviceAccount" $jobDetails.serviceAccount) | nindent 2 }}
{{- end }}
{{- end }}
{{- end }}
