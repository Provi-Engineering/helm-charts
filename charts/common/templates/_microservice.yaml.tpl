{{- define "common.kubernetes.microservice" -}}
{{- $globalError := "\n\nYou must define the global annotation\n" }}
{{- $global := deepCopy (required $globalError .Values.global) }}
{{- $labels := required "You must define global labels" $global.labels}}
{{- $chart := deepCopy .Chart }}
{{- $files := .Files }}

{{- $_ := set .Values.global.labels "chart" .Chart.Name }}
{{- $_ := set .Values.global.labels "chartVersion" .Chart.Version }}
{{- $_ := set $global.labels "chart" .Chart.Name }}
{{- $_ := set $global.labels "chartVersion" .Chart.Version }}

{{- /* When we want to use a single service account for all workloads */}}
{{- with $global.serviceAccount }}
{{ include "common.kubernetes.serviceaccount" (dict "global" $global "serviceAccount" .) }}
{{- end -}}

{{- with .Values.deployments }}
{{- include "common.kubernetes.deployment" (dict "root" $ "global" $global "deployments" . "Chart" $chart) }}
{{- end -}}

{{- with .Values.statefulSets }}
{{- include "common.kubernetes.statefulSet" (dict "root" $ "global" $global "statefulSets" . "Chart" $chart) }}
{{- end -}}

{{- with .Values.configMaps }}
{{- include "common.kubernetes.configMap" (dict "root" $ "global" $global "Files" $files "configMaps" .) }}
{{- end -}}

{{- with .Values.jobs }}
{{- include "common.kubernetes.job" (dict "root" $ "global" $global "jobs" . "Chart" $chart) -}}
{{- end -}}

{{- with .Values.cronJobs }}
{{- include "common.kubernetes.cronJob" (dict "root" $ "global" $global "cronJobs" . "Chart" $chart) -}}
{{- end -}}

{{- with .Values.ingresses }}
{{- include "common.kubernetes.ingress" (dict "root" $ "global" $global "ingresses" .) -}}
{{- end -}}

{{- with .Values.secrets }}
{{- include "common.kubernetes.clusterexternalsecret" (dict "root" $ "global" $global "secrets" .) -}}
{{- end -}}
{{- end }}
