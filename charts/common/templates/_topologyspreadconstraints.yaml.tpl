{{- /* Zone spread is a hard HA requirement; hostname spread is a soft preference so the
     scheduler can bin-pack when resources allow (see AWS EKS HA guidance). */}}
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
- maxSkew: 2
  topologyKey: kubernetes.io/hostname
  whenUnsatisfiable: ScheduleAnyway
  labelSelector:
    matchLabels:
    {{- range $key, $val := .topologySpreadConstraints.matchLabels }}
      {{ $key }}: {{ $val | quote }}
    {{- end }}
{{- end }}
