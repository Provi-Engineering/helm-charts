{{- define "common.kubernetes.clusterexternalsecret" -}}
{{- with .secrets }}
{{- range $secretName, $secretDetails := . }}
---
apiVersion: external-secrets.io/{{ default "v1beta1" .apiVersion }}
kind: ClusterExternalSecret
metadata:
  name: {{ .k8sSecretName }}
  annotations:
    helm.sh/hook: pre-install,pre-upgrade
    helm.sh/hook-delete-policy: before-hook-creation
    helm.sh/hook-weight: "-2"
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
    data:
    {{- range $secretKey := .secretKeys }}
    - secretKey: {{ $secretKey }}
      remoteRef:
        conversionStrategy: Default
        decodingStrategy: None
        key: {{ $secretDetails.awsSecretName }}
        property: {{ $secretKey }}
    {{- end }}
{{- end -}}
{{- end -}}
{{- end -}}
