## 2.0.0

- **Breaking:** Migrated from `custom_lint` to the native
  [analyzer plugin system](https://dart.dev/tools/analyzer-plugins). The plugin
  is now enabled under a top-level `plugins:` key instead of via `custom_lint`.
- **Breaking:** Requires Dart 3.10 or later.
- Uses a wide `analyzer` constraint (`>=10.0.0 <15.0.0`) so it can coexist with
  codegen tools (e.g. `build_runner`, `freezed`) that pin an older analyzer.
- Rules now run on the command line with `dart analyze` / `flutter analyze`, not
  only in the IDE.
- Redesigned and expanded the rule set. Rules are enabled and configured
  individually under `diagnostics:`:
  - `avoid_own_subpackage_import`
  - `avoid_relative_subpackage_import`
  - `prefer_relative_import_from_same_subpackage`
  - `avoid_src_import_from_same_subpackage`
  - `avoid_relative_import_from_other_subpackage`
  - `avoid_src_import_from_other_subpackage`
- Quick fixes are available for most rules.
- **Removed:** The `custom_lint`-specific per-rule `directories` and `exclude`
  options. Use the analyzer's standard `exclude:` and the per-rule
  `diagnostics:` toggles instead.

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
