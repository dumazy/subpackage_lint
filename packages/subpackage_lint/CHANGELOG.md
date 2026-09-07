## 2.0.0+1

- Add a proper example to the pub.dev Example tab (`example/example.md`).

## 2.0.0

- **Breaking:** Migrated from `custom_lint` to the native
  [analyzer plugin system](https://dart.dev/tools/analyzer-plugins). The plugin
  is enabled under a top-level `plugins:` key in `analysis_options.yaml` and is
  no longer added to `pubspec.yaml`; the analysis server fetches and compiles it
  in its own isolated package, so it cannot conflict with your project's
  dependencies.
- **Breaking:** Requires Dart 3.10 or later.
- Supports every analyzer from 10.0.0 (Dart 3.10) through 14.x (Dart 3.13) via a
  wide `analyzer` / `analysis_server_plugin` constraint, so the analysis server
  can always pick the version matching the running SDK.
- Rules now run on the command line with `dart analyze`, not only in the IDE.
- Redesigned and expanded the rule set. Rules are enabled and configured
  individually under `diagnostics:`:
  - `avoid_own_subpackage_import`
  - `avoid_relative_subpackage_import`
  - `prefer_relative_import_from_same_subpackage`
  - `avoid_src_import_from_same_subpackage`
  - `avoid_relative_import_from_other_subpackage`
  - `avoid_src_import_from_other_subpackage`
- `avoid_src_import_from_other_subpackage` only reports imports that reach into
  another subpackage's `src` directory. A `package:` import of a file that sits
  next to another subpackage's barrel is no longer reported.
- Quick fixes are available for most rules. Fixes are computed from the
  resolved import target, and a relative import into another subpackage's `src`
  is rewritten straight to that subpackage's barrel file.
- Diagnostics can be suppressed with `// ignore: subpackage_lint/<rule>` and
  `// ignore_for_file: subpackage_lint/<rule>`.
- **Changed:** The `custom_lint`-specific per-rule `directories` and `exclude`
  options are gone. Files can be excluded from all subpackage rules with a
  top-level `subpackage_lint: exclude:` list of globs in
  `analysis_options.yaml` (relative `include:` directives are followed).

## 1.2.0

- Limit directories for the lint rule to run on.
- Improve performance by parsing configuration at startup instead of on every run.
- Upgrade analyzer to 6.6.0 and custom_lint to 0.6.5

## 1.1.0+2

- Improve README.

## 1.1.0+1

- Improve README.

## 1.1.0

- Add support for excluding directories from being linted.

## 1.0.0

- Rename to `subpackage_lint` package. (Previously `kerekewere`)
- Add philosophy section to README.

## 0.0.3

- Fix issue where import changes were applied to first import in file only
- Allow to exclude files from being linted

## 0.0.2

- Lower minimum required version of Dart SDK to 2.12
- Remove logs from the package
- Add fix for converting absolute paths to relative paths

## 0.0.1

- Initial version.
