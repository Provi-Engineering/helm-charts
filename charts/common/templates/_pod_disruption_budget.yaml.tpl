{{- define "common.kubernetes.pod_disruption_budget" }}
{{- include "common.kubernetes.pod_disruption_budget.guard" . }}
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
      selector: {{ .selector }}
{{- end }}

{{- /*
Fails the render when either setting allows no voluntary disruptions at the
replica floor, which blocks node drains. Percentages round up, as Kubernetes
does. A zero maxUnavailable blocks at any replica count.
*/}}
{{- define "common.kubernetes.pod_disruption_budget.guard" }}
{{- $floor := .replicaFloor | default 0 }}
{{- range $key := list "minAvailable" "maxUnavailable" }}
{{- if and (hasKey $.pdb $key) (not (kindIs "invalid" (get $.pdb $key))) }}
{{- $raw := toString (get $.pdb $key) }}
{{- $count := int (trimSuffix "%" $raw) }}
{{- if and (hasSuffix "%" $raw) (gt $floor 0) }}
{{- $count = div (add (mul $count $floor) 99) 100 }}
{{- end }}
{{- $blocks := eq $count 0 }}
{{- if eq $key "minAvailable" }}
{{- $blocks = and (gt $floor 0) (ge $count $floor) }}
{{- end }}
{{- if $blocks }}
{{- fail (printf "podDisruptionBudget for deployment [%s] allows no voluntary disruptions (%s: %s with a replica floor of %d), which blocks node drains. Use maxUnavailable: 1." $.deploymentName $key $raw $floor) }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
