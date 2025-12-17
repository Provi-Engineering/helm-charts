# AI Agent Instructions for helm-charts
1. Keep templates declarative and reusable via charts/common/templates helpers.
2. Render YAML with two-space indents; avoid tabs and trailing whitespace.
3. Keep Go-template logic small; push shared flows into named helpers.
4. Name helpers "common.<scope>.<resource>" and always call via include.
5. Use default/coalesce for optional values and required() for must-haves.
6. Merge labels/annotations through common.helper.* utilities rather than manual maps.
7. Prefer lowercase-dash keys for values files; match Kubernetes casing in manifests.
8. Reference containers, env, and volumes through existing partials before adding new YAML.
9. Keep imports implicit (sprig, helm); do not add custom Go packages.
10. Order YAML blocks metadata→spec→nested and explain intent via helper names over comments.
11. Error handling: rely on required() / fail templates instead of silent defaults.
12. Tests live in test/*.bats; refresh test/expected_output fixtures when behavior changes.
13. Run all tests with make test (defaults TAG=all).
14. Run focused suite with TAG=<tag> make test (e.g., TAG=podspec-securitycontext).
15. Run a single file via test/bats/bin/bats test/test_podspec.bats.
16. Lint manifests with helm lint charts/common.
17. Build release artifacts via make package (outputs _repo/common-*.tgz).
18. Always bump CHANGELOG.md and charts/common/Chart.yaml when shipping chart changes.
19. When unsure, request clarification and document build/test impact in PR descriptions; Cursor/Copilot rule files: none present.
