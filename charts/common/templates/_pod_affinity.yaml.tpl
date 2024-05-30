{{- define "common.kubernetes.affinity" -}}
nodeAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
    nodeSelectorTerms:
      - matchExpressions:
        {{- range $key, $val := .pod.affinity | default (dict "type" "karpenter")}}
          - key: {{ $key }}
            operator: In
            values:
              - {{ $val }}
        {{- end }}
{{- end }}
