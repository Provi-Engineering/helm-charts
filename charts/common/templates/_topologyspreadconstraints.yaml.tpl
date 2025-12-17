{{- /* This provides topologySpreadConstraints to the pod spec. See: https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/ */}}
{{- define "common.kubernetes.topologyspreadconstraints" -}}
{{- $pod := . }}
{{- $custom := $pod.topologySpreadConstraints }}
{{- $defaults := $pod.defaultTopologySpreadConstraints }}
{{- $customHasValues := and $custom (gt (len $custom) 0) }}
{{- $defaultEnabled := true }}
{{- if $defaults }}
  {{- $defaultEnabled = default true $defaults.enabled }}
{{- end }}
{{- if $customHasValues }}
  {{- if kindIs "map" $custom }}
    {{- if hasKey $custom "matchLabels" }}
      {{- fail "pod.topologySpreadConstraints.matchLabels has moved to pod.defaultTopologySpreadConstraints.matchLabels" }}
    {{- else }}
      {{- fail "pod.topologySpreadConstraints must be an array of constraint maps" }}
    {{- end }}
  {{- end }}
  {{- if not (kindIs "slice" $custom) }}
    {{- fail "pod.topologySpreadConstraints must be an array of constraint maps" }}
  {{- end }}
  {{- range $idx, $constraint := $custom }}
    {{- if not (kindIs "map" $constraint) }}
      {{- fail (printf "pod.topologySpreadConstraints[%d] must be a map" $idx) }}
    {{- end }}
    {{- if not (hasKey $constraint "topologyKey") }}
      {{- fail (printf "pod.topologySpreadConstraints[%d] is missing topologyKey" $idx) }}
    {{- end }}
    {{- if not (hasKey $constraint "whenUnsatisfiable") }}
      {{- fail (printf "pod.topologySpreadConstraints[%d] is missing whenUnsatisfiable" $idx) }}
    {{- end }}
    {{- if not (hasKey $constraint "labelSelector") }}
      {{- fail (printf "pod.topologySpreadConstraints[%d] is missing labelSelector" $idx) }}
    {{- end }}
  {{- end }}
topologySpreadConstraints:
{{- toYaml $custom | nindent 2 }}
{{- else if and $defaults $defaultEnabled }}
  {{- if not (hasKey $defaults "matchLabels") }}
    {{- fail "pod.defaultTopologySpreadConstraints.matchLabels must be provided" }}
  {{- end }}
  {{- $matchLabels := $defaults.matchLabels }}
  {{- if not (kindIs "map" $matchLabels) }}
    {{- fail "pod.defaultTopologySpreadConstraints.matchLabels must be a map" }}
  {{- end }}
  {{- if eq (len $matchLabels) 0 }}
    {{- fail "pod.defaultTopologySpreadConstraints.matchLabels must contain at least one entry" }}
  {{- end }}
  {{- $whenUnsatisfiable := default "DoNotSchedule" $defaults.whenUnsatisfiable }}
topologySpreadConstraints:
- maxSkew: 1
  topologyKey: topology.kubernetes.io/zone
  whenUnsatisfiable: {{ $whenUnsatisfiable }}
  labelSelector:
    matchLabels:
    {{- range $key, $val := $matchLabels }}
      {{ $key }}: {{ printf "%v" $val | quote }}
    {{- end }}
- maxSkew: 1
  topologyKey: kubernetes.io/hostname
  whenUnsatisfiable: {{ $whenUnsatisfiable }}
  labelSelector:
    matchLabels:
    {{- range $key, $val := $matchLabels }}
      {{ $key }}: {{ printf "%v" $val | quote }}
    {{- end }}
{{- end }}
{{- end }}
