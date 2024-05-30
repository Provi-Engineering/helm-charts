{{- define "common.kubernetes.serviceaccount" -}}
{{- $awsAccountId := .global.awsAccountId | required "global.awsAccountId is required." -}}
{{- $role := .global.serviceAccount.role | default dict }}
{{- $roleName := .global.serviceAccount.name }}
{{- if $role.name }}
{{- $roleName = $role.name }}
{{- end }}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ default .selector .serviceAccount.name }}
  annotations:
    {{- include "common.helper.annotations" (dict "global" .global.annotations "override" .serviceAccount.annotations ) | nindent 4}}
    eks.amazonaws.com/role-arn: "arn:aws:iam::{{ $awsAccountId | toString }}:role/{{ $roleName }}"
    eks.amazonaws.com/sts-regional-endpoints: "true"
  labels:
    {{- include "common.helper.labels" (dict "global" .global.labels "override" .serviceAccount.labels ) | nindent 4}}
{{- end }}
