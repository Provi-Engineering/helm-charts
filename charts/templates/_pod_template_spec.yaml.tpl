{{- define "common.kubernetes.podtemplatespec" -}}
metadata:
  annotations:
    {{- include "common.helper.annotations" (dict "global" .global.annotations "override" .pod.annotations ) | trim | nindent 4 }}
  labels:
    selector: {{ .selector }}
    {{- include "common.helper.labels" (dict "global" .global.labels "override" .pod.labels ) | trim | nindent 4 }}
spec:
  {{- include "common.kubernetes.podspec" (dict "root" $.root "podspecs" .) | trim | nindent 2 -}}
{{- end }}
