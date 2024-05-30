{{- define "common.kubernetes.configMapData" -}}

{{- if hasKey .details "template" -}}
  {{- if kindIs "string" .details.template }}
    {{- if (hasPrefix "file://" .details.template) -}}
      {{- $filePath := printf "files/%v" (trimPrefix "file://" $.details.template) -}}
      {{- tpl ($.root.Files.Get $filePath) $.root }}
      {{- println -}}
    {{- else -}}
      {{- tpl $.details.template $.root }}
      {{- println -}}
    {{- end -}}
  {{- else -}}
    {{- range $key, $value := $.details.template }}
      {{- if (hasPrefix "file://" $value) -}}
        {{- $filePath := printf "files/%v" (trimPrefix "file://" $value) -}}
        {{- $key }}: |-
          {{- tpl ($.root.Files.Get $filePath) $.root | nindent 2 }}
          {{- println -}}
      {{- else -}}
        {{- $key }}: {{ tpl $value $.root }}
        {{- println -}}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- range $key, $value := $.details.data }}
  {{- if (hasPrefix "file://" $value) -}}
    {{- $filePath := printf "files/%v" (trimPrefix "file://" $value) }}
    {{- $key }}: |-
      {{- $.root.Files.Get $filePath | nindent 2 -}}
      {{- println -}}
  {{- else if (hasPrefix "json://" $value) -}}
    {{- $filePath := printf "files/%v" (trimPrefix "json://" $value) -}}
    {{- $key }}: |-
      {{- $.root.Files.Get $filePath | mustFromJson | toPrettyJson | nindent 2 -}}
      {{- println -}}
  {{- else if (hasPrefix "yaml://" $value) -}}
    {{- $filePath := printf "files/%v" (trimPrefix "yaml://" $value) -}}
    {{- $key }}: |-
      {{- $.root.Files.Get $filePath | fromYaml | toYaml | nindent 2 -}}
      {{- println -}}
  {{- else -}}
    {{- $key }}: {{ quote $value }}
    {{- println -}}
  {{- end }}
{{- end }}

{{- end }}

{{- define "common.kubernetes.configMapData.checksum" -}}
{{- include "common.kubernetes.configMapData" (dict "root" .root "details" .details) | fromYaml | toYaml | sha256sum -}}
{{- end }}

{{- define "common.kubernetes.configMap" -}}
{{- range $configMapName, $configMapDetails := .configMaps }}
{{- $global := deepCopy $.global }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $configMapName }}
  annotations:
    {{- include "common.helper.annotations" (dict "global" $global.annotations "override" $configMapDetails.annotations) | nindent 4}}
  labels:
    {{- include "common.helper.labels" (dict "global" $global.labels "override" $configMapDetails.labels) | nindent 4}}
data:
{{- include "common.kubernetes.configMapData" (dict "root" $.root "details" $configMapDetails) | nindent 2 }}
{{- end }}
{{- end }}
