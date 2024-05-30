{{- define "common.kubernetes.base.job" -}}
backoffLimit: {{ default 1 .job.backoffLimit }}
completions: {{ default 1 .job.completions }}
parallelism: {{ default 1 .job.parallelism }}
{{- with .job.activeDeadlineSeconds }}
activeDeadlineSeconds: {{ . }}
{{- end }}
template:
  {{- /* Disable healthcheck requirements for all pods in jobs */}}
  {{- $healthcheckOverride := dict "livenessProbe" (dict "disabled" true) "readinessProbe" (dict "disabled" true) }}
  {{- $pod := .job.pod }}
  {{- /* Change default pod restart policy */}}
  {{- $pod := mergeOverwrite $pod (dict "restartPolicy" "Never") }}
  {{- range $k, $v := $pod.containers }}
    {{- $_ := set $pod.containers $k (mergeOverwrite $healthcheckOverride $v) }}
  {{- end }}
  {{- include "common.kubernetes.podtemplatespec" (dict "root" $.root "global" .global "selector" .selector "chart" .chart "pod" $pod "serviceAccount" .serviceAccount) | trim | nindent 2 }}
{{- end }}
