{{/* This provides topologySpreadConstraints to the pod spec. See: https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/ */}}
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
- maxSkew: 1
  topologyKey: kubernetes.io/hostname
  whenUnsatisfiable: DoNotSchedule
  labelSelector:
    matchLabels:
    {{- range $key, $val := .topologySpreadConstraints.matchLabels }}
      {{ $key }}: {{ $val | quote }}
    {{- end }}
{{- end }}
