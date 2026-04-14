{{- define "common.kubernetes.clusterexternalsecret" -}}
{{- with .secrets }}
{{- range $secretName, $secretDetails := . }}
---
apiVersion: external-secrets.io/{{ default "v1" .apiVersion }}
kind: ClusterExternalSecret
metadata:
  name: {{ .k8sSecretName }}
spec:
  namespaceSelector:
    matchLabels:
      kubernetes.io/metadata.name: {{ .namespace }}
  refreshTime: {{ .refreshTime }}

  externalSecretSpec:
    refreshInterval: {{ .refreshInterval }}
    secretStoreRef:
      name: {{ .secretStoreRef.name }}
      kind: ClusterSecretStore
    target:
      name: {{ .k8sSecretName }}
      creationPolicy: Owner
    {{- if and .secretKeys (gt (len .secretKeys) 0) }}
    data:
    {{- range $secretKey := .secretKeys }}
    - secretKey: {{ $secretKey }}
      remoteRef:
        conversionStrategy: Default
        decodingStrategy: None
        key: {{ $secretDetails.awsSecretName }}
        property: {{ $secretKey }}
    {{- end }}
    {{- else }}
    dataFrom:
    - extract:
        key: {{ $secretDetails.awsSecretName }}
    {{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
