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
{{- $nodeAffinityDisabled := default false .pod.antiAffinityDisabled }}
{{- if not $nodeAffinityDisabled }}
  {{- $labelConfig := coalesce .pod.nodeAffinityLabel .pod.antiAffinityLabel (dict "karpenter.sh/controller" "true") }}
  {{- $matchExpressions := list }}
  {{- range $labelKey, $labelValue := $labelConfig }}
    {{- if ne $labelValue nil }}
      {{- $matchExpressions = append $matchExpressions (dict "key" $labelKey "operator" "NotIn" "values" (list (printf "%v" $labelValue))) }}
    {{- end }}
  {{- end }}
  {{- if gt (len $matchExpressions) 0 }}
    {{- $nodeAffinity := dict }}
    {{- if hasKey $affinity "nodeAffinity" }}
      {{- $nodeAffinity = deepCopy (get $affinity "nodeAffinity") }}
    {{- end }}
    {{- $required := dict }}
    {{- if hasKey $nodeAffinity "requiredDuringSchedulingIgnoredDuringExecution" }}
      {{- $required = deepCopy (get $nodeAffinity "requiredDuringSchedulingIgnoredDuringExecution") }}
    {{- end }}
    {{- $nodeSelectorTerms := list }}
    {{- if hasKey $required "nodeSelectorTerms" }}
      {{- $nodeSelectorTerms = deepCopy (get $required "nodeSelectorTerms") }}
    {{- end }}
    {{- $nodeSelectorTerms = append $nodeSelectorTerms (dict "matchExpressions" $matchExpressions) }}
    {{- $_ := set $required "nodeSelectorTerms" $nodeSelectorTerms }}
    {{- $_ := set $nodeAffinity "requiredDuringSchedulingIgnoredDuringExecution" $required }}
    {{- $_ := set $affinity "nodeAffinity" $nodeAffinity }}
  {{- end }}
{{- end }}
{{- if gt (len $affinity) 0 }}
{{- toYaml $affinity }}
{{- end }}
{{- end }}
