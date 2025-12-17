{{- define "common.kubernetes.statefulSet" -}}
{{- $chart := .Chart }}

{{- with .statefulSets }}
{{- range $statefulSetName, $statefulSetDetails := . }}

{{- $global := deepCopy $.global }}
{{- $_ :=  set $global.labels "app" $statefulSetName }}
{{- $selector := printf "%v-statefulset-%v" $chart.Name $statefulSetName }}

{{- with $statefulSetDetails.service }}
{{ include "common.kubernetes.service" (dict "name" $statefulSetName "global" $global "selector" $selector "service" .) }}
{{- end }}

{{- if not $global.serviceAccount }}
{{- with $statefulSetDetails.serviceAccount }}
{{- if ne .create false }}
{{ include "common.kubernetes.serviceaccount" (dict "global" $global "selector" $selector "serviceAccount" .) }}
{{- end }}
{{- end }}
{{- end }}

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ $statefulSetName }}
  annotations:
    {{- include "common.helper.annotations" (dict "global" $global.annotations "override" $statefulSetDetails.annotations) | nindent 4}}
  labels:
    {{- include "common.helper.labels" (dict "global" $global.labels "override" $statefulSetDetails.labels) | nindent 4}}
spec:
  serviceName: {{ $statefulSetName }}
  replicas: {{ required (printf "You must set a replicas count for statefulset [%s]" $statefulSetName ) $statefulSetDetails.replicas }}
  updateStrategy:
    type: {{ default "RollingUpdate" $statefulSetDetails.updateStrategy }}
  selector:
    matchLabels:
      selector: {{ $selector }}
  template:
    {{- include "common.kubernetes.podtemplatespec" (dict "root" $.root "global" $global "selector" $selector "chart" $chart "pod" $statefulSetDetails.pod "serviceAccount" $statefulSetDetails.serviceAccount) | nindent 4 }}
  {{- with $statefulSetDetails.volumeClaimTemplates }}
  volumeClaimTemplates:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
