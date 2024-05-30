{{- define "common.kubernetes.service" -}}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ .name }}
  annotations:
    {{- include "common.helper.annotations" (dict "global" .global.annotations "override" .service.annotations ) | nindent 4}}
  labels:
    {{- include "common.helper.labels" (dict "global" .global.labels "override" .service.labels ) | nindent 4}}
spec:
  selector:
    selector: {{ .selector }}
  type: {{ default "ClusterIP" .service.type }}
  {{- with .service.clusterIP }}
  clusterIP: {{ . }}
  {{- end }}
  {{- with .service.ports }}
  ports:
    {{- range $k, $v := . }}
    - name: {{ $k }}
      {{- $v | toYaml | nindent 6 }}
    {{- end }}
  {{- end }}
{{- end }}
