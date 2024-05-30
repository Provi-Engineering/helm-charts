{{- define "common.kubernetes.ingress" -}}
{{- $global := deepCopy .global }}
{{- $serviceErrorMessage := "You must specify a service with name and port for ingress [%v]" }}
{{- $schemeErrorMessage := "You must specify a scheme (internal, internet-facing) for ingress [%v]" }}
{{- $certArnErrorMessage := "You must specify a certificateArn for ingress [%v]" }}
{{- $commonAnnotations := dict }}
{{- $_ := set $commonAnnotations "nginx.ingress.kubernetes.io/proxy-body-size" "0" }}

{{- $ingressesAnnotations := dict }}
{{- with .ingresses }}
{{- if hasKey . "annotations" }}
  {{- $ingressesAnnotations = .annotations }}
  {{- $_ := unset . "annotations" }}
{{- end }}

{{- range $k, $v := . }}
{{- $finalAnnotations := dict }}
{{- $annotations := dict }}
{{- if hasKey $v "annotations" }}
  {{- $annotations = $v.annotations }}
{{- end }}
{{- $albAnnotations := dict }}
{{ if eq $v.ingressClass "alb" }}
{{- $healthcheckPath := default "/health" $v.healthcheckPath }}
{{- $nameTag := printf "Name=%s-alb" $k }}
{{- $_ := required (printf $certArnErrorMessage $k) $v.certificateArn}}
{{- $_ := required (printf $schemeErrorMessage $k) $v.scheme}}
{{- $_ := set $albAnnotations "alb.ingress.kubernetes.io/backend-protocol" "HTTP" }}
{{- $_ := set $albAnnotations "alb.ingress.kubernetes.io/certificate-arn" $v.certificateArn }}
{{- $_ := set $albAnnotations "alb.ingress.kubernetes.io/scheme" $v.scheme }}
{{- $_ := set $albAnnotations "alb.ingress.kubernetes.io/tags" $nameTag }}
{{- $_ := set $albAnnotations "alb.ingress.kubernetes.io/target-type" "ip" }}
{{- $_ := set $albAnnotations "alb.ingress.kubernetes.io/healthcheck-path" $healthcheckPath }}
{{- $_ := set $albAnnotations "alb.ingress.kubernetes.io/healthcheck-protocol" "HTTP" }}
{{- $_ := set $albAnnotations "alb.ingress.kubernetes.io/listen-ports" "[{\"HTTP\": 80}, {\"HTTPS\":443}]" }}
{{- $_ := set $albAnnotations "alb.ingress.kubernetes.io/ssl-redirect" "443" }}
{{- end }}

{{/* Generate a single hostname based on app/root domains or fall back to hostnames list */}}
{{- $appDomain := default $v.appDomain $global.appDomain }}
{{- $rootDomain := default $v.rootDomain $global.rootDomain }}
{{- $hostname := printf "%s.%s" $appDomain $rootDomain }}
{{- $hostnames := default (list $hostname) $v.hostnames }}
{{- $rules := $hostnames }}
{{- if $v.hostnamesNoExternalDNS }}
{{- $rules = (concat $hostnames $v.hostnamesNoExternalDNS) }}
{{- end }}

{{- $_ := set $finalAnnotations "external-dns.alpha.kubernetes.io/hostname" (join "," $hostnames) }}
{{- $finalAnnotations = (mergeOverwrite $finalAnnotations $global.annotations $commonAnnotations $ingressesAnnotations $annotations) }}
{{- if eq $v.ingressClass "alb" -}}

{{- $finalAnnotations = (mergeOverwrite $finalAnnotations $albAnnotations) }}
{{- end -}}
{{- $_ := required (printf $serviceErrorMessage $k) $v.service }}

{{/* Require specific app/root domain if hostnames list is not set */}}
{{- if not $v.hostnames }}
{{- $_ := required (printf "You must specify appDomain in the ingress or global section") $appDomain }}
{{- $_ := required (printf "You must specify rootDomain in the ingress or global section") $rootDomain }}
{{- end }}

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ $k }}
  annotations:
    {{- toYaml $finalAnnotations | nindent 4}}
    external-dns.alpha.kubernetes.io/ttl: "10"
    {{- if and (hasKey $.root.Values "spec" ) (hasKey $.root.Values.spec "ingress") }}
    {{- if (hasKey $.root.Values.spec.ingress "route53_weight") }}
    external-dns.alpha.kubernetes.io/aws-weight: "{{ $.root.Values.spec.ingress.route53_weight }}"
    {{- end }}
    {{- end }}
    {{- if and (hasKey $.root.Values "spec" ) (hasKey $.root.Values.spec "clusterName") }}
    external-dns.alpha.kubernetes.io/set-identifier: {{ $.root.Values.spec.clusterName }}
    {{- end }}
  labels:
    {{- include "common.helper.labels" (dict "global" $global.labels "override" $v.labels) | nindent 4 }}
spec:
  ingressClassName: {{ $v.ingressClass | default "alb" }}
  rules:
    {{- range $entry := $rules }}
    - host: "{{ $entry }}"
      http:
        paths:
          - path: /
            pathType: {{ $v.pathType | default "Prefix" }}
            backend:
              service:
                name: {{ $v.service.name }}
                port:
                  number: {{ $v.service.port }}
    {{- end }}
{{- end }}
{{- end }}
{{- end }}
