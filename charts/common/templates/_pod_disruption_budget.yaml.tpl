{{- define "common.kubernetes.pod_disruption_budget" -}}
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ printf "%s-%s-pdb" .chart.Name .deploymentName }}
spec:
{{- if .pdb.minAvailable }}
  minAvailable: {{ .pdb.minAvailable }}
{{- end }}
{{- if .pdb.maxUnavailable }}
  maxUnavailable: {{ .pdb.maxUnavailable }}
{{- end }}
  selector:
    matchLabels:
      app: {{ .selector }}
{{- end }}
