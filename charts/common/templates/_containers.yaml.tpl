{{- define "common.kubernetes.containers" -}}
{{- if kindIs "map" .containers }}
  {{- if $.isInitContainer -}}
    {{- fail "initContainer values must be specified as a list (not a map)" }}
  {{- end }}
  {{- range $name, $details := $.containers }}
    {{- include "common.kubernetes.containerspec" (dict "root" $.root "global" $.global "chart" $.chart "name" $name "details" $details "isInitContainer" $.isInitContainer) }}
  {{- end }}
{{- else if kindIs "slice" .containers }}
  {{- if not $.isInitContainer -}}
    {{- fail "Container values must be specified as a map (not a list)" }}
  {{- end }}
  {{- range $details := $.containers }}
    {{- include "common.kubernetes.containerspec" (dict "root" $.root "global" $.global "chart" $.chart "name" $details.name "details" $details  "isInitContainer" $.isInitContainer) }}
  {{- end }}
{{- else if $.isInitContainer }}
  {{- fail (printf "initContainer values must be specified as a list (not a %s)" (kindOf .containers)) }}
{{- else -}}
  {{- fail (printf "Container values must be specified as a map (not a %s)" (kindOf .containers)) }}
{{- end }}
{{- end }}

{{- define "common.kubernetes.containerspec" }}
- name: {{ .name }}
  image: {{ required (printf "You must define an image for container [%s]" .name) (coalesce .details.image .global.image) }}
  imagePullPolicy: {{ default "Always" .details.imagePullPolicy }}
  {{- with .details.command }}
  command:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .details.args }}
  args:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  securityContext:
    {{- toYaml (mergeOverwrite (dict "runAsNonRoot" false) (default dict .details.securityContext)) | nindent 4 }}
  {{- $env := include "common.helper.env" (dict "override" .details.env "global" .global "chart" .chart) }}
  {{- if $env }}
  env:
    {{- $env | trim | nindent 4 }}
    {{- if and (hasKey $.root.Values "spec") (hasKey $.root.Values.spec "clusterName") }}
    - name: CLUSTER_NAME
      value: {{ $.root.Values.spec.clusterName }}
    {{- end }}
  {{- end }}
  {{- with .details.envFrom }}
  envFrom:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .details.lifecycle }}
  lifecycle:
    {{- toYaml . | nindent 4 }}
  {{- end }}

{{- $probe := dict }}
{{- if .isInitContainer }}
  {{- $probe = default (dict "disabled" true) $.details.livenessProbe }}
{{- else }}
  {{- $probe = required (printf "You must define a livenessProbe for container [%s]. To disable, set:\n\n        livenessProbe:\n          disabled: true" $.name) $.details.livenessProbe }}
{{- end }}
{{- if not $probe.disabled }}
  {{- if (or (hasKey $probe "tcpSocket") (or (hasKey $probe "exec") (hasKey $probe "httpGet")))}}
  {{- with $probe }}
  livenessProbe:
    initialDelaySeconds: {{ default 0 .initialDelaySeconds }}
    periodSeconds: {{ default 5 .periodSeconds }}
    timeoutSeconds: {{ default 1 .timeoutSeconds }}
    failureThreshold: {{ default 5 .failureThreshold }}
    successThreshold: {{ default 1 .successThreshold }}
    {{- with .tcpSocket }}
    tcpSocket:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .exec }}
    exec:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .httpGet }}
    httpGet:
      {{- toYaml . | nindent 6 }}
    {{- end }}
  {{- end -}}
  {{- else }}
    {{- fail (printf "\n\nERROR: You must define a livenessProbe for container [%s]. To disable, set:\n\n        livenessProbe:\n          disabled: true" $.name) }}
  {{- end -}}
{{- end -}}

{{- $probe := dict }}
{{- if .isInitContainer }}
  {{- $probe = default (dict "disabled" true) $.details.readinessProbe }}
{{- else }}
  {{- $probe = required (printf "You must define a readinessProbe for container [%s]. To disable, set:\n\n        readinessProbe:\n          disabled: true" $.name) $.details.readinessProbe }}
{{- end }}
{{- if not $probe.disabled }}
  {{- if (or (hasKey $probe "tcpSocket") (or (hasKey $probe "exec") (hasKey $probe "httpGet")))}}
  {{- with .details.readinessProbe }}
  readinessProbe:
    initialDelaySeconds: {{ default 0 .initialDelaySeconds }}
    periodSeconds: {{ default 5 .periodSeconds }}
    timeoutSeconds: {{ default 1 .timeoutSeconds }}
    failureThreshold: {{ default 1 .failureThreshold }}
    successThreshold: {{ default 5 .successThreshold }}
    {{- with .tcpSocket }}
    tcpSocket:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .exec }}
    exec:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .httpGet }}
    httpGet:
      {{- toYaml . | nindent 6 }}
    {{- end }}
  {{- end -}}
  {{- else }}
    {{- fail (printf "\n\nERROR: You must define a readinessProbe for container [%s]. To disable, set:\n\n        readinessProbe:\n          disabled: true" $.name) }}
  {{- end -}}
{{- end -}}
{{- with .details.startupProbe }}
  startupProbe:
    {{- toYaml . | nindent 4 }}
{{- end -}}

{{- $containerKind := ternary "initContainer" "container" .isInitContainer }}
{{- $resourcesError := printf "\n\nERROR: You must specify resources for %s [%v]. Example:\n\n  resources:\n    limits:\n      memory: 200Mi\n    requests:\n      cpu: 30m\n      memory: 100Mi" $containerKind .name }}
{{- $resources := required $resourcesError .details.resources }}
  resources:
{{- $limits := required $resourcesError $resources.limits }}
{{- $ephemeral_limits := index $limits "ephemeral-storage" }}
{{- $ephemeral_requests := index $resources.requests "ephemeral-storage" }}
{{- $cpu_limits := index $limits "cpu" }}
    limits:
      memory: {{ required $resourcesError $limits.memory }}
      {{- if $ephemeral_limits}}
      ephemeral-storage: {{ $ephemeral_limits }}
      {{- end }}
      {{- if $cpu_limits}}
      cpu: {{ $cpu_limits }}
      {{- end }}
    requests:
      cpu: {{ required $resourcesError $resources.requests.cpu }}
      memory: {{ required $resourcesError $resources.requests.memory }}
      {{- if $ephemeral_requests }}
      ephemeral-storage: {{ $ephemeral_requests }}
      {{- end }}
  {{- $volumeMounts := default list .details.volumeMounts }}
  {{- with $volumeMounts }}
  volumeMounts:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
