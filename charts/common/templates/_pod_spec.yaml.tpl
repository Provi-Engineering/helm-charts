{{- define "common.kubernetes.podspec" -}}
{{- with .podspecs }}
{{- $global := .global }}
{{- $chart := .chart }}
{{- $pod := deepCopy (.pod | default dict) }}
{{- with $global.podDefaults }}
{{- if and .tolerations (not $pod.tolerations) }}
{{- $_ := set $pod "tolerations" .tolerations }}
{{- end }}
{{- if and .affinity (not $pod.affinity) }}
{{- $_ := set $pod "affinity" .affinity }}
{{- end }}
{{- end }}
{{- $serviceAccount := dict }}
{{- if .serviceAccount }}
  {{- $serviceAccount = .serviceAccount }}
{{- end }}
{{- if $pod.topologySpreadConstraints }}
{{- include "common.kubernetes.topologyspreadconstraints" $pod }}
{{- end }}
{{- if $pod.imagePullSecretsName }}
imagePullSecrets:
  - name: {{ $pod.imagePullSecretsName }}
{{- end }}
{{- if $serviceAccount.enabled }}
{{- if $global.serviceAccount }}
serviceAccountName: {{ $global.serviceAccount.name }}
{{- else }}
serviceAccountName: {{ default .selector $serviceAccount.name }}
{{- end }}
{{- end }}
automountServiceAccountToken: {{ default false $serviceAccount.enabled }}
{{- if $pod.disableServiceLinks }}
enableServiceLinks: false
{{- end }}
{{- with $pod.tolerations }}
tolerations:
{{- include "common.kubernetes.tolerations" . | trim | nindent 2 }}
{{- end }}
restartPolicy: {{ default "Always" $pod.restartPolicy }}
{{- with $pod.initContainers }}
initContainers:
{{- include "common.kubernetes.containers" (dict "root" $.root "global" $global "chart" $chart "containers" . "isInitContainer" true) | trim | nindent 2 }}
{{- end }}
{{- with $pod.securityContext }}
securityContext:
{{- if (hasKey . "fsGroup") }}
  {{- toYaml (mergeOverwrite (dict "fsGroupChangePolicy" "OnRootMismatch") .) | nindent 2 }}
{{- else }}
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
terminationGracePeriodSeconds: {{ default 30 $pod.terminationGracePeriodSeconds }}
{{- $volumes := default list $pod.volumes }}
{{- with $volumes }}
volumes:
  {{- toYaml . | nindent 2 }}
{{- end }}
containers:
{{- include "common.kubernetes.containers" (dict "root" $.root "global" $global "chart" $chart "containers" $pod.containers "isInitContainer" false) | trim | nindent 2 }}
affinity:
{{- include "common.kubernetes.affinity" (dict "pod" $pod) | nindent 2 }}
{{- end }}
{{- end }}
