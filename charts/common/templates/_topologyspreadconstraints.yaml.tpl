{{- /* Zone spread is a hard HA requirement; hostname spread is a soft preference so the
     scheduler can bin-pack when resources allow (see AWS EKS HA guidance).
     hostname: false drops the hostname spread so Karpenter packs nodes within each zone. */}}
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
{{- if ne (toString (dig "hostname" true .topologySpreadConstraints)) "false" }}
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
