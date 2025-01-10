# bats file_tags=tag:all, tag:ingress
setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load 'test_helper/bats-file/load'

  AWS_PROFILE=provi-development helm dep update test/fixtures/ingresses &> /dev/null

  TEST_TEMP_DIR="$(temp_make)"
}

teardown() {
  temp_del "$TEST_TEMP_DIR"
}

# bats test_tags=tag:oauth
@test "oauth: outputs a template with auth annotations" {
  run helm template -f test/fixtures/ingresses/values-oauth.yaml test/fixtures/ingresses/
  assert_output --partial 'kind: Ingress'
  assert_output --partial 'nginx.ingress.kubernetes.io/auth-signin: https://auth.example.com/oauth2/start?rd=https://$host$uri'
  assert_output --partial 'nginx.ingress.kubernetes.io/auth-url: https://auth.example.com/oauth2/auth'
  assert_output --partial 'ingressClassName: nginx-internal'
}

# bats test_tags=tag:oauth
@test "ouath: matches expected output" {
  helm template -f test/fixtures/ingresses/values-oauth.yaml test/fixtures/ingresses/ > "$TEST_TEMP_DIR/oauth_output.yaml"
  assert diff -ub test/expected_output/ingresses-oauth.yaml "$TEST_TEMP_DIR/oauth_output.yaml"
}

# bats test_tags=tag:nodns
@test "nodns: outputs a template with no external-dns annotation" {
  run helm template -f test/fixtures/ingresses/values-nodns.yaml test/fixtures/ingresses/
  assert_output --partial 'ingressClassName: nginx-internal'
  assert_output --partial 'external-dns.alpha.kubernetes.io/hostname: test-ingresses.example.com'
  refute_output --partial 'external-dns.alpha.kubernetes.io/hostname: test-ingresses2.example.com'
}

# bats test_tags=tag:nodns
@test "nodns: matches expected output" {
  helm template -f test/fixtures/ingresses/values-nodns.yaml test/fixtures/ingresses/ > "$TEST_TEMP_DIR/nodns_output.yaml"
  assert diff -ub test/expected_output/ingresses-nodns.yaml "$TEST_TEMP_DIR/nodns_output.yaml"
}

# bats test_tags=tag:basicauth
@test "basicauth: outputs a template with no external-dns annotation" {
  run helm template -f test/fixtures/ingresses/values-basicauth.yaml test/fixtures/ingresses/
  assert_output --partial 'ingressClassName: nginx-internal'
  assert_output --partial 'external-dns.alpha.kubernetes.io/hostname: test-ingresses.example.com'
}

# bats test_tags=tag:basicauth
@test "basicauth: matches expected output" {
  helm template -f test/fixtures/ingresses/values-basicauth.yaml test/fixtures/ingresses/ > "$TEST_TEMP_DIR/basicauth_output.yaml"
  assert diff -ub test/expected_output/ingresses-basicauth.yaml "$TEST_TEMP_DIR/basicauth_output.yaml"
}

# bats test_tags=tag:nginx-external
@test "nginx-external: outputs a template with an ingress class name called nginx" {
  run helm template -f test/fixtures/ingresses/values-nginx-external.yaml test/fixtures/ingresses/
  assert_output --partial 'ingressClassName: nginx'
}

# bats test_tags=tag:nginx-external
@test "nginx-external: matches expected output" {
  helm template -f test/fixtures/ingresses/values-nginx-external.yaml test/fixtures/ingresses/ > "$TEST_TEMP_DIR/nginx-external_output.yaml"
  assert diff -ub test/expected_output/ingresses-nginx-external.yaml "$TEST_TEMP_DIR/nginx-external_output.yaml"
}

# bats test_tags=tag:ingress-no-service
@test "nginx-ingress: fails if service is not specified" {
  run helm template -f test/fixtures/ingresses/badvalues-no-service.yaml test/fixtures/ingresses/
  assert_failure
  assert_output --partial 'You must specify a service with name and port for ingress [dummy]'
}

# bats test_tags=tag:ingress-no-hostnames
@test "basicauth: uses appDomain and rootDomain to construct a hostname if none specified" {
  run helm template -f test/fixtures/ingresses/values-no-hostnames.yaml test/fixtures/ingresses/
  assert_output --partial 'host: "my-cool-service.coolservices.com"'
}

# bats test_tags=tag:alb-internal
@test "alb-internal: matches expected output" {
  helm template -f test/fixtures/ingresses/values-alb.yaml test/fixtures/ingresses/ > "$TEST_TEMP_DIR/alb_output.yaml"
  assert diff -ub test/expected_output/ingresses-alb.yaml "$TEST_TEMP_DIR/alb_output.yaml"
}

# bats test_tags=tag:alb-external
@test "alb-external: sets scheme" {
  run helm template -f test/fixtures/ingresses/values-alb-external.yaml test/fixtures/ingresses/
  assert_output --partial 'ingressClassName: alb'
  assert_output --partial 'alb.ingress.kubernetes.io/scheme: internet-facing'
  assert_output --partial 'alb.ingress.kubernetes.io/healthcheck-path: /health'
}

# bats test_tags=tag:alb-scheme-error
@test "alb-scheme-error: ensures a scheme is set" {
  run helm template -f test/fixtures/ingresses/badvalues-alb-no-scheme.yaml test/fixtures/containers/
  assert_failure
  assert_output --partial "You must specify a scheme (internal, internet-facing) for ingress [dummy]"
}

# bats test_tags=tag:alb-certarn-error
@test "alb-certarn-error: ensures a certificateArn is set" {
  run helm template -f test/fixtures/ingresses/badvalues-alb-no-certarn.yaml test/fixtures/containers/
  assert_failure
  assert_output --partial "You must specify a certificateArn for ingress [dummy]"
}

# bats test_tags=tag:gitops-bridge
@test "gitops-bridge: if Values has a spec field (usually from Gitops Bridge), ensure annotations are set" {
  run helm template -f test/fixtures/ingresses/values-gitops-bridge.yaml --set spec.ingress.route53_weight=100,spec.clusterName=foo test/fixtures/ingresses/
  assert_output --partial "external-dns.alpha.kubernetes.io/aws-weight: \"100\""
  assert_output --partial "external-dns.alpha.kubernetes.io/set-identifier: foo"
}

# bats test_tags=tag:default-alb
@test "default-alb: if no ingressClass is set, default to alb" {
  run helm template -f test/fixtures/ingresses/values-no-ingressclass.yaml test/fixtures/ingresses/
  assert_output --partial "ingressClassName: alb"
}

# bats test_tags=tag:alb-imperva
@test "alb-imperva: sets imperva-related annotations and scheme" {
  run helm template -f test/fixtures/ingresses/values-alb-imperva.yaml test/fixtures/ingresses/
  assert_output --partial "alb.ingress.kubernetes.io/conditions.cool_foo_service: '[{\"Field\":\"host-header\",\"HostHeaderConfig\":{\"Values\":[\"test-ingresses.example.com\"]}}]'"
  assert_output --partial "external-dns.alpha.kubernetes.io/hostname: origin-test-ingresses.example.com"
  assert_output --partial "host: \"origin-test-ingresses.example.com\""
}

# bats test_tags=tag:alb-imperva-multiple-hostnames
@test "alb-imperva-multiple-hostnames: sets imperva-related annotations and scheme with multiple hostnames" {
  run helm template -f test/fixtures/ingresses/values-alb-imperva-multiple-hostnames.yaml test/fixtures/ingresses/
  assert_output --partial "alb.ingress.kubernetes.io/conditions.web: '[{\"Field\":\"host-header\",\"HostHeaderConfig\":{\"Values\":[\"test-ingresses.example.com\",\"test2-ingresses.example.com\"]}}]'"
}

# bats test_tags=tag:alb-imperva-internal-sceme
@test "alb-imperva-internal-scheme: fails if the scheme is internal" {
  run helm template -f test/fixtures/ingresses/badvalues-alb-imperva-internal-scheme.yaml test/fixtures/ingresses/
  assert_failure
  assert_output --partial "you must set scheme to internet-facing"
}

# bats test_tags=tag:alb-healthcheck-port
@test "alb-healthcheck-port: sets healthcheck-port annotation if specified" {
  run helm template -f test/fixtures/ingresses/values-healthcheck-port.yaml test/fixtures/ingresses/
  assert_output --partial "alb.ingress.kubernetes.io/healthcheck-port: 8181"
}

# bats test_tags=tag:alb-healthcheck-protocol
@test "alb-healthcheck-protocol: sets healthcheck-protocl annotation if specified" {
  run helm template -f test/fixtures/ingresses/values-healthcheck-protocol.yaml test/fixtures/ingresses/
  assert_output --partial "alb.ingress.kubernetes.io/healthcheck-protocol: HTTPS"
}

# bats test_tags=tag:alb-aliases
@test "alb-aliases: sets alb host header annotations with hostnameAliases" {
  run helm template -f test/fixtures/ingresses/values-alb-aliases.yaml test/fixtures/ingresses/
  assert_output --partial "alb.ingress.kubernetes.io/conditions.cool_foo_service: '[{\"Field\":\"host-header\",\"HostHeaderConfig\":{\"Values\":[\"test-ingresses.example.com\",\"alias-subdomain1.example.com\",\"alias-subdomain2.example.com\"]}}]'"
}

# bats test_tags=tag:www-redirect
@test "www-redirect: creates annotations to redirect base domain to www" {
  run helm template -f test/fixtures/ingresses/values-redirect-to-www.yaml test/fixtures/ingresses/
  assert_output --partial "alb.ingress.kubernetes.io/conditions.rule-redirect-www: '[{\"Field\":\"host-header\",\"HostHeaderConfig\":{\"Values\":[\"example.com\"]}}]'"
  assert_output --partial "alb.ingress.kubernetes.io/actions.rule-redirect-www: '{\"Type\":\"redirect\",\"RedirectConfig\":{\"Host\":\"www.example.com\",\"Port\":\"443\",\"Protocol\":\"HTTPS\",\"StatusCode\":\"HTTP_301\"}}'"

  # check that subdomain.example.com is unchanged
  assert_output --partial "
  rules:
    - host: \"subdomain.example.com\"
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web
                port:
                  number: 8080
    - host: \"www.example.com\"
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web
                port:
                  number: 8080
          - path: /
            pathType: Prefix
            backend:
              service:
                name: rule-redirect-www
                port:
                  name: use-annotation"
}
