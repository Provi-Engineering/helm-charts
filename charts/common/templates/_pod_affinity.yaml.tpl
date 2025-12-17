{{- define "common.kubernetes.affinity" -}}
{{- $rawAffinity := default dict .pod.affinity }}
{{- $affinity := dict }}
{{- if kindIs "map" $rawAffinity }}
  {{- if gt (len $rawAffinity) 0 }}
    {{- if or (hasKey $rawAffinity "nodeAffinity") (hasKey $rawAffinity "podAffinity") (hasKey $rawAffinity "podAntiAffinity") }}
      {{- $affinity = deepCopy $rawAffinity }}
    {{- else }}
      {{- $matchExpressions := list }}
      {{- range $key, $val := $rawAffinity }}
        {{- $values := list }}
        {{- if kindIs "slice" $val }}
          {{- $values = $val }}
        {{- else }}
          {{- $values = list $val }}
        {{- end }}
        {{- $matchExpressions = append $matchExpressions (dict "key" $key "operator" "In" "values" $values) }}
      {{- end }}
      {{- if gt (len $matchExpressions) 0 }}
        {{- $affinity = dict "nodeAffinity" (dict "requiredDuringSchedulingIgnoredDuringExecution" (dict "nodeSelectorTerms" (list (dict "matchExpressions" $matchExpressions)))) }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- else if $rawAffinity }}
  {{- fail "pod.affinity must be provided as a map" }}
{{- end }}
{{- $antiAffinityDisabled := default false .pod.antiAffinityDisabled }}
{{- if not $antiAffinityDisabled }}
  {{- $labelConfig := .pod.antiAffinityLabel | default (dict "karpenter.sh/controller" "true") }}
  {{- $matchExpressions := list }}
  {{- range $labelKey, $labelValue := $labelConfig }}
    {{- if ne $labelValue nil }}
      {{- $matchExpressions = append $matchExpressions (dict "key" $labelKey "operator" "In" "values" (list (printf "%v" $labelValue))) }}
    {{- end }}
  {{- end }}
  {{- if gt (len $matchExpressions) 0 }}
    {{- $term := dict "labelSelector" (dict "matchExpressions" $matchExpressions) "topologyKey" "kubernetes.io/hostname" }}
    {{- $podAntiAffinity := dict }}
    {{- if hasKey $affinity "podAntiAffinity" }}
      {{- $podAntiAffinity = deepCopy (get $affinity "podAntiAffinity") }}
    {{- end }}
    {{- $required := list }}
    {{- if hasKey $podAntiAffinity "requiredDuringSchedulingIgnoredDuringExecution" }}
      {{- $required = deepCopy (get $podAntiAffinity "requiredDuringSchedulingIgnoredDuringExecution") }}
    {{- end }}
    {{- $required = append $required $term }}
    {{- $_ := set $podAntiAffinity "requiredDuringSchedulingIgnoredDuringExecution" $required }}
    {{- $_ := set $affinity "podAntiAffinity" $podAntiAffinity }}
  {{- end }}
{{- end }}
{{- if gt (len $affinity) 0 }}
{{- toYaml $affinity }}
{{- end }}
{{- end }}
