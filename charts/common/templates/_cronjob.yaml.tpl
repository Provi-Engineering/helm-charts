{{- define "common.kubernetes.cronJob" -}}
{{- $chart := .Chart }}

{{- with .cronJobs }}
{{- range $cronJobName, $cronJobDetails := . }}

{{- $global := deepCopy $.global }}
{{- $_ :=  set $global.labels "app" $cronJobName }}
{{- $selector := printf "%v-cronjob-%v" $chart.Name $cronJobName }}

{{- if not $global.serviceAccount }}
{{- with $cronJobDetails.serviceAccount }}
{{ include "common.kubernetes.serviceaccount" (dict "global" $global "selector" $selector "serviceAccount" .) }}
{{- end }}
{{- end }}

---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ $cronJobName }}
  annotations:
    {{- include "common.helper.annotations" (dict "global" $global.annotations "override" $cronJobDetails.annotations) | nindent 4}}
  labels:
    {{- include "common.helper.labels" (dict "global" $global.labels "override" $cronJobDetails.labels) | nindent 4}}
spec:
  timeZone: {{ default 	"Etc/UTC" $cronJobDetails.timeZone }}
  suspend: {{ default false $cronJobDetails.disabled }}
  concurrencyPolicy: {{ default "Forbid" $cronJobDetails.concurrencyPolicy }}
  failedJobsHistoryLimit: {{ default 5 $cronJobDetails.failedJobsHistoryLimit }}
  successfulJobsHistoryLimit: {{ default 5 $cronJobDetails.successfulJobsHistoryLimit }}
  {{- with $cronJobDetails.startingDeadlineSeconds }}
  startingDeadlineSeconds: {{ . }}
  {{- end }}
  schedule: {{ required (printf "You must specify a schedule for cronJob [%v]" $cronJobName) $cronJobDetails.schedule | quote }}
  jobTemplate:
    spec:
      {{- include "common.kubernetes.base.job" (dict "root" $.root "global" $global "selector" $selector "chart" $chart "job" $cronJobDetails "serviceAccount" $cronJobDetails.serviceAccount) | nindent 6 }}

{{- end }}
{{- end }}
{{- end }}
