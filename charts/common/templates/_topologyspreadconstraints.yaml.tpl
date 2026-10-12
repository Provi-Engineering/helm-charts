{{- /* Zone spread is a hard HA requirement; the soft hostname spread is opt-in (hostname: true). See README. */}}
{{- define "common.kubernetes.topologyspreadconstraints" -}}
topologySpreadConstraints:
- maxSkew: 1
  topologyKey: topology.kubernetes.io/zone
  whenUnsatisfiable: DoNotSchedule
  labelSelector:
    matchLabels:
    {{- range $key, $val := .topologySpreadConstraints.matchLabels }}
      {{ $key }}: {{ $val | quote }}
    {{- end }}
{{- if .topologySpreadConstraints.hostname }}
- maxSkew: 2
  topologyKey: kubernetes.io/hostname
  whenUnsatisfiable: ScheduleAnyway
  labelSelector:
    matchLabels:
    {{- range $key, $val := .topologySpreadConstraints.matchLabels }}
      {{ $key }}: {{ $val | quote }}
    {{- end }}
{{- end }}
{{- end }}
