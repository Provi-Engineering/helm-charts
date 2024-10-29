{{- define "common.kubernetes.podautoscaler" }}
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ .selector }}
spec:
  minReplicas: {{ default 1 .autoscaling.minReplicas }}
  maxReplicas: {{ default 3 .autoscaling.maxReplicas }}
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ .selector }}
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ default 80 .autoscaling.targetUtilization }}
  {{- if .autoscaling.behavior }}
  behavior: {{ toYaml .autoscaling.behavior | nindent 4 }}
  {{- end }}
{{ end }}
