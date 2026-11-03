# Code structure

How the chart and its tests fit together. `concurrent-work.md` says how changes are shaped so
tickets rarely collide, and `hotspots.md` lists the files that change together. Here a new
module is a named template file, and the fixtures `concurrent-work.md` means are the charts in
`test/fixtures/`.

- **One resource or shared fragment per file.** Each `charts/common/templates/_<name>.yaml.tpl`
  holds the named templates for one resource kind or one shared fragment; small helpers go in
  `_helper_utils.yaml.tpl`. A new resource kind gets its own file rather than a branch in an
  existing one.
- **Every feature is tested by rendering.** A new option gets a `values-*.yaml` in its fixture
  chart under `test/fixtures/<kind>/`, an expected-output file in `test/expected_output/` when
  the whole render matters, and a bats test in `test/test_<kind>.bats` with its own
  `# bats test_tags=tag:<name>` line so `TAG=<name> make test` runs it alone.
- **Expected output is rendered, never hand-edited.** Regenerate it with `helm template` under
  Helm 4 and review the diff; a hand edit can pass a test the chart does not.
- **Additive by default.** A new key is optional, and omitting it renders byte-identical output
  to before. A change to existing output is a release with a `CHANGELOG.md` entry, and a major
  version when consumers must act.
