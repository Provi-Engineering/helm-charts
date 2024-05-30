{{- define "common.kubernetes.tolerations" -}}
{{- range . }}
- key: {{ . | quote }}
  operator: "Exists"
  effect: "NoSchedule"
{{- end }}
{{- end }}
