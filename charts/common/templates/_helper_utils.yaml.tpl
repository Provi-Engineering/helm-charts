{{- define "common.helper.mergeGlobalMap" -}}
{{- if and (kindIs "map" .override) (kindIs "map" .global) }}
{{- toYaml (mergeOverwrite .global .override ) }}
{{- else if (kindIs "map" .override) }}
{{- toYaml .override }}
{{- else if (kindIs "map" .global ) }}
{{- toYaml .global }}
{{- end }}
{{- end }}

{{- define "common.helper.env" -}}
{{- $chart := .chart }}
{{- $env := dict }}
{{- if and (kindIs "map" .override) (kindIs "map" .global.env) }}
{{- $env = mergeOverwrite (deepCopy .global.env) .override }}
{{- else if (kindIs "map" .override) }}
{{- $env = .override }}
{{- else if (kindIs "map" .global.env ) }}
{{- $env = deepCopy .global.env }}
{{- end }}
{{- range $k, $v := $env }}
{{- if kindIs "map" $v }}
- name: {{ $k }}
  valueFrom:
{{- if $v.secretsManagerKeyRef }}
    secretKeyRef:
      key: {{ include "common.helper.secretsmanagerkey" (dict "key" $v.secretsManagerKeyRef.key "property" $v.secretsManagerKeyRef.property) }}
      name: {{ $chart.Name }}
{{- else if $v.secretValue }}
    secretKeyRef:
      key: {{ $v.secretValue }}
      name: {{ $chart.Name }}
{{- else if $v.optionalSecretValue }}
    secretKeyRef:
      key: {{ $v.optionalSecretValue }}
      name: {{ $chart.Name }}
      optional: true
{{- else }}
{{- toYaml $v | nindent 4 }}
{{- end }}
{{- else }}
- name: {{ $k }}
  value: {{ quote $v }}
{{- end }}
{{- end }}
{{- end }}

{{- define "common.helper.secretsmanagerkey" -}}
{{ printf "%s-%s" (regexReplaceAll "\\W+" .key "_") .property }}
{{- end }}

{{- define "common.helper.labels" -}}
{{- $labels := dict }}
{{- if and (kindIs "map" .override) (kindIs "map" .global) }}
{{- $labels = (mergeOverwrite .global .override) }}
{{- else if (kindIs "map" .override) }}
{{- $labels = .override }}
{{- else if (kindIs "map" .global ) }}
{{- $labels = .global }}
{{- end }}
{{- toYaml $labels }}
{{- end }}

{{- define "common.helper.annotations" -}}
{{- $annotations := dict }}
{{- if and (kindIs "map" .override) (kindIs "map" .global) }}
{{- $annotations = (mergeOverwrite .global .override ) }}
{{- else if (kindIs "map" .override) }}
{{- $annotations = .override }}
{{- else if (kindIs "map" .global ) }}
{{- $annotations = .global }}
{{- end }}
{{- toYaml $annotations }}
{{- end }}
