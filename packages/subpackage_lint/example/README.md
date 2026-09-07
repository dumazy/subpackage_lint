# subpackage_lint example

A tiny package with two subpackages and all six rules enabled. The walkthrough
is in [example.md](example.md), which is also what pub.dev shows on the
package's Example tab.

To try it locally, run `dart analyze` in this folder. The plugin is loaded from
source via `path: ../` in `analysis_options.yaml`. Uncomment the bad imports in
`lib/feature/src/other.dart` to see the rules fire.
